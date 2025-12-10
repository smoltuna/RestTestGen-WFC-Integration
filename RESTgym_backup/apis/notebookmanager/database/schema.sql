-- NoteBook Manager Database Schema
-- MySQL/H2 compatible schema

CREATE TABLE IF NOT EXISTS note_book (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) UNIQUE NOT NULL,
    current_price DOUBLE NOT NULL,
    last_update TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE INDEX idx_notebook_name ON note_book(name);
