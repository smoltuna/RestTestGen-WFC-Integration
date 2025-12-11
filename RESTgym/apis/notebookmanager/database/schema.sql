-- NoteBook Manager Database Schema
-- MySQL/H2 compatible schema
-- Modified to allow test generation tools to work properly

CREATE TABLE IF NOT EXISTS note_book (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NULL,
    current_price DOUBLE NULL,
    last_update TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE INDEX idx_notebook_name ON note_book(name);
