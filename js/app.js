/* Operation Skeld: Query Console
 * Fully static, in-browser SQL playground. No backend, no storage, no accounts.
 * See README.md for how this fits together.
 */
(function () {
  "use strict";

  // ---------------------------------------------------------------------
  // Constants & state
  // ---------------------------------------------------------------------
  var MAX_DISPLAY_ROWS = 200;
  var MAX_QUERY_LENGTH = 5000;
  var QUERY_TIMEOUT_MS = 5000;
  var MAX_HISTORY = 20;
  var FORBIDDEN_KEYWORDS = [
    "INSERT", "UPDATE", "DELETE", "DROP", "ALTER", "CREATE",
    "REPLACE", "TRUNCATE", "PRAGMA", "ATTACH", "DETACH", "VACUUM"
  ];

  var DATASETS = {
    demo: { label: "Easy demo", file: "data/mini_demo_database.sql" },
    queryQuest: { label: "Query Quest", file: "data/query_quest_database.sql" }
  };

  var state = {
    currentDataset: "queryQuest",
    datasetText: {},     // cache of fetched .sql file contents
    setupDb: null,       // main-thread SQL.Database, used only for schema introspection
    worker: null,        // Web Worker running the "live" query database
    workerReady: false,
    pendingRequest: null, // { id, timeoutHandle, startTime }
    nextRequestId: 1,
    history: []          // [{ sql, time }]
  };

  // ---------------------------------------------------------------------
  // DOM references
  // ---------------------------------------------------------------------
  var el = {
    loadingOverlay: document.getElementById("loadingOverlay"),
    loadingText: document.getElementById("loadingText"),
    sidebarToggle: document.getElementById("sidebarToggle"),
    sidebar: document.getElementById("sidebar"),
    fullscreenBtn: document.getElementById("fullscreenBtn"),
    fullscreenGate: document.getElementById("fullscreenGate"),
    fullscreenRequiredBtn: document.getElementById("fullscreenRequiredBtn"),
    fullscreenGateError: document.getElementById("fullscreenGateError"),
    datasetSelect: document.getElementById("datasetSelect"),
    schemaPanel: document.getElementById("schemaPanel"),
    tableCount: document.getElementById("tableCount"),
    sqlInput: document.getElementById("sqlInput"),
    runBtn: document.getElementById("runBtn"),
    clearEditorBtn: document.getElementById("clearEditorBtn"),
    errorBox: document.getElementById("errorBox"),
    resultMeta: document.getElementById("resultMeta"),
    resultsTable: document.getElementById("resultsTable"),
    resultsHead: document.getElementById("resultsHead"),
    resultsBody: document.getElementById("resultsBody"),
    resultsWrap: document.getElementById("resultsWrap"),
    historyBtn: document.getElementById("historyBtn"),
    historyPanel: document.getElementById("historyPanel"),
    historyList: document.getElementById("historyList"),
    clearHistoryBtn: document.getElementById("clearHistoryBtn"),
    howToPlayBtn: document.getElementById("howToPlayBtn"),
    differencesBtn: document.getElementById("differencesBtn"),
    modalLayer: document.getElementById("modalLayer"),
    modalTitle: document.getElementById("modalTitle"),
    modalBody: document.getElementById("modalBody"),
    modalClose: document.getElementById("modalClose"),
    panelBackdrop: document.getElementById("panelBackdrop")
  };

  // ---------------------------------------------------------------------
  // Mobile panel backdrop: lets a tap outside the open sidebar / history
  // panel close it, since on narrow screens they overlay the workspace.
  // ---------------------------------------------------------------------
  var isNarrowViewport = function () { return window.matchMedia("(max-width: 820px)").matches; };

  function syncPanelBackdrop() {
    var sidebarOpen = isNarrowViewport() && el.sidebar.classList.contains("open");
    var historyOpen = isNarrowViewport() && !el.historyPanel.hidden;
    el.panelBackdrop.hidden = !(sidebarOpen || historyOpen);
  }

  function closeMobilePanels() {
    el.sidebar.classList.remove("open");
    el.sidebarToggle.setAttribute("aria-expanded", "false");
    el.historyPanel.hidden = true;
    syncPanelBackdrop();
  }

  el.panelBackdrop.addEventListener("click", closeMobilePanels);
  document.addEventListener("keydown", function (e) {
    if (e.key === "Escape" && !el.panelBackdrop.hidden) closeMobilePanels();
  });

  function showFullscreenError(message) {
    el.fullscreenGateError.textContent = message;
    el.fullscreenGateError.hidden = false;
  }

  function enterFullscreen() {
    if (!document.documentElement.requestFullscreen) {
      showFullscreenError("Full screen mode is not supported by this browser.");
      return;
    }
    var request;
    try {
      request = document.documentElement.requestFullscreen();
    } catch (err) {
      showFullscreenError("Could not enter full screen mode: " + err.message);
      return;
    }
    if (!request || typeof request.catch !== "function") {
      showFullscreenError("Full screen mode is not supported by this browser.");
      return;
    }
    request.catch(function (err) {
      showFullscreenError("Could not enter full screen mode: " + err.message);
    });
  }

  function updateFullscreenState() {
    var active = Boolean(document.fullscreenElement);
    el.fullscreenGate.hidden = active;
    Array.prototype.forEach.call(document.body.children, function (child) {
      if (child !== el.fullscreenGate && child.tagName !== "SCRIPT") child.inert = !active;
    });
    el.fullscreenBtn.setAttribute("aria-pressed", String(active));
    el.fullscreenBtn.setAttribute("aria-label", active ? "Exit full screen" : "Enter full screen");
    el.fullscreenBtn.querySelector("span").textContent = active ? "Exit full screen" : "Full screen";
    if (active) {
      el.fullscreenGateError.hidden = true;
      el.sqlInput.focus();
    } else {
      el.fullscreenRequiredBtn.focus();
    }
  }

  el.fullscreenRequiredBtn.addEventListener("click", enterFullscreen);
  el.fullscreenBtn.addEventListener("click", function () {
    if (!document.fullscreenElement) {
      enterFullscreen();
      return;
    }
    if (!document.exitFullscreen) {
      showFullscreenError("Exiting full screen mode is not supported by this browser.");
      return;
    }
    try {
      document.exitFullscreen().catch(function (err) {
        showError("Could not exit full screen mode: " + err.message);
      });
    } catch (err) {
      showError("Could not exit full screen mode: " + err.message);
    }
  });
  document.addEventListener("fullscreenchange", updateFullscreenState);
  updateFullscreenState();

  ["copy", "cut", "paste"].forEach(function (eventName) {
    el.sqlInput.addEventListener(eventName, function (e) {
      e.preventDefault();
    });
  });
  el.sqlInput.addEventListener("keydown", function (e) {
    var key = e.key.toLowerCase();
    var usesClipboardShortcut = (e.ctrlKey || e.metaKey) &&
      (key === "c" || key === "x" || key === "v" || key === "insert");
    var usesShiftInsert = e.shiftKey && key === "insert";
    if (usesClipboardShortcut || usesShiftInsert) e.preventDefault();
  });
  el.sqlInput.addEventListener("drop", function (e) {
    e.preventDefault();
  });

  function selectionTouchesResults() {
    var selection = window.getSelection();
    if (!selection || selection.isCollapsed) return false;
    if (el.resultsWrap.contains(selection.anchorNode) || el.resultsWrap.contains(selection.focusNode)) return true;
    for (var i = 0; i < selection.rangeCount; i++) {
      if (selection.getRangeAt(i).intersectsNode(el.resultsWrap)) return true;
    }
    return false;
  }

  ["copy", "cut", "paste"].forEach(function (eventName) {
    document.addEventListener(eventName, function (e) {
      if (selectionTouchesResults()) e.preventDefault();
    });
  });
  document.addEventListener("keydown", function (e) {
    var key = e.key.toLowerCase();
    var usesClipboardShortcut = (e.ctrlKey || e.metaKey) &&
      (key === "c" || key === "x" || key === "v" || key === "insert");
    var usesShiftInsert = e.shiftKey && key === "insert";
    if ((usesClipboardShortcut || usesShiftInsert) && selectionTouchesResults()) e.preventDefault();
  });

  // ---------------------------------------------------------------------
  // Modal helper
  // ---------------------------------------------------------------------
  function openModal(title, bodyHtml) {
    el.modalTitle.textContent = title;
    el.modalBody.innerHTML = bodyHtml;
    el.modalLayer.hidden = false;
  }
  function closeModal() { el.modalLayer.hidden = true; }
  el.modalClose.addEventListener("click", closeModal);
  el.modalLayer.addEventListener("click", function (e) {
    if (e.target === el.modalLayer) closeModal();
  });
  document.addEventListener("keydown", function (e) {
    if (e.key === "Escape" && !el.modalLayer.hidden) closeModal();
  });

  function showHowToPlay() {
    openModal("How to play", "" +
      "<ul>" +
      "<li>Explore the tables in the Schema panel on the left &mdash; click a table name to drop a starter query into the editor.</li>" +
      "<li>Use <code>SELECT</code> queries to cross-check the logs: who was where, when things happened, who said what.</li>" +
      "<li>When you're confident, write your final evidence query on paper (or keep it in History) and hand it to the facilitator.</li>" +
      "</ul>" +
      "<p class=\"muted-small\">This console only runs queries &mdash; nothing is submitted or scored automatically.</p>");
  }

  function showDifferences() {
    openModal("What's different from real MySQL?", "" +
      "<p class=\"muted-small\">This console runs SQLite under the hood, with a few MySQL-style helpers added. Most <code>SELECT</code> queries behave the same. Known differences:</p>" +
      "<ul>" +
      "<li>No stored procedures, no <code>@variables</code>.</li>" +
      "<li>No regular-expression flags for <code>REGEXP</code>.</li>" +
      "<li><code>FULL OUTER JOIN</code> may not be supported.</li>" +
      "<li><code>GROUP BY</code> is not strict about selecting ungrouped columns.</li>" +
      "<li><code>LOCATE</code> supports only the 2-argument form, <code>LOCATE(substr, str)</code>.</li>" +
      "</ul>");
  }

  el.howToPlayBtn.addEventListener("click", showHowToPlay);
  el.differencesBtn.addEventListener("click", showDifferences);

  // ---------------------------------------------------------------------
  // Sidebar / history panel toggles (responsive)
  // ---------------------------------------------------------------------
  el.sidebarToggle.addEventListener("click", function () {
    var isOpen = el.sidebar.classList.toggle("open");
    el.sidebarToggle.setAttribute("aria-expanded", String(isOpen));
    syncPanelBackdrop();
  });

  el.historyBtn.addEventListener("click", function () {
    el.historyPanel.hidden = !el.historyPanel.hidden;
    syncPanelBackdrop();
  });

  // ---------------------------------------------------------------------
  // SQL text sanitation / validation
  // ---------------------------------------------------------------------

  // Remove -- line comments and /* */ block comments, keeping string
  // literal contents intact. Used to produce the text actually executed.
  function stripComments(sql) {
    var out = "";
    var i = 0;
    var n = sql.length;
    while (i < n) {
      var c = sql[i], c2 = sql[i + 1];
      if (c === "-" && c2 === "-") {
        while (i < n && sql[i] !== "\n") i++;
        continue;
      }
      if (c === "/" && c2 === "*") {
        i += 2;
        while (i < n && !(sql[i] === "*" && sql[i + 1] === "/")) i++;
        i += 2;
        continue;
      }
      if (c === "'" || c === '"' || c === "`") {
        var quote = c;
        out += c; i++;
        while (i < n && sql[i] !== quote) { out += sql[i]; i++; }
        if (i < n) { out += sql[i]; i++; }
        continue;
      }
      out += c; i++;
    }
    return out;
  }

  // Blank out string-literal contents (same length, spaces) so keyword /
  // structure checks never match text that is just data inside a string.
  // Assumes comments have already been stripped.
  function blankStringLiterals(sql) {
    var out = "";
    var i = 0;
    var n = sql.length;
    while (i < n) {
      var c = sql[i];
      if (c === "'" || c === '"' || c === "`") {
        var quote = c;
        out += " "; i++;
        while (i < n && sql[i] !== quote) { out += " "; i++; }
        if (i < n) { out += " "; i++; }
        continue;
      }
      out += c; i++;
    }
    return out;
  }

  // Returns { ok: true, sql: <cleaned sql to execute> } or { ok: false, message }
  function validateQuery(raw) {
    if (raw.length > MAX_QUERY_LENGTH) {
      return { ok: false, message: "Query is too long (max " + MAX_QUERY_LENGTH + " characters)." };
    }
    var noComments = stripComments(raw).trim();
    if (!noComments) {
      return { ok: false, message: "Please enter a query." };
    }
    var analysis = blankStringLiterals(noComments);

    if (!/^(SELECT|WITH)\b/i.test(analysis.trim())) {
      return { ok: false, message: "Only SELECT queries are allowed in this console." };
    }

    // Allow exactly one optional trailing semicolon; anything left after
    // stripping it means more than one statement.
    var body = analysis.replace(/;\s*$/, "");
    if (body.indexOf(";") !== -1) {
      return { ok: false, message: "Only a single statement is allowed. Remove the extra statement(s)." };
    }

    var upper = analysis.toUpperCase();
    for (var k = 0; k < FORBIDDEN_KEYWORDS.length; k++) {
      var kw = FORBIDDEN_KEYWORDS[k];
      var re = new RegExp("\\b" + kw + "\\b");
      if (re.test(upper)) {
        return { ok: false, message: "The keyword '" + kw + "' is not allowed in this read-only console." };
      }
    }

    // Execute the comment-free text, trimmed of a single trailing semicolon
    // (sql.js is fine with a trailing semicolon too, but this keeps it tidy).
    var toRun = noComments.replace(/;\s*$/, "");
    return { ok: true, sql: toRun };
  }

  // ---------------------------------------------------------------------
  // Engine bootstrap
  // ---------------------------------------------------------------------
  var SQLEngine = null; // the sql.js module (main thread copy, for schema introspection)

  function setLoading(text) {
    el.loadingOverlay.hidden = false;
    el.loadingText.textContent = text;
  }
  function hideLoading() { el.loadingOverlay.hidden = true; }

  function fetchText(path) {
    return fetch(path).then(function (res) {
      if (!res.ok) throw new Error("Could not load " + path + " (HTTP " + res.status + ")");
      return res.text();
    });
  }

  function boot() {
    setLoading("Loading SQL engine\u2026");
    var engineReady = initSqlJs({ locateFile: function (f) { return "vendor/" + f; } });
    var dataReady = Promise.all(Object.keys(DATASETS).map(function (key) {
      return fetchText(DATASETS[key].file).then(function (text) {
        state.datasetText[key] = text;
      });
    }));

    Promise.all([engineReady, dataReady]).then(function (results) {
      SQLEngine = results[0];
      setLoading("Building the ship's database\u2026");
      return switchDataset(state.currentDataset, /*isInitial*/ true);
    }).then(function () {
      hideLoading();
      el.runBtn.disabled = false;
      showHowToPlay();
    }).catch(function (err) {
      setLoading("Failed to load: " + (err && err.message ? err.message : err));
    });
  }

  // ---------------------------------------------------------------------
  // Dataset handling (setup DB on main thread + worker for live queries)
  // ---------------------------------------------------------------------
  function buildSetupDb(sqlText) {
    if (state.setupDb) { try { state.setupDb.close(); } catch (e) { /* ignore */ } }
    var db = new SQLEngine.Database();
    db.exec(sqlText);
    state.setupDb = db;
    return db;
  }

  function spawnWorker() {
    return new Promise(function (resolve, reject) {
      var worker = new Worker("vendor/query-worker.js");
      var readyHandler = function (event) {
        var msg = event.data || {};
        if (msg.id === 0) {
          worker.removeEventListener("message", readyHandler);
          if (msg.ready) resolve(worker);
          else reject(new Error(msg.error || "Worker failed to start."));
        }
      };
      worker.addEventListener("message", readyHandler);
      worker.addEventListener("error", function (e) {
        reject(new Error("Worker error: " + e.message));
      });
    });
  }

  function openWorkerDb(worker, buffer) {
    return new Promise(function (resolve, reject) {
      var id = state.nextRequestId++;
      var handler = function (event) {
        var msg = event.data || {};
        if (msg.id !== id) return;
        worker.removeEventListener("message", handler);
        if (msg.opened) resolve();
        else reject(new Error(msg.error || "Could not open database in worker."));
      };
      worker.addEventListener("message", handler);
      worker.postMessage({ id: id, action: "open", buffer: buffer });
    });
  }

  function switchDataset(key, isInitial) {
    state.currentDataset = key;
    var sqlText = state.datasetText[key];

    var db = buildSetupDb(sqlText);
    renderSchema(db);

    var buffer = db.export();

    var workerPromise = state.worker ? Promise.resolve(state.worker) : spawnWorker();
    return workerPromise.then(function (worker) {
      state.worker = worker;
      return openWorkerDb(worker, buffer);
    }).then(function () {
      state.workerReady = true;
      if (!isInitial) {
        clearResults();
        showMeta("Dataset switched to \u201c" + DATASETS[key].label + "\u201d. Results cleared.");
      }
    });
  }

  el.datasetSelect.addEventListener("change", function () {
    var key = el.datasetSelect.value;
    el.runBtn.disabled = true;
    setLoading("Loading \u201c" + DATASETS[key].label + "\u201d dataset\u2026");
    switchDataset(key, false).then(function () {
      hideLoading();
      el.runBtn.disabled = false;
    }).catch(function (err) {
      hideLoading();
      el.runBtn.disabled = false;
      showError("Could not switch datasets: " + err.message);
    });
  });

  // ---------------------------------------------------------------------
  // Schema panel
  // ---------------------------------------------------------------------
  function renderSchema(db) {
    el.schemaPanel.innerHTML = "";
    var tablesRes = db.exec(
      "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' ORDER BY name;"
    );
    var tableNames = (tablesRes[0] ? tablesRes[0].values : []).map(function (r) { return r[0]; });
    el.tableCount.textContent = tableNames.length + " table" + (tableNames.length === 1 ? "" : "s");

    tableNames.forEach(function (tableName) {
      var colsRes = db.exec("PRAGMA table_info(" + quoteIdent(tableName) + ");");
      var cols = colsRes[0] ? colsRes[0].values : []; // cid, name, type, notnull, dflt_value, pk
      var countRes = db.exec("SELECT COUNT(*) FROM " + quoteIdent(tableName) + ";");
      var rowCount = countRes[0] ? countRes[0].values[0][0] : 0;

      var wrap = document.createElement("div");
      wrap.className = "schema-table";

      var btn = document.createElement("button");
      btn.type = "button";
      btn.className = "schema-table-btn";
      btn.innerHTML = "<span>" + escapeHtml(tableName) + "</span>" +
        "<span class=\"muted-small\">" + rowCount + " rows</span>";
      btn.addEventListener("click", function () {
        insertAtCursor(el.sqlInput, "SELECT * FROM " + tableName + " LIMIT 10;");
        el.sqlInput.focus();
        if (isNarrowViewport()) {
          el.sidebar.classList.remove("open");
          syncPanelBackdrop();
        }
      });

      var colsBox = document.createElement("div");
      colsBox.className = "schema-cols";
      cols.forEach(function (c) {
        var row = document.createElement("div");
        row.className = "schema-col-row";
        var label = escapeHtml(c[1]) + (c[5] ? " \uD83D\uDD11" : "");
        row.innerHTML = "<span>" + label + "</span><span class=\"col-type\">" + escapeHtml(c[2] || "") + "</span>";
        colsBox.appendChild(row);
      });

      wrap.appendChild(btn);
      wrap.appendChild(colsBox);
      el.schemaPanel.appendChild(wrap);
    });
  }

  function quoteIdent(name) { return "`" + String(name).replace(/`/g, "``") + "`"; }

  function insertAtCursor(textarea, text) {
    var start = textarea.selectionStart, end = textarea.selectionEnd;
    var value = textarea.value;
    var before = value.slice(0, start);
    var needsNewline = before.length > 0 && !/\n\s*$/.test(before);
    var insertion = (needsNewline ? "\n" : "") + text;
    textarea.value = before + insertion + value.slice(end);
    var pos = (before + insertion).length;
    textarea.selectionStart = textarea.selectionEnd = pos;
  }

  function escapeHtml(s) {
    return String(s).replace(/[&<>"']/g, function (c) {
      return ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" })[c];
    });
  }

  // ---------------------------------------------------------------------
  // Running queries
  // ---------------------------------------------------------------------
  function showError(message) {
    el.errorBox.hidden = false;
    el.errorBox.textContent = message;
  }
  function clearError() {
    el.errorBox.hidden = true;
    el.errorBox.textContent = "";
  }
  function showMeta(text) { el.resultMeta.textContent = text; }

  function clearResults() {
    el.resultsTable.hidden = true;
    el.resultsHead.innerHTML = "";
    el.resultsBody.innerHTML = "";
    showMeta("Run a query to see results here.");
  }

  function getQueryToRun() {
    var full = el.sqlInput.value;
    var selStart = el.sqlInput.selectionStart, selEnd = el.sqlInput.selectionEnd;
    if (selEnd > selStart) return full.slice(selStart, selEnd);
    return full;
  }

  function renderResults(resultSet) {
    el.resultsHead.innerHTML = "";
    el.resultsBody.innerHTML = "";

    if (!resultSet) {
      el.resultsTable.hidden = true;
      showMeta("Query ran, but returned no result set (not a SELECT?).");
      return;
    }

    var columns = resultSet.columns;
    var values = resultSet.values;

    var headRow = document.createElement("tr");
    columns.forEach(function (c) {
      var th = document.createElement("th");
      th.textContent = c;
      headRow.appendChild(th);
    });
    el.resultsHead.appendChild(headRow);

    var shown = values.slice(0, MAX_DISPLAY_ROWS);
    shown.forEach(function (row) {
      var tr = document.createElement("tr");
      row.forEach(function (val) {
        var td = document.createElement("td");
        if (val === null || val === undefined) {
          td.textContent = "NULL";
          td.className = "null-cell";
        } else {
          td.textContent = String(val);
        }
        tr.appendChild(td);
      });
      el.resultsBody.appendChild(tr);
    });

    el.resultsTable.hidden = false;
  }

  function runQuery() {
    clearError();
    var raw = getQueryToRun();
    var validation = validateQuery(raw);
    if (!validation.ok) {
      showError(validation.message);
      return;
    }
    if (!state.workerReady || !state.worker) {
      showError("The database engine is still starting up. Please wait a moment.");
      return;
    }

    el.runBtn.disabled = true;
    showMeta("Running\u2026");

    var id = state.nextRequestId++;
    var startTime = performance.now();

    var timeoutHandle = setTimeout(function () {
      handleTimeout(id);
    }, QUERY_TIMEOUT_MS);

    state.pendingRequest = { id: id, timeoutHandle: timeoutHandle, startTime: startTime };

    var handler = function (event) {
      var msg = event.data || {};
      if (msg.id !== id) return;
      if (!state.pendingRequest || state.pendingRequest.id !== id) return; // superseded by a timeout restart
      state.worker.removeEventListener("message", handler);
      clearTimeout(timeoutHandle);
      state.pendingRequest = null;
      el.runBtn.disabled = false;

      var elapsedMs = Math.round(performance.now() - startTime);

      if (msg.error) {
        showError(msg.error);
        clearResults();
        return;
      }

      var resultSet = (msg.results && msg.results.length) ? msg.results[msg.results.length - 1] : null;
      renderResults(resultSet);

      if (resultSet) {
        var total = resultSet.values.length;
        var truncatedNote = total > MAX_DISPLAY_ROWS
          ? " (showing first " + MAX_DISPLAY_ROWS + " rows)"
          : "";
        showMeta(total + " row" + (total === 1 ? "" : "s") + " \u00B7 " + elapsedMs + " ms" + truncatedNote);
      }

      addToHistory(validation.sql);
    };
    state.worker.addEventListener("message", handler);
    state.worker.postMessage({ id: id, action: "exec", sql: validation.sql });
  }

  function handleTimeout(id) {
    if (!state.pendingRequest || state.pendingRequest.id !== id) return;
    state.pendingRequest = null;
    el.runBtn.disabled = false;
    showError("Query timed out after " + (QUERY_TIMEOUT_MS / 1000) + " seconds. Try adding a LIMIT clause or simplifying the query.");
    clearResults();

    // The worker may be stuck; kill it and respawn against the same dataset.
    try { state.worker.terminate(); } catch (e) { /* ignore */ }
    state.workerReady = false;
    var buffer = state.setupDb.export();
    spawnWorker().then(function (worker) {
      state.worker = worker;
      return openWorkerDb(worker, buffer);
    }).then(function () {
      state.workerReady = true;
    }).catch(function (err) {
      showError("Could not restart the query engine: " + err.message + " Please reload the page.");
    });
  }

  el.runBtn.addEventListener("click", runQuery);
  el.sqlInput.addEventListener("keydown", function (e) {
    var isEnter = e.key === "Enter";
    var isMod = e.ctrlKey || e.metaKey;
    if (isEnter && isMod) {
      e.preventDefault();
      if (!el.runBtn.disabled) runQuery();
    }
  });
  el.clearEditorBtn.addEventListener("click", function () {
    el.sqlInput.value = "";
    el.sqlInput.focus();
    clearError();
  });

  // ---------------------------------------------------------------------
  // History
  // ---------------------------------------------------------------------
  function addToHistory(sql) {
    state.history.unshift({ sql: sql, time: new Date() });
    if (state.history.length > MAX_HISTORY) state.history.length = MAX_HISTORY;
    renderHistory();
  }

  function renderHistory() {
    el.historyList.innerHTML = "";
    if (state.history.length === 0) {
      var li = document.createElement("li");
      li.className = "history-empty";
      li.textContent = "No queries run yet.";
      el.historyList.appendChild(li);
      return;
    }
    state.history.forEach(function (item) {
      var li = document.createElement("li");
      li.className = "history-item";
      var hh = item.time.getHours(), mm = item.time.getMinutes(), ss = item.time.getSeconds();
      var pad = function (n) { return n < 10 ? "0" + n : "" + n; };
      li.innerHTML = "<span class=\"history-time\">" + pad(hh) + ":" + pad(mm) + ":" + pad(ss) + "</span>" +
        escapeHtml(item.sql);
      li.addEventListener("click", function () {
        el.sqlInput.value = item.sql;
        el.sqlInput.focus();
      });
      el.historyList.appendChild(li);
    });
  }

  el.clearHistoryBtn.addEventListener("click", function () {
    state.history = [];
    renderHistory();
  });

  renderHistory();

  // ---------------------------------------------------------------------
  // Go
  // ---------------------------------------------------------------------
  boot();
})();
