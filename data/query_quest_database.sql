-- QUERY QUEST : Spaceship "SKELD-7" Database (single-incident, 5-stage edition)
-- Mission clock: every *_minute column = minutes since launch (0-60).
-- NULL exit_minute on room_logs = still there / never logged leaving (dead, or left via vent).
-- Works in MySQL 8 / SQLite / PostgreSQL. Primary keys only - no Foreign Keys.
-- FACILITATOR FILE - do not distribute to teams. Pair with the Query Quest Evidence & Facilitator Guide.

DROP TABLE IF EXISTS crewmates;
DROP TABLE IF EXISTS rooms;
DROP TABLE IF EXISTS vent_network;
DROP TABLE IF EXISTS room_logs;
DROP TABLE IF EXISTS movement_logs;
DROP TABLE IF EXISTS task_assignments;
DROP TABLE IF EXISTS task_logs;
DROP TABLE IF EXISTS system_status_logs;
DROP TABLE IF EXISTS emergency_events;
DROP TABLE IF EXISTS sabotage_records;
DROP TABLE IF EXISTS camera_logs;
DROP TABLE IF EXISTS communication_logs;
DROP TABLE IF EXISTS repair_logs;
DROP TABLE IF EXISTS activity_logs;

CREATE TABLE crewmates (
  player_id INT PRIMARY KEY,
  color VARCHAR(20),
  department VARCHAR(30)
);

CREATE TABLE rooms (
  room_id INT PRIMARY KEY,
  room_name VARCHAR(30)
);

CREATE TABLE vent_network (
  vent_id INT PRIMARY KEY,
  room_a_id INT,
  room_b_id INT
);

CREATE TABLE room_logs (
  log_id INT PRIMARY KEY,
  player_id INT,
  room_id INT,
  entry_minute INT,
  exit_minute INT
);

CREATE TABLE movement_logs (
  move_id INT PRIMARY KEY,
  player_id INT,
  from_room_id INT,
  to_room_id INT,
  move_minute INT
);

CREATE TABLE task_assignments (
  assignment_id INT PRIMARY KEY,
  player_id INT,
  task_name VARCHAR(40),
  room_id INT
);

CREATE TABLE task_logs (
  task_log_id INT PRIMARY KEY,
  player_id INT,
  task_name VARCHAR(40),
  room_id INT,
  completed_minute INT
);

CREATE TABLE system_status_logs (
  status_id INT PRIMARY KEY,
  system_name VARCHAR(20),
  log_minute INT,
  status VARCHAR(15),
  note VARCHAR(60)
);

CREATE TABLE emergency_events (
  event_id INT PRIMARY KEY,
  event_minute INT,
  event_type VARCHAR(20),
  called_by INT,
  location_room_id INT,
  body_of_player_id INT,
  outcome VARCHAR(80)
);

CREATE TABLE sabotage_records (
  sabotage_id INT PRIMARY KEY,
  sabotage_type VARCHAR(25),
  room_id INT,
  start_minute INT,
  resolved_minute INT,
  status VARCHAR(10)
);

CREATE TABLE camera_logs (
  cam_log_id INT PRIMARY KEY,
  room_id INT,
  log_minute INT,
  observed_player_id INT,
  observation VARCHAR(80)
);

CREATE TABLE communication_logs (
  comm_id INT PRIMARY KEY,
  sent_minute INT,
  channel VARCHAR(10),
  sender_id INT,
  receiver_id INT,
  message VARCHAR(140)
);

CREATE TABLE repair_logs (
  repair_id INT PRIMARY KEY,
  sabotage_id INT,
  player_id INT,
  repair_minute INT,
  room_id INT,
  action VARCHAR(40),
  result VARCHAR(15)
);

CREATE TABLE activity_logs (
  activity_id INT PRIMARY KEY,
  log_minute INT,
  player_id INT,
  room_id INT,
  event_type VARCHAR(25),
  details VARCHAR(80)
);

-- ========== DATA ==========
INSERT INTO crewmates (player_id, color, department) VALUES
  (1, 'Red', 'Engineering'),
  (2, 'Blue', 'Navigation Crew'),
  (3, 'Green', 'Science'),
  (4, 'Pink', 'Life Support'),
  (5, 'Orange', 'Weapons Crew'),
  (6, 'Yellow', 'Electrical Crew'),
  (7, 'Black', 'Security'),
  (8, 'White', 'Communications'),
  (9, 'Purple', 'Reactor Crew'),
  (10, 'Brown', 'Logistics');

INSERT INTO rooms (room_id, room_name) VALUES
  (1, 'Cafeteria'),
  (2, 'Weapons'),
  (3, 'Navigation'),
  (4, 'O2'),
  (5, 'Shields'),
  (6, 'Communications'),
  (7, 'Storage'),
  (8, 'Electrical'),
  (9, 'Lower Engine'),
  (10, 'Reactor'),
  (11, 'Upper Engine'),
  (12, 'Security'),
  (13, 'MedBay'),
  (14, 'Admin');

INSERT INTO vent_network (vent_id, room_a_id, room_b_id) VALUES
  (1, 10, 11),
  (2, 11, 9),
  (3, 8, 13),
  (4, 13, 12),
  (5, 3, 5),
  (6, 1, 14),
  (7, 14, 7);

INSERT INTO room_logs (log_id, player_id, room_id, entry_minute, exit_minute) VALUES
  (1, 1, 1, 0, 4),
  (2, 2, 1, 0, 4),
  (3, 3, 1, 0, 4),
  (4, 4, 1, 0, 4),
  (5, 5, 1, 0, 4),
  (6, 6, 1, 0, 4),
  (7, 7, 1, 0, 4),
  (8, 8, 1, 0, 4),
  (9, 9, 1, 0, 4),
  (10, 10, 1, 0, 4),
  (11, 2, 8, 5, 9),
  (12, 1, 2, 6, 13),
  (13, 3, 3, 6, 12),
  (14, 4, 4, 6, 10),
  (15, 5, 5, 6, 10),
  (16, 6, 7, 6, 11),
  (17, 7, 12, 6, 10),
  (18, 8, 3, 6, 10),
  (19, 9, 10, 6, 14),
  (20, 10, 7, 6, 12),
  (21, 2, 3, 11, 16),
  (22, 4, 14, 12, 16),
  (23, 5, 3, 12, 17),
  (24, 7, 2, 12, 17),
  (25, 8, 4, 12, 16),
  (26, 6, 14, 13, 17),
  (27, 3, 5, 14, 19),
  (28, 10, 14, 14, 18),
  (29, 1, 14, 15, 21),
  (30, 9, 9, 16, 19),
  (31, 2, 5, 18, 23),
  (32, 4, 7, 18, 22),
  (33, 8, 5, 18, 22),
  (34, 5, 6, 19, 24),
  (35, 7, 3, 19, 24),
  (36, 6, 8, 20, 25),
  (37, 10, 2, 20, 25),
  (38, 9, 1, 21, 23),
  (39, 3, 8, 22, NULL),
  (40, 1, 8, 23, 24),
  (41, 4, 2, 24, 29),
  (42, 8, 1, 24, 27),
  (43, 9, 8, 24, NULL),
  (44, 1, 2, 25, 29),
  (45, 2, 2, 25, 30),
  (46, 5, 13, 26, 31),
  (47, 7, 8, 26, 31),
  (48, 6, 5, 27, 31),
  (49, 10, 8, 27, 29),
  (50, 9, 13, 28, 31),
  (51, 8, 6, 29, 33),
  (52, 10, 12, 30, 34),
  (53, 4, 3, 31, 36),
  (54, 2, 4, 32, 37),
  (55, 6, 3, 32, 37),
  (56, 5, 2, 33, 37),
  (57, 7, 1, 33, 36),
  (58, 9, 12, 33, 37),
  (59, 8, 8, 34, 36),
  (60, 8, 1, 37, 47),
  (61, 7, 13, 38, 41),
  (62, 1, 10, 39, 42),
  (63, 2, 13, 39, 43),
  (64, 5, 10, 39, 42),
  (65, 6, 2, 39, 43),
  (66, 1, 1, 44, 47),
  (67, 2, 1, 44, 47),
  (68, 4, 1, 44, 47),
  (69, 5, 1, 44, 47),
  (70, 6, 1, 44, 47),
  (71, 7, 1, 44, 47),
  (72, 9, 1, 44, 47),
  (73, 10, 1, 44, 47);

INSERT INTO movement_logs (move_id, player_id, from_room_id, to_room_id, move_minute) VALUES
  (1, 1, 1, 2, 4),
  (2, 2, 1, 8, 4),
  (3, 3, 1, 3, 4),
  (4, 4, 1, 4, 4),
  (5, 5, 1, 5, 4),
  (6, 6, 1, 7, 4),
  (7, 7, 1, 12, 4),
  (8, 8, 1, 3, 4),
  (9, 9, 1, 10, 4),
  (10, 10, 1, 7, 4),
  (11, 2, 8, 3, 9),
  (12, 4, 4, 14, 10),
  (13, 5, 5, 3, 10),
  (14, 7, 12, 2, 10),
  (15, 8, 3, 4, 10),
  (16, 6, 7, 14, 11),
  (17, 3, 3, 5, 12),
  (18, 10, 7, 14, 12),
  (19, 1, 2, 14, 13),
  (20, 9, 10, 9, 14),
  (21, 2, 3, 5, 16),
  (22, 4, 14, 7, 16),
  (23, 8, 4, 5, 16),
  (24, 5, 3, 6, 17),
  (25, 6, 14, 8, 17),
  (26, 7, 2, 3, 17),
  (27, 10, 14, 2, 18),
  (28, 3, 5, 8, 19),
  (29, 9, 9, 1, 19),
  (30, 1, 14, 8, 21),
  (31, 4, 7, 2, 22),
  (32, 8, 5, 1, 22),
  (33, 2, 5, 2, 23),
  (34, 9, 1, 8, 23),
  (35, 1, 8, 2, 24),
  (36, 5, 6, 13, 24),
  (37, 7, 3, 8, 24),
  (38, 6, 8, 5, 25),
  (39, 10, 2, 8, 25),
  (40, 8, 1, 6, 27),
  (41, 1, 2, 10, 29),
  (42, 4, 2, 3, 29),
  (43, 10, 8, 12, 29),
  (44, 2, 2, 4, 30),
  (45, 5, 13, 2, 31),
  (46, 6, 5, 3, 31),
  (47, 7, 8, 1, 31),
  (48, 9, 13, 12, 31),
  (49, 8, 6, 8, 33),
  (50, 10, 12, 1, 34),
  (51, 4, 3, 1, 36),
  (52, 7, 1, 13, 36),
  (53, 8, 8, 1, 36),
  (54, 2, 4, 13, 37),
  (55, 5, 2, 10, 37),
  (56, 6, 3, 2, 37),
  (57, 9, 12, 1, 37),
  (58, 7, 13, 1, 41),
  (59, 1, 10, 1, 42),
  (60, 5, 10, 1, 42),
  (61, 2, 13, 1, 43),
  (62, 6, 2, 1, 43);

INSERT INTO task_assignments (assignment_id, player_id, task_name, room_id) VALUES
  (1, 1, 'Clear Asteroids', 2),
  (2, 2, 'Fix Wiring', 8),
  (3, 2, 'Stabilize Steering', 3),
  (4, 3, 'Stabilize Steering', 3),
  (5, 3, 'Prime Shields', 5),
  (6, 4, 'Clean O2 Filter', 4),
  (7, 4, 'Swipe Card', 14),
  (8, 5, 'Prime Shields', 5),
  (9, 5, 'Chart Course', 3),
  (10, 5, 'Download Data', 6),
  (11, 6, 'Fix Wiring', 8),
  (12, 7, 'Calibrate Distributor', 8),
  (13, 7, 'Fix Wiring', 12),
  (14, 8, 'Submit Scan', 13),
  (15, 9, 'Start Reactor', 10),
  (16, 9, 'Unlock Manifolds', 10),
  (17, 10, 'Fuel Engines', 7),
  (18, 10, 'Fix Wiring', 12),
  (19, 4, 'Chart Course', 3),
  (20, 2, 'Submit Scan', 13),
  (21, 5, 'Clear Asteroids', 2),
  (22, 7, 'Chart Course', 3),
  (23, 7, 'Clear Asteroids', 2),
  (24, 8, 'Download Data', 6),
  (25, 6, 'Clear Asteroids', 2),
  (26, 10, 'Clear Asteroids', 2),
  (27, 3, 'Empty Garbage', 4),
  (28, 8, 'Clean O2 Filter', 4),
  (29, 4, 'Clear Asteroids', 2),
  (30, 9, 'Divert Power', 8);

INSERT INTO task_logs (task_log_id, player_id, task_name, room_id, completed_minute) VALUES
  (1, 1, 'Clear Asteroids', 2, 9),
  (2, 2, 'Fix Wiring', 8, 8),
  (3, 2, 'Stabilize Steering', 3, 14),
  (4, 3, 'Stabilize Steering', 3, 10),
  (5, 3, 'Prime Shields', 5, 17),
  (6, 4, 'Clean O2 Filter', 4, 9),
  (7, 4, 'Swipe Card', 14, 14),
  (8, 5, 'Prime Shields', 5, 9),
  (9, 5, 'Chart Course', 3, 15),
  (10, 5, 'Download Data', 6, 22),
  (11, 6, 'Fix Wiring', 8, 24),
  (12, 7, 'Calibrate Distributor', 8, 30),
  (13, 10, 'Fuel Engines', 7, 10),
  (14, 10, 'Fix Wiring', 12, 33),
  (15, 4, 'Chart Course', 3, 34),
  (16, 2, 'Submit Scan', 13, 41),
  (17, 5, 'Clear Asteroids', 2, 35),
  (18, 7, 'Chart Course', 3, 22),
  (19, 7, 'Clear Asteroids', 2, 15),
  (20, 8, 'Download Data', 6, 31),
  (21, 6, 'Clear Asteroids', 2, 41),
  (22, 10, 'Clear Asteroids', 2, 23),
  (23, 8, 'Clean O2 Filter', 4, 14),
  (24, 4, 'Clear Asteroids', 2, 27);

INSERT INTO system_status_logs (status_id, system_name, log_minute, status, note) VALUES
  (1, 'O2', 0, 'OK', 'Nominal'),
  (2, 'LIGHTS', 0, 'OK', 'Nominal'),
  (3, 'REACTOR', 0, 'OK', 'Nominal'),
  (4, 'O2', 8, 'SABOTAGED', 'Filter pressure dropping'),
  (5, 'O2', 11, 'OK', 'Filter pressure restored'),
  (6, 'LIGHTS', 25, 'SABOTAGED', 'Breaker tripped in Electrical'),
  (7, 'CAMERAS', 25, 'OFFLINE', 'Electrical & MedBay feeds lost - lights out'),
  (8, 'LIGHTS', 32, 'OK', 'Breaker restored'),
  (9, 'CAMERAS', 32, 'ONLINE', 'Feeds restored'),
  (10, 'REACTOR', 39, 'CRITICAL', 'Meltdown countdown started'),
  (11, 'REACTOR', 43, 'OK', 'Meltdown stopped'),
  (12, 'COMMS', 18, 'SABOTAGED', 'Signal array offline'),
  (13, 'COMMS', 21, 'OK', 'Signal restored');

INSERT INTO emergency_events (event_id, event_minute, event_type, called_by, location_room_id, body_of_player_id, outcome) VALUES
  (1, 35, 'BODY_REPORT', 8, 8, 3, 'Emergency meeting called - evidence review in progress');

INSERT INTO sabotage_records (sabotage_id, sabotage_type, room_id, start_minute, resolved_minute, status) VALUES
  (1, 'O2_DEPLETION', 4, 8, 11, 'RESOLVED'),
  (2, 'COMMS_OUTAGE', 6, 18, 21, 'RESOLVED'),
  (3, 'LIGHTS', 8, 25, 32, 'RESOLVED'),
  (4, 'REACTOR_MELTDOWN', 10, 39, 43, 'RESOLVED');

INSERT INTO camera_logs (cam_log_id, room_id, log_minute, observed_player_id, observation) VALUES
  (1, 2, 9, 1, 'Red at asteroids console'),
  (2, 8, 8, 2, 'Blue at wiring panel'),
  (3, 4, 9, 4, 'Pink at O2 filter'),
  (4, 5, 9, 5, 'Orange at shields console'),
  (5, 8, 23, 1, 'Red glances into Electrical'),
  (6, 8, 24, 6, 'Yellow at wiring panel'),
  (7, 12, 7, 7, 'Black at security monitors'),
  (8, 8, NULL, NULL, 'Feed lost - lights out'),
  (9, 13, NULL, NULL, 'Feed lost - lights out'),
  (10, 8, 33, 7, 'Black leaving Electrical'),
  (11, 1, 24, 8, 'White crossing Cafeteria'),
  (12, 8, 35, 8, 'White discovers a body'),
  (13, 7, 7, 10, 'Brown collecting fuel canister'),
  (14, 10, 40, 5, 'Orange at reactor console'),
  (15, 10, 41, 1, 'Red at reactor console'),
  (16, 14, 16, 1, 'Red at admin console'),
  (17, 14, 15, 4, 'Pink swiping card'),
  (18, 3, 21, 7, 'Black at navigation console'),
  (19, 2, 15, 7, 'Black at asteroids console'),
  (20, 6, 20, 5, 'Orange at comms console'),
  (21, 6, 19, 5, 'Orange restarting comms array'),
  (22, 13, 29, 5, 'Orange submitting a scan'),
  (23, 7, 20, 10, 'Brown loading fuel canister'),
  (24, 2, 26, 4, 'Pink at asteroids console'),
  (25, 3, 34, 4, 'Pink charting a course'),
  (26, 4, 34, 2, 'Blue at O2 filter'),
  (27, 13, 40, 2, 'Blue submitting a scan'),
  (28, 1, 2, 3, 'Green leaving Cafeteria'),
  (29, 5, 7, 5, 'Orange priming shields'),
  (30, 5, 16, 3, 'Green priming shields'),
  (31, 3, 8, 8, 'White charting a course'),
  (32, 14, 17, 10, 'Brown swiping card'),
  (33, 12, 32, 10, 'Brown at security console'),
  (34, 4, 7, 4, 'Pink cleaning the O2 filter'),
  (35, 2, 27, 1, 'Red at asteroids console again');

INSERT INTO communication_logs (comm_id, sent_minute, channel, sender_id, receiver_id, message) VALUES
  (1, 1, 'RADIO', 1, 2, 'Meet at Cafeteria after tasks?'),
  (2, 2, 'RADIO', 2, 1, 'Sure, doing wiring first'),
  (3, 35, 'RADIO', 8, NULL, 'Body in Electrical! It is Green. Reporting now.'),
  (4, 36, 'MEETING', 8, NULL, 'Found Green in Electrical. No idea how long they had been there.'),
  (5, 37, 'MEETING', 1, NULL, 'I just glanced into Electrical for a second around 23, then went straight back to Weapons.'),
  (6, 38, 'MEETING', 6, NULL, 'I was in MedBay the whole time. Never went near Electrical.'),
  (7, 39, 'MEETING', 7, NULL, 'I was calibrating the distributor in Electrical. Saw Brown pass through on their way to Security.'),
  (8, 40, 'MEETING', 9, NULL, 'I was doing Reactor tasks since minute 20. Never went to Electrical.'),
  (9, 41, 'MEETING', 10, NULL, 'I just cut through Electrical on my way to Security, did not stop.'),
  (10, 42, 'MEETING', 4, NULL, 'I was in Storage then Admin all game, nowhere near Electrical.'),
  (11, 43, 'MEETING', 5, NULL, 'I was doing Navigation and Comms tasks, then helped with the reactor at the end.'),
  (12, 44, 'MEETING', 2, NULL, 'I did wiring in Electrical early on, way before any of this.'),
  (13, 45, 'MEETING', 8, NULL, 'Check the room logs and camera feeds before we vote on anything.'),
  (14, 3, 'RADIO', 4, 5, 'Heading to O2 then Admin, catch you at Cafeteria later'),
  (15, 5, 'RADIO', 5, 4, 'Copy, I will be at Shields'),
  (16, 18, 'RADIO', 5, NULL, 'Comms array just died, on it'),
  (17, 21, 'RADIO', 5, NULL, 'Comms back online'),
  (18, 46, 'MEETING', 4, NULL, 'I never left Storage and Weapons that whole stretch.'),
  (19, 46, 'MEETING', 7, NULL, 'Navigation and Weapons logs should back me up before Electrical.'),
  (20, 9, 'RADIO', 3, 8, 'Doing Navigation then Shields, see you at Cafeteria'),
  (21, 10, 'RADIO', 8, 3, 'Sounds good, I am on O2 duty'),
  (22, 13, 'RADIO', 7, 1, 'Security feed is quiet, heading to Weapons'),
  (23, 20, 'RADIO', 10, 4, 'Grabbing fuel from Storage, then Admin'),
  (24, 30, 'RADIO', 9, NULL, 'Reactor numbers look fine on my end'),
  (25, 47, 'MEETING', 5, NULL, 'The comms outage earlier was already fixed before any of this happened.');

INSERT INTO repair_logs (repair_id, sabotage_id, player_id, repair_minute, room_id, action, result) VALUES
  (1, 1, 4, 10, 4, 'Reset O2 filter', 'SUCCESS'),
  (2, 2, 5, 20, 6, 'Restarted comms array', 'SUCCESS'),
  (3, 3, 7, 29, 8, 'Fixed breaker switch 1', 'PARTIAL'),
  (4, 3, 10, 31, 8, 'Fixed breaker switch 2', 'SUCCESS'),
  (5, 4, 5, 41, 10, 'Hand scan (left panel)', 'PARTIAL'),
  (6, 4, 1, 42, 10, 'Hand scan (right panel)', 'SUCCESS');

INSERT INTO activity_logs (activity_id, log_minute, player_id, room_id, event_type, details) VALUES
  (1, 0, 1, 1, 'GAME_START', '10 players aboard'),
  (2, 7, 7, 12, 'CAMERA_ACCESS', 'Black checking Security monitors'),
  (3, 8, NULL, 4, 'SABOTAGE_TRIGGERED', 'O2_DEPLETION'),
  (4, 18, NULL, 6, 'SABOTAGE_TRIGGERED', 'COMMS_OUTAGE'),
  (5, 25, NULL, 8, 'SABOTAGE_TRIGGERED', 'LIGHTS'),
  (6, 26, NULL, 8, 'VENT_USED', 'Vent cover moved'),
  (7, 27, 3, 8, 'VITALS_FLATLINE', 'Crewmate vitals lost'),
  (8, 28, NULL, 13, 'VENT_USED', 'Vent cover moved'),
  (9, 30, NULL, 10, 'DOOR_LOCK', 'Reactor doors locked briefly'),
  (10, 33, 7, 12, 'CAMERA_ACCESS', 'Black checking Security monitors'),
  (11, 35, 8, 8, 'BODY_FOUND', 'Body of Green'),
  (12, 36, NULL, 1, 'MEETING_START', 'Emergency meeting called'),
  (13, 39, NULL, 10, 'SABOTAGE_TRIGGERED', 'REACTOR_MELTDOWN'),
  (14, 47, NULL, 1, 'MEETING_END', 'Evidence review in progress');

