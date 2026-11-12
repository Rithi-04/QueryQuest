// Operation Skeld - Query Console
// Dedicated Web Worker that owns the "live" SQLite database used for
// participant queries. Running queries here (instead of the main thread)
// lets the page terminate a runaway query by killing this worker, without
// freezing the UI.
//
// Protocol (all messages are {id, ...}):
//   -> {action:"open", buffer: Uint8Array}   open a database from an exported buffer
//   <- {id, ready:true}                      sql.js finished loading (sent once, id 0)
//   <- {id, opened:true}                     database opened and functions registered
//   -> {action:"exec", sql: "SELECT ..."}
//   <- {id, results:[{columns:[...], values:[[...], ...]}]}
//   <- {id, error: "message"}

importScripts("sql-wasm.js");

var SQL = null;
var db = null;

function pad(n) { return n < 10 ? "0" + n : "" + n; }

function registerMySqlStyleFunctions(database) {
  // CONCAT(a, b, ...): MySQL returns NULL if any argument is NULL.
  database.create_function("CONCAT", function () {
    var args = Array.prototype.slice.call(arguments);
    for (var i = 0; i < args.length; i++) {
      if (args[i] === null || args[i] === undefined) return null;
    }
    return args.map(String).join("");
  });

  // IF(condition, whenTrue, whenFalse)
  database.create_function("IF", function (cond, a, b) {
    return cond ? a : b;
  });

  // NOW() -> "YYYY-MM-DD HH:MM:SS"
  database.create_function("NOW", function () {
    var d = new Date();
    return d.getFullYear() + "-" + pad(d.getMonth() + 1) + "-" + pad(d.getDate()) +
      " " + pad(d.getHours()) + ":" + pad(d.getMinutes()) + ":" + pad(d.getSeconds());
  });

  // CURDATE() -> "YYYY-MM-DD"
  database.create_function("CURDATE", function () {
    var d = new Date();
    return d.getFullYear() + "-" + pad(d.getMonth() + 1) + "-" + pad(d.getDate());
  });

  // CURTIME() -> "HH:MM:SS"
  database.create_function("CURTIME", function () {
    var d = new Date();
    return pad(d.getHours()) + ":" + pad(d.getMinutes()) + ":" + pad(d.getSeconds());
  });

  // LEFT(str, n)
  database.create_function("LEFT", function (s, n) {
    if (s === null || s === undefined) return null;
    return String(s).substring(0, Number(n));
  });

  // RIGHT(str, n)
  database.create_function("RIGHT", function (s, n) {
    if (s === null || s === undefined) return null;
    var str = String(s);
    var count = Number(n);
    if (count <= 0) return "";
    return str.slice(Math.max(0, str.length - count));
  });

  // LOCATE(substr, str) -> 1-based position, 0 if not found.
  // (2-argument form only; MySQL's optional 3rd "start position" argument
  // is not supported here - see the Differences popup in the app.)
  database.create_function("LOCATE", function (substr, str) {
    if (substr === null || substr === undefined || str === null || str === undefined) return null;
    return String(str).indexOf(String(substr)) + 1;
  });

  // CHAR_LENGTH(str)
  database.create_function("CHAR_LENGTH", function (s) {
    if (s === null || s === undefined) return null;
    return String(s).length;
  });

  // DATEDIFF(a, b) -> whole days between two date/datetime strings (a - b)
  database.create_function("DATEDIFF", function (a, b) {
    if (a === null || a === undefined || b === null || b === undefined) return null;
    var da = new Date(String(a).replace(" ", "T"));
    var db2 = new Date(String(b).replace(" ", "T"));
    if (isNaN(da.getTime()) || isNaN(db2.getTime())) return null;
    return Math.round((da.getTime() - db2.getTime()) / 86400000);
  });
}

initSqlJs({ locateFile: function (f) { return f; } }).then(function (sql) {
  SQL = sql;
  postMessage({ id: 0, ready: true });
}).catch(function (err) {
  postMessage({ id: 0, ready: false, error: String(err && err.message ? err.message : err) });
});

onmessage = function (event) {
  var msg = event.data || {};
  var id = msg.id;
  try {
    if (msg.action === "open") {
      if (db) { try { db.close(); } catch (e) { /* ignore */ } }
      db = msg.buffer ? new SQL.Database(new Uint8Array(msg.buffer)) : new SQL.Database();
      registerMySqlStyleFunctions(db);
      postMessage({ id: id, opened: true });
      return;
    }
    if (msg.action === "exec") {
      if (!db) {
        postMessage({ id: id, error: "The database is not open yet. Please wait a moment and try again." });
        return;
      }
      var results = db.exec(msg.sql);
      postMessage({ id: id, results: results });
      return;
    }
    postMessage({ id: id, error: "Unknown worker action: " + msg.action });
  } catch (err) {
    postMessage({ id: id, error: String(err && err.message ? err.message : err) });
  }
};
