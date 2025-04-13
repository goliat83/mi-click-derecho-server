-- Script de inicialización MySQL
CREATE DATABASE IF NOT EXISTS miclick;
USE miclick;
CREATE TABLE IF NOT EXISTS ejemplo (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100)
);
