-- SQL AMONG US : Spaceship "SKELD-7" Database
-- Mission clock: every *_minute column = minutes since launch (0-60). NULL exit_minute = never left (dead).
-- Works in MySQL 8 / SQLite / PostgreSQL. Primary keys only: Foreign Keys are intentionally left out for Part 2 (DDL round).

DROP TABLE IF EXISTS crewmates;
DROP TABLE IF EXISTS rooms;
DROP TABLE IF EXISTS room_logs;
DROP TABLE IF EXISTS movement_logs;
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
  callsign VARCHAR(20),
  department VARCHAR(30),
  tasks_assigned INT,
  final_status VARCHAR(10)
);

CREATE TABLE rooms (
  room_id INT PRIMARY KEY,
  room_name VARCHAR(30)
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

CREATE TABLE task_logs (
  task_log_id INT PRIMARY KEY,
  player_id INT,
  task_name VARCHAR(40),
  room_id INT,
  completed_minute INT,
  status VARCHAR(25)
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
  outcome VARCHAR(60),
  ejected_player_id INT
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
  message VARCHAR(120)
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
  details VARCHAR(60)
);

-- ========== DATA ==========
INSERT INTO crewmates (player_id, color, callsign, department, tasks_assigned, final_status) VALUES
  (1, 'Red', 'Red', 'Engineering', 5, 'ALIVE'),
  (2, 'Blue', 'Blue', 'Navigation Crew', 5, 'DEAD'),
  (3, 'Green', 'Green', 'Science', 5, 'DEAD'),
  (4, 'Pink', 'Pink', 'Life Support', 5, 'ALIVE'),
  (5, 'Orange', 'Orange', 'Weapons Crew', 5, 'ALIVE'),
  (6, 'Yellow', 'Yellow', 'Electrical Crew', 5, 'EJECTED'),
  (7, 'Black', 'Black', 'Security', 5, 'ALIVE'),
  (8, 'White', 'White', 'Communications', 5, 'DEAD');

INSERT INTO rooms (room_id, room_name) VALUES
  (1, 'Cafeteria'),
  (2, 'Electrical'),
  (3, 'MedBay'),
  (4, 'Reactor'),
  (5, 'Security'),
  (6, 'Admin'),
  (7, 'Navigation'),
  (8, 'O2 Storage'),
  (9, 'Communications'),
  (10, 'Weapons'),
  (11, 'Shields');

INSERT INTO room_logs (log_id, player_id, room_id, entry_minute, exit_minute) VALUES
  (1, 1, 1, 0, 3),
  (2, 2, 1, 0, 3),
  (3, 3, 1, 0, 3),
  (4, 4, 1, 0, 3),
  (5, 5, 1, 0, 3),
  (6, 6, 1, 0, 3),
  (7, 7, 1, 0, 12),
  (8, 8, 1, 0, 3),
  (9, 1, 5, 5, 14),
  (10, 2, 10, 5, 10),
  (11, 3, 11, 5, 12),
  (12, 4, 8, 5, 12),
  (13, 5, 10, 5, 12),
  (14, 6, 7, 5, 12),
  (15, 8, 9, 5, 12),
  (16, 2, 7, 11, 15),
  (17, 3, 4, 14, 20),
  (18, 4, 6, 14, 20),
  (19, 7, 10, 14, 20),
  (20, 8, 7, 14, 20),
  (21, 6, 2, 15, 21),
  (22, 2, 2, 16, NULL),
  (23, 5, 2, 17, 21),
  (24, 1, 2, 18, 22),
  (25, 1, 1, 24, 27),
  (26, 3, 1, 24, 27),
  (27, 4, 1, 24, 27),
  (28, 5, 1, 24, 27),
  (29, 6, 1, 24, 27),
  (30, 7, 1, 24, 27),
  (31, 8, 1, 24, 27),
  (32, 5, 6, 28, 31),
  (33, 3, 9, 29, 34),
  (34, 6, 6, 29, 34),
  (35, 7, 5, 29, 34),
  (36, 8, 2, 29, 34),
  (37, 1, 4, 31, 34),
  (38, 4, 4, 31, 34),
  (39, 5, 9, 33, 36),
  (40, 1, 5, 36, 42),
  (41, 3, 3, 36, NULL),
  (42, 4, 9, 36, 40),
  (43, 6, 3, 36, 39),
  (44, 7, 6, 36, 39),
  (45, 8, 10, 36, 42),
  (46, 5, 3, 38, 41),
  (47, 7, 3, 41, 42),
  (48, 4, 3, 42, 43),
  (49, 1, 1, 44, 47),
  (50, 4, 1, 44, 47),
  (51, 5, 1, 44, 47),
  (52, 6, 1, 44, 47),
  (53, 7, 1, 44, 47),
  (54, 8, 1, 44, 47),
  (55, 7, 7, 48, 50),
  (56, 1, 6, 49, 52),
  (57, 4, 8, 49, 55),
  (58, 8, 7, 49, NULL),
  (59, 5, 7, 50, 53),
  (60, 7, 6, 51, 53),
  (61, 1, 8, 53, 55),
  (62, 7, 7, 54, 55),
  (63, 1, 1, 56, 59),
  (64, 4, 1, 56, 59),
  (65, 5, 1, 56, 59),
  (66, 7, 1, 56, 59);

INSERT INTO movement_logs (move_id, player_id, from_room_id, to_room_id, move_minute) VALUES
  (1, 1, 1, 5, 3),
  (2, 2, 1, 10, 3),
  (3, 3, 1, 11, 3),
  (4, 4, 1, 8, 3),
  (5, 5, 1, 10, 3),
  (6, 6, 1, 7, 3),
  (7, 8, 1, 9, 3),
  (8, 2, 10, 7, 10),
  (9, 3, 11, 4, 12),
  (10, 4, 8, 6, 12),
  (11, 5, 10, 2, 12),
  (12, 6, 7, 2, 12),
  (13, 7, 1, 10, 12),
  (14, 8, 9, 7, 12),
  (15, 1, 5, 2, 14),
  (16, 2, 7, 2, 15),
  (17, 3, 4, 1, 20),
  (18, 4, 6, 1, 20),
  (19, 7, 10, 1, 20),
  (20, 8, 7, 1, 20),
  (21, 5, 2, 1, 21),
  (22, 6, 2, 1, 21),
  (23, 1, 2, 1, 22),
  (24, 1, 1, 4, 27),
  (25, 3, 1, 9, 27),
  (26, 4, 1, 4, 27),
  (27, 5, 1, 6, 27),
  (28, 6, 1, 6, 27),
  (29, 7, 1, 5, 27),
  (30, 8, 1, 2, 27),
  (31, 5, 6, 9, 31),
  (32, 1, 4, 5, 34),
  (33, 3, 9, 3, 34),
  (34, 4, 4, 9, 34),
  (35, 6, 6, 3, 34),
  (36, 7, 5, 6, 34),
  (37, 8, 2, 10, 34),
  (38, 5, 9, 3, 36),
  (39, 6, 3, 1, 39),
  (40, 7, 6, 3, 39),
  (41, 4, 9, 3, 40),
  (42, 5, 3, 1, 41),
  (43, 1, 5, 1, 42),
  (44, 7, 3, 1, 42),
  (45, 8, 10, 1, 42),
  (46, 4, 3, 1, 43),
  (47, 1, 1, 6, 47),
  (48, 4, 1, 8, 47),
  (49, 5, 1, 7, 47),
  (50, 7, 1, 7, 47),
  (51, 8, 1, 7, 47),
  (52, 7, 7, 6, 50),
  (53, 1, 6, 8, 52),
  (54, 5, 7, 1, 53),
  (55, 7, 6, 7, 53),
  (56, 1, 8, 1, 55),
  (57, 4, 8, 1, 55),
  (58, 7, 7, 1, 55);

INSERT INTO task_logs (task_log_id, player_id, task_name, room_id, completed_minute, status) VALUES
  (1, 1, 'Fix Wiring', 5, 8, 'COMPLETED'),
  (2, 2, 'Clear Asteroids', 10, 8, 'COMPLETED'),
  (3, 3, 'Prime Shields', 11, 9, 'COMPLETED'),
  (4, 4, 'Clean O2 Filter', 8, 9, 'COMPLETED'),
  (5, 6, 'Stabilize Steering', 7, 9, 'COMPLETED'),
  (6, 8, 'Download Data', 9, 10, 'COMPLETED'),
  (7, 2, 'Chart Course', 7, 13, 'COMPLETED'),
  (8, 3, 'Unlock Manifolds', 4, 17, 'COMPLETED'),
  (9, 4, 'Swipe Card', 6, 17, 'COMPLETED'),
  (10, 7, 'Clear Asteroids', 10, 17, 'COMPLETED'),
  (11, 6, 'Fix Wiring', 2, 18, 'COMPLETED'),
  (12, 8, 'Stabilize Steering', 7, 18, 'COMPLETED'),
  (13, 3, 'Download Data', 9, 31, 'COMPLETED'),
  (14, 6, 'Swipe Card', 6, 31, 'COMPLETED'),
  (15, 1, 'Unlock Manifolds', 4, 32, 'COMPLETED'),
  (16, 8, 'Divert Power', 2, 32, 'COMPLETED'),
  (17, 4, 'Start Reactor', 4, 33, 'COMPLETED'),
  (18, 4, 'Download Data', 9, 38, 'FAILED_COMMS_DOWN'),
  (19, 6, 'Submit Scan', 3, 38, 'COMPLETED'),
  (20, 8, 'Clear Asteroids', 10, 39, 'COMPLETED'),
  (21, 1, 'Upload Data', 6, 50, 'COMPLETED'),
  (22, 1, 'Clean O2 Filter', 8, 54, 'COMPLETED');

INSERT INTO system_status_logs (status_id, system_name, log_minute, status, note) VALUES
  (1, 'LIGHTS', 0, 'OK', 'Nominal'),
  (2, 'REACTOR', 0, 'OK', 'Nominal'),
  (3, 'O2', 0, 'OK', 'Nominal'),
  (4, 'COMMS', 0, 'OK', 'Nominal'),
  (5, 'SHIELDS', 0, 'OK', 'Nominal'),
  (6, 'LIGHTS', 17, 'SABOTAGED', 'Electrical breaker tripped'),
  (7, 'CAMERAS', 17, 'OFFLINE', 'Feeds lost - lights out'),
  (8, 'LIGHTS', 22, 'OK', 'Breaker restored'),
  (9, 'CAMERAS', 22, 'ONLINE', 'Feeds restored'),
  (10, 'REACTOR', 30, 'CRITICAL', 'Meltdown countdown started'),
  (11, 'REACTOR', 34, 'OK', 'Meltdown stopped'),
  (12, 'COMMS', 36, 'DOWN', 'Communications array offline'),
  (13, 'O2', 49, 'CRITICAL', 'Oxygen depletion started'),
  (14, 'O2', 55, 'CRITICAL', 'Still depleting - unresolved'),
  (15, 'COMMS', 55, 'DOWN', 'Still offline - unresolved');

INSERT INTO emergency_events (event_id, event_minute, event_type, called_by, location_room_id, body_of_player_id, outcome, ejected_player_id) VALUES
  (1, 22, 'BODY_REPORT', 1, 2, 2, 'MEETING: vote skipped', NULL),
  (2, 42, 'BODY_REPORT', 4, 3, 3, 'MEETING: Yellow ejected (5-2-1 skip)', 6),
  (3, 54, 'BODY_REPORT', 7, 8, 7, 'MEETING: vote tied - skipped', NULL);

INSERT INTO sabotage_records (sabotage_id, sabotage_type, room_id, start_minute, resolved_minute, status) VALUES
  (1, 'LIGHTS', 2, 17, 22, 'RESOLVED'),
  (2, 'REACTOR_MELTDOWN', 4, 30, 34, 'RESOLVED'),
  (3, 'COMMS_OUTAGE', 9, 36, NULL, 'ACTIVE'),
  (4, 'O2_DEPLETION', 8, 49, NULL, 'ACTIVE');

INSERT INTO camera_logs (cam_log_id, room_id, log_minute, observed_player_id, observation) VALUES
  (1, 7, 12, 2, 'Blue walking into Navigation'),
  (2, 6, 15, 4, 'Pink at swipe card console'),
  (3, 2, 16, 2, 'Blue enters Electrical hallway'),
  (4, 2, 18, NULL, 'Camera feed lost - lights out'),
  (5, 2, 20, NULL, 'Camera feed lost - lights out'),
  (6, 2, 22, 1, 'Red flipping lights breaker'),
  (7, 6, 30, 5, 'Orange at swipe card console'),
  (8, 6, 33, 6, 'Yellow at swipe card console'),
  (9, 3, 36, 6, 'Yellow enters MedBay hall'),
  (10, 3, 38, NULL, 'Unidentified crewmate enters MedBay (motion blur)'),
  (11, 3, 39, 6, 'Yellow exits MedBay'),
  (12, 3, 41, NULL, 'Crewmate leaving MedBay - face not visible'),
  (13, 3, 41, 7, 'Black enters MedBay hall'),
  (14, 3, 42, 4, 'Pink enters MedBay'),
  (15, 7, 48, 7, 'Black enters Navigation'),
  (16, 7, 49, 8, 'White enters Navigation'),
  (17, 7, 50, 7, 'Black exits Navigation'),
  (18, 7, 50, NULL, 'Crewmate enters Navigation - hood color unclear'),
  (19, 6, 50, 1, 'Red at upload console'),
  (20, 6, 52, 7, 'Black arrives at Admin'),
  (21, 7, 53, NULL, 'Crewmate leaves Navigation - camera angle blocked'),
  (22, 7, 54, 7, 'Black re-enters Navigation');

INSERT INTO communication_logs (comm_id, sent_minute, channel, sender_id, receiver_id, message) VALUES
  (1, 1, 'RADIO', 1, 2, 'Meet at Electrical later for wires?'),
  (2, 2, 'RADIO', 2, 1, 'Ok, after Weapons'),
  (3, 22, 'RADIO', 1, NULL, 'BODY in Electrical! Blue is dead. Reporting!'),
  (4, 24, 'MEETING', 1, NULL, 'Found Blue in Electrical next to the lights switch.'),
  (5, 24, 'MEETING', 6, NULL, 'I was doing wires there until 21. Lights were out, saw nothing.'),
  (6, 25, 'MEETING', 5, NULL, 'I was at Weapons doing asteroids then came straight here. I never went near Electrical.'),
  (7, 25, 'MEETING', 7, NULL, 'Yellow is sus. Wires is the oldest excuse.'),
  (8, 26, 'MEETING', 4, NULL, 'Red was in Electrical too. I was in Admin.'),
  (9, 26, 'MEETING', 1, NULL, 'I went to fix the lights. Check the cams.'),
  (10, 27, 'MEETING', 5, NULL, 'No real evidence. Skip.'),
  (11, 35, 'RADIO', 3, 4, 'Heading to MedBay for my scan'),
  (12, 42, 'RADIO', 4, NULL, 'Green is dead in MedBay!'),
  (13, 44, 'MEETING', 4, NULL, 'Found Green at 42. Black came in right before me.'),
  (14, 44, 'MEETING', 7, NULL, 'I passed by, saw the body, left. Wasnt me.'),
  (15, 45, 'MEETING', 6, NULL, 'I was in MedBay with Green till 39. Orange was walking in as I left.'),
  (16, 45, 'MEETING', 5, NULL, 'Lie. Yellow is deflecting. I was in Communications the whole time.'),
  (17, 46, 'MEETING', 1, NULL, 'Yellow was at both kill rooms. Vote Yellow.'),
  (18, 46, 'MEETING', 4, NULL, 'Agree. Vote Yellow.'),
  (19, 47, 'MEETING', 6, NULL, 'Check the logs! It is not me!'),
  (20, 51, 'RADIO', 7, 4, 'O2 alarm! Going to Admin to enter the code.'),
  (21, 54, 'RADIO', 7, NULL, 'White is dead in Navigation!'),
  (22, 56, 'MEETING', 7, NULL, 'Found White at 54. I saw Red heading toward O2.'),
  (23, 57, 'MEETING', 5, NULL, 'Black was in Navigation twice. Black is the imposter.'),
  (24, 57, 'MEETING', 1, NULL, 'I was in Admin then O2. Never entered Navigation.'),
  (25, 58, 'MEETING', 4, NULL, 'Check the logs before we vote.');

INSERT INTO repair_logs (repair_id, sabotage_id, player_id, repair_minute, room_id, action, result) VALUES
  (1, 1, 2, 19, 2, 'Tried switch 1 (lights out)', 'FAILED'),
  (2, 1, 6, 20, 2, 'Fixed switch 3', 'PARTIAL'),
  (3, 1, 1, 22, 2, 'Fixed switch 5', 'SUCCESS'),
  (4, 2, 1, 32, 4, 'Hand scan (left panel)', 'IN_PROGRESS'),
  (5, 2, 4, 33, 4, 'Hand scan (right panel)', 'SUCCESS'),
  (6, 3, 4, 38, 9, 'Reset comms panel', 'FAILED'),
  (7, 4, 4, 50, 8, 'Entered O2 code at O2 panel', 'PARTIAL'),
  (8, 4, 7, 52, 6, 'Entered O2 code at Admin panel', 'PARTIAL'),
  (9, 4, 1, 54, 8, 'Entered O2 code (second attempt)', 'PARTIAL');

INSERT INTO activity_logs (activity_id, log_minute, player_id, room_id, event_type, details) VALUES
  (1, 0, NULL, 1, 'GAME_START', '8 players aboard'),
  (2, 8, 1, 5, 'CAMERA_ACCESS', 'Red checking Security monitors'),
  (3, 12, 1, 5, 'CAMERA_ACCESS', 'Red checking Security monitors'),
  (4, 17, NULL, 2, 'SABOTAGE_TRIGGERED', 'LIGHTS'),
  (5, 20, 2, 2, 'VITALS_FLATLINE', 'Crewmate vitals lost'),
  (6, 21, NULL, 2, 'VENT_USED', 'Vent cover moved'),
  (7, 22, 1, 2, 'BODY_FOUND', 'Body of Blue'),
  (8, 24, NULL, 1, 'MEETING_START', 'Meeting 1'),
  (9, 27, NULL, 1, 'MEETING_END', 'Vote skipped'),
  (10, 30, NULL, 4, 'SABOTAGE_TRIGGERED', 'REACTOR_MELTDOWN'),
  (11, 31, NULL, 4, 'DOOR_LOCK', 'Reactor doors locked 2 min'),
  (12, 36, NULL, 9, 'SABOTAGE_TRIGGERED', 'COMMS_OUTAGE'),
  (13, 36, NULL, 5, 'DOOR_LOCK', 'Security doors locked 1 min'),
  (14, 38, 1, 5, 'CAMERA_ACCESS', 'Red checking Security monitors'),
  (15, 40, 3, 3, 'VITALS_FLATLINE', 'Crewmate vitals lost'),
  (16, 41, NULL, 3, 'VENT_USED', 'Vent cover moved'),
  (17, 42, 4, 3, 'BODY_FOUND', 'Body of Green'),
  (18, 44, NULL, 1, 'MEETING_START', 'Meeting 2'),
  (19, 47, 6, 1, 'EJECTION', 'Yellow ejected'),
  (20, 49, NULL, 8, 'SABOTAGE_TRIGGERED', 'O2_DEPLETION'),
  (21, 52, 8, 7, 'VITALS_FLATLINE', 'Crewmate vitals lost'),
  (22, 53, NULL, 7, 'VENT_USED', 'Vent cover moved'),
  (23, 54, 7, 7, 'BODY_FOUND', 'Body of White'),
  (24, 55, NULL, 1, 'MEETING_START', 'Meeting 3'),
  (25, 58, NULL, 1, 'MEETING_END', 'Vote tied - skipped');

