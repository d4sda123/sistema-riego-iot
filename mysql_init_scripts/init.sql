DROP DATABASE IF EXISTS sistema_riego;

CREATE DATABASE sistema_riego;

-- Usuarios MySQL: EMQX, node-red, Flask, Rocketbot
CREATE USER 'emqx'@'localhost' IDENTIFIED BY '7FF161E4392ED9C72FB0A16957D80E57';
GRANT ALL PRIVILEGES ON sistema_riego.* TO 'emqx'@'localhost';
CREATE USER 'node-red'@'localhost' IDENTIFIED BY 'DE31DBF294ACA5D7BB0EA9624641CDF7';
GRANT ALL PRIVILEGES ON sistema_riego.* TO 'node-red'@'localhost';
CREATE USER 'flask'@'localhost' IDENTIFIED BY '20A1598BD2ADB0D3DEE274D2FB6FA0AC';
GRANT ALL PRIVILEGES ON sistema_riego.* TO 'flask'@'localhost';
CREATE USER 'rocketbot'@'localhost' IDENTIFIED BY 'F118A754D2C67CB39045106B73DA5066';
GRANT ALL PRIVILEGES ON sistema_riego.* TO 'rocketbot'@'localhost';

FLUSH PRIVILEGES;

USE sistema_riego;

CREATE TABLE tipo_sensor (
    tipo_id INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
    descripcion VARCHAR(50) NOT NULL
);

CREATE TABLE sensor (
    sensor_id INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
    tipo_id INT NOT NULL,
    ubicacion VARCHAR(100) NOT NULL,
    descripcion VARCHAR(150),
    FOREIGN KEY (tipo_id) REFERENCES tipo_sensor(tipo_id)
);

CREATE TABLE lectura (
    lectura_id INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
    sensor_id INT NOT NULL,
    valor FLOAT NOT NULL,
    fecha_hora DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (sensor_id) REFERENCES sensor(sensor_id)
);

CREATE TABLE configuracion (
    configuracion_id INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
    sensor_id INT NOT NULL,
    umbral FLOAT NOT NULL,
    FOREIGN KEY (sensor_id) REFERENCES sensor(sensor_id)
);

CREATE TABLE accion (
    accion_id INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
    fecha_hora DATETIME DEFAULT CURRENT_TIMESTAMP,
    estado VARCHAR(50) NOT NULL,
    cantidad FLOAT NOT NULL,
    duracion INT NOT NULL,
    observaciones VARCHAR(150)
);

CREATE TABLE lectura_accion (
    lectura_accion_id INT NOT NULL PRIMARY KEY,
    accion_id INT NOT NULL,
    lectura_id INT NOT NULL,
    orden_lectura INT NOT NULL,
    FOREIGN KEY (accion_id) REFERENCES accion(accion_id),
    FOREIGN KEY (lectura_id) REFERENCES lectura(lectura_id)
);

CREATE TABLE mqtt_user (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `username` varchar(100) DEFAULT NULL,
  `password_hash` varchar(100) DEFAULT NULL,
  `salt` varchar(35) DEFAULT NULL,
  `is_superuser` tinyint(1) DEFAULT 0,
  `created` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `mqtt_username` (`username`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE mqtt_acl (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `ipaddress` VARCHAR(60) NOT NULL DEFAULT '',
  `username` VARCHAR(255) NOT NULL DEFAULT '',
  `clientid` VARCHAR(255) NOT NULL DEFAULT '',
  `action` ENUM('publish', 'subscribe', 'all') NOT NULL,
  `permission` ENUM('allow', 'deny') NOT NULL,
  `topic` VARCHAR(255) NOT NULL DEFAULT '',
  `qos` tinyint(1),
  `retain` tinyint(1),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE roles (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) UNIQUE NOT NULL,
    description TEXT
);

CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(100) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    salt VARCHAR(255) NOT NULL,
    is_superuser TINYINT(1) DEFAULT 0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    role_id INT DEFAULT NULL,
    FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE SET NULL    
);

CREATE TABLE sessions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    session_token VARCHAR(255) UNIQUE NOT NULL,
    expiration DATETIME NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE permissions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) UNIQUE NOT NULL,
    description TEXT
);

CREATE TABLE role_permissions (
    role_id INT NOT NULL,
    permission_id INT NOT NULL,
    FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE CASCADE,
    FOREIGN KEY (permission_id) REFERENCES permissions(id) ON DELETE CASCADE,
    PRIMARY KEY (role_id, permission_id)
);

CREATE TABLE access_logs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    accion VARCHAR(255) NOT NULL,
    ip_address VARCHAR(45),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE tokens (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    token VARCHAR(500) NOT NULL,
    type ENUM('access', 'refresh') NOT NULL,
    is_revoked TINYINT(1) DEFAULT 0,
    issued_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    expires_at DATETIME NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

ALTER TABLE accion ADD COLUMN user_id INT DEFAULT NULL;
ALTER TABLE accion ADD FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL;

DELIMITER //
CREATE PROCEDURE addMQTTUser (
    IN p_username VARCHAR(100),
    IN p_password VARCHAR(100),
    IN p_salt VARCHAR(35),
    IN p_is_superuser TINYINT(1)
)
BEGIN
	INSERT INTO mqtt_user (username, password_hash, salt, is_superuser)
	VALUES (p_username, SHA2(concat(p_password, p_salt), 256), p_salt, p_is_superuser);
END //
DELIMITER ;

CALL addMQTTUser('node-red', '5ABB1EBA2FA62F10087A2F77C45AB0ED', 'node-red', 1);
CALL addMQTTUser('mqttx', '527EEB79ED951D1217E4079F96F89A5F', 'mqttx', 0);
CALL addMQTTUser('client', '0EE7DEBB64E5BB337F445687D3D52E35', 'client', 0);
CALL addMQTTUser('admin', 'D70FE56CE61180758754F9DDC3AE9A0B', 'admin', 1);
CALL addMQTTUser('esp32', '370E9BB70E8424A3636BCF94DE186BF0', 'esp32', 0)
CALL addMQTTUser('user', 'F472645D80F0E615B0173F3AA818BBCE', 'user', '')

insert into tipo_sensor (descripcion) 
values 
	("Temperatura aire"), 
	("Humedad aire"), 
    ("Humedad suelo"), 
    ("Nivel agua");

insert into sensor (tipo_id, ubicacion, descripcion) 
values 
	(1, "Planta 1", "DHT-11"),
    (2, "Planta 1", "DHT-11"),
    (3, "Planta 1", "FC-28"),
    (4, "Pozo 1", "Boya");