DROP DATABASE IF EXISTS sistema_riego;

CREATE DATABASE sistema_riego;

-- Usuarios MySQL: EMQX, node-red, Flask, Rocketbot
CREATE USER 'node-red'@'localhost' IDENTIFIED BY '2-}OT05MN$4+#aJxr{M`';
GRANT ALL PRIVILEGES ON sistema_riego.* TO 'node-red'@'localhost' IDENTIFIED BY '2-}OT05MN$4+#aJxr{M`';
CREATE USER 'emqx'@'localhost' IDENTIFIED BY 'i%}&rt1c/B>P|6RmLVnr';
GRANT ALL PRIVILEGES ON sistema_riego.* TO 'emqx'@'localhost' IDENTIFIED BY 'i%}&rt1c/B>P|6RmLVnr';
CREATE USER 'flask'@'localhost' IDENTIFIED BY 'R zbjeL;X!I}PHL-oH:G';
GRANT ALL PRIVILEGES ON sistema_riego.* TO 'flask'@'localhost' IDENTIFIED BY 'R zbjeL;X!I}PHL-oH:G';
CREATE USER 'rocketbot'@'localhost' IDENTIFIED BY 'HH+:Hu=wz]izP"?-sjf4';
GRANT ALL PRIVILEGES ON sistema_riego.* TO 'rocketbot'@'localhost' IDENTIFIED BY 'HH+:Hu=wz]izP"?-sjf4';

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

CREATE TABLE roles (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) UNIQUE NOT NULL,
    description TEXT
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

CALL addMQTTUser('node-red', 'l{/(%K:+*>d^sRNYW<&z', 'node-red', 1);
CALL addMQTTUser('mqttx', 'Hin>,#p(Fi1% =1epRMA', 'mqttx', 0);
CALL addMQTTUser('client', '3HVL_5>pg?;s38/^}#vG', 'client', 0);
CALL addMQTTUser('admin', '2MUfxVTL2i~xoh:+R7UG', 'admin', 1);
CALL addMQTTUser('esp32', 'N8/VW9\U..{95$9ZQ#nG', 'esp32', 0)
CALL addMQTTUser('user', '#QpMPf]l`WkC||}(-1n}', 'user', '')

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