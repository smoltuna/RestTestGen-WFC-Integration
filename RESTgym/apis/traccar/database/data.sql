-- Traccar Sample Data for RESTgym Testing

-- Insert Server configuration
INSERT INTO tc_servers (id, registration, readonly, latitude, longitude, zoom, twelveHourFormat, version) 
VALUES (1, TRUE, FALSE, 0, 0, 0, FALSE, '6.10.0');

-- Insert test users
-- Password: 'admin' hashed with SHA-256 (simplified for testing)
INSERT INTO tc_users (id, name, email, administrator, readonly, disabled, deviceLimit, userLimit) VALUES
(1, 'Admin User', 'admin@traccar.org', TRUE, FALSE, FALSE, -1, 0),
(2, 'Test User', 'test@example.com', FALSE, FALSE, FALSE, 10, 0),
(3, 'Demo User', 'demo@demo.com', FALSE, FALSE, FALSE, 5, 0),
(4, 'Manager', 'manager@company.com', FALSE, FALSE, FALSE, 50, 5),
(5, 'Readonly User', 'readonly@example.com', FALSE, TRUE, FALSE, 0, 0);

-- Insert test groups
INSERT INTO tc_groups (id, name, groupId) VALUES
(1, 'All Devices', NULL),
(2, 'Fleet A', 1),
(3, 'Fleet B', 1),
(4, 'Personal Trackers', 1),
(5, 'Company Vehicles', 1);

-- Insert test devices
INSERT INTO tc_devices (id, name, uniqueId, groupId, category, disabled, status) VALUES
(1, 'Vehicle GPS-001', '123456789012345', 2, 'car', FALSE, 'online'),
(2, 'Truck-A', '111111111111111', 2, 'truck', FALSE, 'online'),
(3, 'Personal-Tracker-001', 'ABCDEF123456789', 4, 'person', FALSE, 'online'),
(4, 'Fleet-Van-01', '354678901234567', 3, 'van', FALSE, 'offline'),
(5, 'Motorcycle-GPS', '867890123456789', 4, 'motorcycle', FALSE, 'online'),
(6, 'Bus-Route-101', '999999999999999', 5, 'bus', FALSE, 'online'),
(7, 'Emergency-Vehicle', '001122334455667', 5, 'default', FALSE, 'online'),
(8, 'Delivery-Van-02', 'test-unique-id', 3, 'van', FALSE, 'offline'),
(9, 'Asset-Tracker-001', 'tracker-serial-123', 1, 'default', FALSE, 'unknown'),
(10, 'Field-Worker-GPS', 'gps-unit-456', 4, 'person', TRUE, 'offline');

-- Insert test positions
INSERT INTO tc_positions (id, deviceId, protocol, serverTime, deviceTime, fixTime, valid, latitude, longitude, altitude, speed, course, accuracy) VALUES
(1, 1, 'gps103', '2024-11-27 10:00:00', '2024-11-27 10:00:00', '2024-11-27 10:00:00', TRUE, 30.5234, -97.6789, 150, 60, 90, 10),
(2, 2, 'tk103', '2024-11-27 10:05:00', '2024-11-27 10:05:00', '2024-11-27 10:05:00', TRUE, 40.7128, -74.0060, 20, 45, 180, 15),
(3, 3, 'osmand', '2024-11-27 10:10:00', '2024-11-27 10:10:00', '2024-11-27 10:10:00', TRUE, 51.5074, -0.1278, 50, 5, 270, 5),
(4, 5, 'gl200', '2024-11-27 10:15:00', '2024-11-27 10:15:00', '2024-11-27 10:15:00', TRUE, 35.6762, 139.6503, 40, 80, 45, 20),
(5, 6, 't55', '2024-11-27 10:20:00', '2024-11-27 10:20:00', '2024-11-27 10:20:00', TRUE, 48.8566, 2.3522, 35, 30, 135, 12),
(6, 7, 'xexun', '2024-11-27 10:25:00', '2024-11-27 10:25:00', '2024-11-27 10:25:00', TRUE, 55.7558, 37.6173, 150, 90, 225, 8),
(7, 1, 'gps103', '2024-11-27 11:00:00', '2024-11-27 11:00:00', '2024-11-27 11:00:00', TRUE, 30.5300, -97.6800, 155, 65, 95, 10),
(8, 2, 'tk103', '2024-11-27 11:05:00', '2024-11-27 11:05:00', '2024-11-27 11:05:00', TRUE, 40.7200, -74.0100, 25, 50, 185, 15);

-- Insert test geofences
INSERT INTO tc_geofences (id, name, description, area) VALUES
(1, 'Headquarters', 'Company headquarters', 'CIRCLE (30.5234 -97.6789, 500)'),
(2, 'Warehouse', 'Main warehouse', 'CIRCLE (40.7128 -74.0060, 1000)'),
(3, 'Office Building', 'Downtown office', 'CIRCLE (51.5074 -0.1278, 750)'),
(4, 'Depot', 'Vehicle depot', 'POLYGON ((30.5 -97.7, 30.6 -97.7, 30.6 -97.6, 30.5 -97.6, 30.5 -97.7))'),
(5, 'Restricted Area', 'No entry zone', 'CIRCLE (48.8566 2.3522, 200)');

-- Insert test events
INSERT INTO tc_events (id, type, serverTime, deviceId, positionId, geofenceId) VALUES
(1, 'deviceOnline', '2024-11-27 09:00:00', 1, 1, NULL),
(2, 'deviceOnline', '2024-11-27 09:05:00', 2, 2, NULL),
(3, 'geofenceEnter', '2024-11-27 10:00:00', 1, 1, 1),
(4, 'deviceMoving', '2024-11-27 10:10:00', 1, 1, NULL),
(5, 'deviceOverspeed', '2024-11-27 10:15:00', 2, 2, NULL),
(6, 'geofenceExit', '2024-11-27 11:00:00', 1, 7, 1),
(7, 'deviceOnline', '2024-11-27 09:10:00', 3, 3, NULL),
(8, 'deviceOffline', '2024-11-27 12:00:00', 4, NULL, NULL);

-- Insert test commands
INSERT INTO tc_commands (id, description, type, textChannel) VALUES
(1, 'Get single position', 'positionSingle', FALSE),
(2, 'Start periodic position tracking', 'positionPeriodic', FALSE),
(3, 'Stop engine', 'engineStop', FALSE),
(4, 'Resume engine', 'engineResume', FALSE),
(5, 'Arm alarm', 'alarmArm', FALSE),
(6, 'Disarm alarm', 'alarmDisarm', FALSE),
(7, 'Reboot device', 'rebootDevice', FALSE),
(8, 'Send SMS', 'sendSms', TRUE),
(9, 'Request photo', 'requestPhoto', FALSE),
(10, 'Custom command', 'custom', FALSE);

-- Insert test notifications
INSERT INTO tc_notifications (id, type, always, notificators) VALUES
(1, 'deviceOnline', FALSE, 'web,mail'),
(2, 'deviceOffline', TRUE, 'web,mail,sms'),
(3, 'deviceOverspeed', TRUE, 'web,mail'),
(4, 'geofenceEnter', FALSE, 'web'),
(5, 'geofenceExit', FALSE, 'web'),
(6, 'alarm', TRUE, 'web,mail,sms'),
(7, 'deviceMoving', FALSE, 'web'),
(8, 'deviceStopped', FALSE, 'web');

-- Insert test calendars
INSERT INTO tc_calendars (id, name, data, attributes) VALUES
(1, 'Working Days', X'424547494E3A5643414C454E4441520A56455253494F4E3A322E300A50524F4449443A2D2F2F54726163636172204750532054726163', '{}'),
(2, 'Weekends', X'424547494E3A5643414C454E4441520A56455253494F4E3A322E300A50524F4449443A2D2F2F54726163636172204750532054726163', '{}'),
(3, 'Business Hours', X'424547494E3A5643414C454E4441520A56455253494F4E3A322E300A50524F4449443A2D2F2F54726163636172204750532054726163', '{}');

-- Insert test attributes (computed attributes)
INSERT INTO tc_attributes (id, description, type, attribute, expression) VALUES
(1, 'Fuel level percentage', 'number', 'fuelLevel', 'io1'),
(2, 'Engine temperature', 'number', 'temperature', 'io2 * 0.1'),
(3, 'Battery voltage', 'number', 'batteryLevel', 'io3 * 0.01'),
(4, 'Speed in MPH', 'number', 'speedMph', 'speed * 0.621371'),
(5, 'High speed alert', 'boolean', 'highSpeed', 'speed > 100');

-- Insert test drivers
INSERT INTO tc_drivers (id, name, uniqueId, attributes) VALUES
(1, 'John Smith', 'DRV001', '{"license":"ABC123","phone":"+1234567890"}'),
(2, 'Jane Doe', 'DRV002', '{"license":"XYZ789","phone":"+0987654321"}'),
(3, 'Mike Johnson', 'DRV003', '{"license":"DEF456","phone":"+1122334455"}'),
(4, 'Sarah Wilson', 'DRV004', '{"license":"GHI789","phone":"+5566778899"}');

-- Insert test maintenance
INSERT INTO tc_maintenance (id, name, type, start, period, attributes) VALUES
(1, 'Oil Change', 'totalDistance', 0, 5000, '{"description":"Regular oil change every 5000 km"}'),
(2, 'Tire Rotation', 'totalDistance', 0, 10000, '{"description":"Rotate tires every 10000 km"}'),
(3, 'Annual Service', 'totalDistance', 0, 20000, '{"description":"Complete annual service"}'),
(4, 'Brake Inspection', 'totalDistance', 0, 15000, '{"description":"Inspect brakes every 15000 km"}');

-- Insert test statistics
INSERT INTO tc_statistics (captureTime, activeUsers, activeDevices, requests, messagesReceived, messagesStored, mailSent, smsSent) VALUES
('2024-11-27 00:00:00', 5, 10, 1250, 850, 850, 15, 3),
('2024-11-27 01:00:00', 3, 8, 950, 720, 720, 8, 1),
('2024-11-27 02:00:00', 2, 6, 600, 480, 480, 2, 0);

-- Create user-device permissions
INSERT INTO tc_user_device (userId, deviceId) VALUES
(1, 1), (1, 2), (1, 3), (1, 4), (1, 5), (1, 6), (1, 7), (1, 8), (1, 9), (1, 10),  -- Admin has all devices
(2, 1), (2, 3), (2, 5),  -- Test user has 3 devices
(3, 1), (3, 2),  -- Demo user has 2 devices
(4, 1), (4, 2), (4, 4), (4, 6), (4, 7), (4, 8);  -- Manager has 6 devices

-- Create user-group permissions
INSERT INTO tc_user_group (userId, groupId) VALUES
(1, 1), (1, 2), (1, 3), (1, 4), (1, 5),  -- Admin has all groups
(2, 2), (2, 4),  -- Test user has 2 groups
(3, 2),  -- Demo user has 1 group
(4, 2), (4, 3), (4, 5);  -- Manager has 3 groups

-- Create user-geofence permissions
INSERT INTO tc_user_geofence (userId, geofenceId) VALUES
(1, 1), (1, 2), (1, 3), (1, 4), (1, 5),  -- Admin has all geofences
(2, 1), (2, 2),  -- Test user has 2 geofences
(3, 1),  -- Demo user has 1 geofence
(4, 1), (4, 2), (4, 3), (4, 4);  -- Manager has 4 geofences

-- Create user-notification permissions
INSERT INTO tc_user_notification (userId, notificationId) VALUES
(1, 1), (1, 2), (1, 3), (1, 4), (1, 5), (1, 6), (1, 7), (1, 8),  -- Admin has all notifications
(2, 1), (2, 2), (2, 3),  -- Test user has 3 notifications
(3, 1), (3, 2),  -- Demo user has 2 notifications
(4, 1), (4, 2), (4, 3), (4, 6);  -- Manager has 4 notifications

-- Create device-geofence associations
INSERT INTO tc_device_geofence (deviceId, geofenceId) VALUES
(1, 1), (1, 2),  -- Device 1 in 2 geofences
(2, 2),  -- Device 2 in 1 geofence
(3, 3),  -- Device 3 in 1 geofence
(6, 1), (6, 2), (6, 4),  -- Device 6 in 3 geofences
(7, 5);  -- Device 7 in restricted area

-- Create device-command associations
INSERT INTO tc_device_command (deviceId, commandId) VALUES
(1, 1), (1, 2), (1, 3), (1, 4), (1, 5),  -- Device 1 has 5 commands
(2, 1), (2, 2), (2, 3),  -- Device 2 has 3 commands
(3, 1), (3, 2),  -- Device 3 has 2 commands
(5, 1), (5, 2), (5, 3), (5, 4), (5, 5), (5, 6);  -- Device 5 has 6 commands

-- Create device-driver associations
INSERT INTO tc_device_driver (deviceId, driverId) VALUES
(1, 1),  -- Device 1 -> Driver 1
(2, 2),  -- Device 2 -> Driver 2
(5, 3),  -- Device 5 -> Driver 3
(6, 4);  -- Device 6 -> Driver 4

-- Create device-maintenance associations
INSERT INTO tc_device_maintenance (deviceId, maintenanceId) VALUES
(1, 1), (1, 2), (1, 3),  -- Device 1 has 3 maintenance schedules
(2, 1), (2, 4),  -- Device 2 has 2 maintenance schedules
(6, 1), (6, 2), (6, 3), (6, 4);  -- Device 6 has all maintenance schedules

-- Update device positions
UPDATE tc_devices SET positionId = 1, lastUpdate = '2024-11-27 11:00:00' WHERE id = 1;
UPDATE tc_devices SET positionId = 2, lastUpdate = '2024-11-27 11:05:00' WHERE id = 2;
UPDATE tc_devices SET positionId = 3, lastUpdate = '2024-11-27 10:10:00' WHERE id = 3;
UPDATE tc_devices SET positionId = 4, lastUpdate = '2024-11-27 10:15:00' WHERE id = 5;
UPDATE tc_devices SET positionId = 5, lastUpdate = '2024-11-27 10:20:00' WHERE id = 6;
UPDATE tc_devices SET positionId = 6, lastUpdate = '2024-11-27 10:25:00' WHERE id = 7;
