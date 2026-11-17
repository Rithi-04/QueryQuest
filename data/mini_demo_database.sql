-- SQL AMONG US : MINI DEMO (Easy)  | minutes = since launch
DROP TABLE IF EXISTS crewmates;
CREATE TABLE crewmates (
  player_id INT PRIMARY KEY,
  color VARCHAR(60),
  tasks_assigned INT
);
DROP TABLE IF EXISTS rooms;
CREATE TABLE rooms (
  room_id INT PRIMARY KEY,
  room_name VARCHAR(60)
);
DROP TABLE IF EXISTS room_logs;
CREATE TABLE room_logs (
  log_id INT PRIMARY KEY,
  player_id INT,
  room_id INT,
  entry_minute INT,
  exit_minute INT
);
DROP TABLE IF EXISTS task_logs;
CREATE TABLE task_logs (
  task_log_id INT PRIMARY KEY,
  player_id INT,
  task_name VARCHAR(60),
  room_id INT,
  completed_minute INT,
  status VARCHAR(60)
);
DROP TABLE IF EXISTS camera_logs;
CREATE TABLE camera_logs (
  cam_log_id INT PRIMARY KEY,
  room_id INT,
  log_minute INT,
  observed_player_id INT,
  observation VARCHAR(60)
);
DROP TABLE IF EXISTS communication_logs;
CREATE TABLE communication_logs (
  comm_id INT PRIMARY KEY,
  sent_minute INT,
  sender_id INT,
  message VARCHAR(60)
);
DROP TABLE IF EXISTS activity_logs;
CREATE TABLE activity_logs (
  activity_id INT PRIMARY KEY,
  log_minute INT,
  player_id INT,
  room_id INT,
  event_type VARCHAR(60),
  details VARCHAR(60)
);
INSERT INTO crewmates (player_id, color, tasks_assigned) VALUES
  (1, 'Red', 3),
  (2, 'Blue', 3),
  (3, 'Green', 3),
  (4, 'Pink', 3),
  (5, 'Orange', 3);
INSERT INTO rooms (room_id, room_name) VALUES
  (1, 'Cafeteria'),
  (2, 'Electrical'),
  (3, 'MedBay'),
  (4, 'Admin'),
  (5, 'Navigation');
INSERT INTO room_logs (log_id, player_id, room_id, entry_minute, exit_minute) VALUES
  (1, 1, 1, 0, 5),
  (2, 2, 1, 0, 5),
  (3, 3, 1, 0, 5),
  (4, 4, 1, 0, 5),
  (5, 5, 1, 0, 5),
  (6, 1, 4, 7, 21),
  (7, 2, 5, 7, 14),
  (8, 3, 2, 7, 12),
  (9, 4, 3, 7, 23),
  (10, 5, 4, 7, 12),
  (11, 3, 3, 14, 23),
  (12, 2, 2, 16, NULL),
  (13, 5, 2, 17, 21),
  (14, 1, 2, 22, 23),
  (15, 1, 1, 25, 30),
  (16, 3, 1, 25, 30),
  (17, 4, 1, 25, 30),
  (18, 5, 1, 25, 30);
INSERT INTO task_logs (task_log_id, player_id, task_name, room_id, completed_minute, status) VALUES
  (1, 3, 'Fix Wiring', 2, 9, 'COMPLETED'),
  (2, 1, 'Upload Data', 4, 10, 'COMPLETED'),
  (3, 2, 'Chart Course', 5, 10, 'COMPLETED'),
  (4, 4, 'Inspect Sample', 3, 12, 'COMPLETED'),
  (5, 1, 'Swipe Card', 4, 15, 'COMPLETED'),
  (6, 3, 'Submit Scan', 3, 18, 'COMPLETED'),
  (7, 4, 'Submit Scan', 3, 21, 'COMPLETED');
INSERT INTO camera_logs (cam_log_id, room_id, log_minute, observed_player_id, observation) VALUES
  (1, 4, 10, 1, 'Red at Admin console'),
  (2, 5, 12, 2, 'Blue at Navigation console'),
  (3, 2, 19, 5, 'Orange seen at Electrical door');
INSERT INTO communication_logs (comm_id, sent_minute, sender_id, message) VALUES
  (1, 25, 1, 'Found Blue dead in Electrical.'),
  (2, 25, 5, 'I was in MedBay the whole time.'),
  (3, 26, 3, 'I was in MedBay with Pink. Orange was not there.'),
  (4, 26, 4, 'Yes, Green and I were together in MedBay.');
INSERT INTO activity_logs (activity_id, log_minute, player_id, room_id, event_type, details) VALUES
  (1, 0, NULL, 1, 'GAME_START', '5 players aboard'),
  (2, 20, 2, 2, 'VITALS_FLATLINE', 'Crewmate vitals lost'),
  (3, 21, NULL, 2, 'VENT_USED', 'Vent cover moved'),
  (4, 23, 1, 2, 'BODY_FOUND', 'Body of Blue'),
  (5, 25, NULL, 1, 'MEETING_START', 'Emergency meeting'),
  (6, 30, NULL, 1, 'MEETING_END', 'Vote pending');
