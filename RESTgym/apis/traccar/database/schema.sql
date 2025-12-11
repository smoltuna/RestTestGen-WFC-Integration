-- Traccar Database Schema (Simplified for RESTgym)
-- Based on Liquibase changelog-4.0-clean.xml

-- Users Table
CREATE TABLE IF NOT EXISTS tc_users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(128) NOT NULL,
    email VARCHAR(128) NOT NULL UNIQUE,
    login VARCHAR(128),
    hashedPassword VARCHAR(128),
    salt VARCHAR(128),
    readonly BOOLEAN DEFAULT FALSE,
    administrator BOOLEAN DEFAULT FALSE,
    map VARCHAR(128),
    latitude DOUBLE,
    longitude DOUBLE,
    zoom INT,
    twelveHourFormat BOOLEAN DEFAULT FALSE,
    coordinateFormat VARCHAR(128),
    disabled BOOLEAN DEFAULT FALSE,
    expirationTime TIMESTAMP,
    deviceLimit INT DEFAULT -1,
    userLimit INT DEFAULT 0,
    deviceReadonly BOOLEAN DEFAULT FALSE,
    limitCommands BOOLEAN DEFAULT FALSE,
    poiLayer VARCHAR(512),
    token VARCHAR(128) UNIQUE,
    attributes VARCHAR(4000)
);

-- Devices Table
CREATE TABLE IF NOT EXISTS tc_devices (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(128) NOT NULL,
    uniqueId VARCHAR(128) NOT NULL UNIQUE,
    lastUpdate TIMESTAMP,
    positionId INT,
    groupId INT,
    attributes VARCHAR(4000),
    phone VARCHAR(128),
    model VARCHAR(128),
    contact VARCHAR(512),
    category VARCHAR(128),
    disabled BOOLEAN DEFAULT FALSE,
    status VARCHAR(128)
);

-- Groups Table
CREATE TABLE IF NOT EXISTS tc_groups (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(128) NOT NULL,
    groupId INT,
    attributes VARCHAR(4000)
);

-- Positions Table
CREATE TABLE IF NOT EXISTS tc_positions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    protocol VARCHAR(128),
    deviceId INT NOT NULL,
    serverTime TIMESTAMP NOT NULL,
    deviceTime TIMESTAMP NOT NULL,
    fixTime TIMESTAMP NOT NULL,
    valid BOOLEAN NOT NULL,
    latitude DOUBLE NOT NULL,
    longitude DOUBLE NOT NULL,
    altitude DOUBLE,
    speed DOUBLE,
    course DOUBLE,
    address VARCHAR(512),
    accuracy DOUBLE,
    network VARCHAR(4000),
    attributes VARCHAR(4000)
);

-- Geofences Table
CREATE TABLE IF NOT EXISTS tc_geofences (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(128) NOT NULL,
    description VARCHAR(128),
    area VARCHAR(4096) NOT NULL,
    attributes VARCHAR(4000),
    calendarId INT
);

-- Events Table
CREATE TABLE IF NOT EXISTS tc_events (
    id INT AUTO_INCREMENT PRIMARY KEY,
    type VARCHAR(128) NOT NULL,
    serverTime TIMESTAMP NOT NULL,
    deviceId INT,
    positionId INT,
    geofenceId INT,
    attributes VARCHAR(4000),
    maintenanceId INT
);

-- Commands Table
CREATE TABLE IF NOT EXISTS tc_commands (
    id INT AUTO_INCREMENT PRIMARY KEY,
    description VARCHAR(4000) NOT NULL,
    type VARCHAR(128) NOT NULL,
    textChannel BOOLEAN DEFAULT FALSE,
    attributes VARCHAR(4000) NOT NULL
);

-- Notifications Table
CREATE TABLE IF NOT EXISTS tc_notifications (
    id INT AUTO_INCREMENT PRIMARY KEY,
    type VARCHAR(128) NOT NULL,
    always BOOLEAN DEFAULT FALSE,
    notificators VARCHAR(128),
    attributes VARCHAR(4000),
    calendarId INT
);

-- Calendars Table
CREATE TABLE IF NOT EXISTS tc_calendars (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(128) NOT NULL,
    data BLOB NOT NULL,
    attributes VARCHAR(4000) NOT NULL
);

-- Attributes Table (Computed Attributes)
CREATE TABLE IF NOT EXISTS tc_attributes (
    id INT AUTO_INCREMENT PRIMARY KEY,
    description VARCHAR(4000) NOT NULL,
    type VARCHAR(128) NOT NULL,
    attribute VARCHAR(128) NOT NULL,
    expression VARCHAR(4000) NOT NULL
);

-- Drivers Table
CREATE TABLE IF NOT EXISTS tc_drivers (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(128) NOT NULL,
    uniqueId VARCHAR(128) NOT NULL UNIQUE,
    attributes VARCHAR(4000) NOT NULL
);

-- Maintenance Table
CREATE TABLE IF NOT EXISTS tc_maintenance (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(128) NOT NULL,
    type VARCHAR(128) NOT NULL,
    start DOUBLE NOT NULL,
    period DOUBLE NOT NULL,
    attributes VARCHAR(4000) NOT NULL
);

-- Server Table
CREATE TABLE IF NOT EXISTS tc_servers (
    id INT AUTO_INCREMENT PRIMARY KEY,
    registration BOOLEAN DEFAULT TRUE,
    readonly BOOLEAN DEFAULT FALSE,
    map VARCHAR(128),
    bingKey VARCHAR(128),
    mapUrl VARCHAR(512),
    latitude DOUBLE DEFAULT 0,
    longitude DOUBLE DEFAULT 0,
    zoom INT DEFAULT 0,
    twelveHourFormat BOOLEAN DEFAULT FALSE,
    forceSettings BOOLEAN DEFAULT FALSE,
    coordinateFormat VARCHAR(128),
    attributes VARCHAR(4000),
    version VARCHAR(128),
    announcement VARCHAR(4000)
);

-- Permission Tables (User-Device relationships)
CREATE TABLE IF NOT EXISTS tc_user_device (
    userId INT NOT NULL,
    deviceId INT NOT NULL,
    PRIMARY KEY (userId, deviceId)
);

CREATE TABLE IF NOT EXISTS tc_user_group (
    userId INT NOT NULL,
    groupId INT NOT NULL,
    PRIMARY KEY (userId, groupId)
);

CREATE TABLE IF NOT EXISTS tc_user_geofence (
    userId INT NOT NULL,
    geofenceId INT NOT NULL,
    PRIMARY KEY (userId, geofenceId)
);

CREATE TABLE IF NOT EXISTS tc_user_notification (
    userId INT NOT NULL,
    notificationId INT NOT NULL,
    PRIMARY KEY (userId, notificationId)
);

CREATE TABLE IF NOT EXISTS tc_user_calendar (
    userId INT NOT NULL,
    calendarId INT NOT NULL,
    PRIMARY KEY (userId, calendarId)
);

CREATE TABLE IF NOT EXISTS tc_user_attribute (
    userId INT NOT NULL,
    attributeId INT NOT NULL,
    PRIMARY KEY (userId, attributeId)
);

CREATE TABLE IF NOT EXISTS tc_user_driver (
    userId INT NOT NULL,
    driverId INT NOT NULL,
    PRIMARY KEY (userId, driverId)
);

CREATE TABLE IF NOT EXISTS tc_user_maintenance (
    userId INT NOT NULL,
    maintenanceId INT NOT NULL,
    PRIMARY KEY (userId, maintenanceId)
);

-- Device Permission Tables
CREATE TABLE IF NOT EXISTS tc_device_geofence (
    deviceId INT NOT NULL,
    geofenceId INT NOT NULL,
    PRIMARY KEY (deviceId, geofenceId)
);

CREATE TABLE IF NOT EXISTS tc_device_notification (
    deviceId INT NOT NULL,
    notificationId INT NOT NULL,
    PRIMARY KEY (deviceId, notificationId)
);

CREATE TABLE IF NOT EXISTS tc_device_attribute (
    deviceId INT NOT NULL,
    attributeId INT NOT NULL,
    PRIMARY KEY (deviceId, attributeId)
);

CREATE TABLE IF NOT EXISTS tc_device_driver (
    deviceId INT NOT NULL,
    driverId INT NOT NULL,
    PRIMARY KEY (deviceId, driverId)
);

CREATE TABLE IF NOT EXISTS tc_device_maintenance (
    deviceId INT NOT NULL,
    maintenanceId INT NOT NULL,
    PRIMARY KEY (deviceId, maintenanceId)
);

CREATE TABLE IF NOT EXISTS tc_device_command (
    deviceId INT NOT NULL,
    commandId INT NOT NULL,
    PRIMARY KEY (deviceId, commandId)
);

-- Group Permission Tables
CREATE TABLE IF NOT EXISTS tc_group_geofence (
    groupId INT NOT NULL,
    geofenceId INT NOT NULL,
    PRIMARY KEY (groupId, geofenceId)
);

CREATE TABLE IF NOT EXISTS tc_group_notification (
    groupId INT NOT NULL,
    notificationId INT NOT NULL,
    PRIMARY KEY (groupId, notificationId)
);

CREATE TABLE IF NOT EXISTS tc_group_attribute (
    groupId INT NOT NULL,
    attributeId INT NOT NULL,
    PRIMARY KEY (groupId, attributeId)
);

CREATE TABLE IF NOT EXISTS tc_group_driver (
    groupId INT NOT NULL,
    driverId INT NOT NULL,
    PRIMARY KEY (groupId, driverId)
);

CREATE TABLE IF NOT EXISTS tc_group_maintenance (
    groupId INT NOT NULL,
    maintenanceId INT NOT NULL,
    PRIMARY KEY (groupId, maintenanceId)
);

CREATE TABLE IF NOT EXISTS tc_group_command (
    groupId INT NOT NULL,
    commandId INT NOT NULL,
    PRIMARY KEY (groupId, commandId)
);

-- Statistics Table
CREATE TABLE IF NOT EXISTS tc_statistics (
    id INT AUTO_INCREMENT PRIMARY KEY,
    captureTime TIMESTAMP NOT NULL,
    activeUsers INT DEFAULT 0,
    activeDevices INT DEFAULT 0,
    requests INT DEFAULT 0,
    messagesReceived INT DEFAULT 0,
    messagesStored INT DEFAULT 0,
    mailSent INT DEFAULT 0,
    smsSent INT DEFAULT 0,
    geocoderRequests INT DEFAULT 0,
    geolocationRequests INT DEFAULT 0
);

-- Create indexes for performance
CREATE INDEX idx_positions_deviceId ON tc_positions(deviceId);
CREATE INDEX idx_positions_deviceTime ON tc_positions(deviceTime);
CREATE INDEX idx_events_deviceId ON tc_events(deviceId);
CREATE INDEX idx_events_type ON tc_events(type);
CREATE INDEX idx_events_serverTime ON tc_events(serverTime);
CREATE INDEX idx_devices_uniqueId ON tc_devices(uniqueId);
CREATE INDEX idx_users_email ON tc_users(email);

-- Insert default server configuration (required by Traccar)
INSERT INTO tc_servers (id, registration, readonly, latitude, longitude, zoom, version)
VALUES (1, TRUE, FALSE, 0, 0, 0, '6.10.0');
