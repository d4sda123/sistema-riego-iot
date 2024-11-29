DROP DATABASE IF EXISTS sistema_riego;

CREATE DATABASE sistema_riego;

USE sistema_riego;

CREATE TABLE TIPO_SENSOR (
    tipo_id INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
    descripcion VARCHAR(50) NOT NULL
);

CREATE TABLE SENSOR (
    sensor_id INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
    tipo_id INT NOT NULL,
    ubicacion VARCHAR(100) NOT NULL,
    descripcion VARCHAR(150),
    FOREIGN KEY (tipo_id) REFERENCES TIPO_SENSOR(tipo_id)
);

CREATE TABLE LECTURA (
    lectura_id INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
    sensor_id INT NOT NULL,
    valor FLOAT NOT NULL,
    fecha_hora DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (sensor_id) REFERENCES SENSOR(sensor_id)
);

CREATE TABLE CONFIGURACION (
    configuracion_id INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
    sensor_id INT NOT NULL,
    umbral FLOAT NOT NULL,
    FOREIGN KEY (sensor_id) REFERENCES SENSOR(sensor_id)
);

CREATE TABLE ACCION (
    accion_id INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
    fecha_hora DATETIME DEFAULT CURRENT_TIMESTAMP,
    estado VARCHAR(50) NOT NULL,
    cantidad FLOAT NOT NULL,
    duracion INT NOT NULL,
    observaciones VARCHAR(150)
);

CREATE TABLE LECTURA_ACCION (
    lectura_accion_id INT NOT NULL PRIMARY KEY,
    accion_id INT NOT NULL,
    lectura_id INT NOT NULL,
    orden_lectura INT NOT NULL,
    FOREIGN KEY (accion_id) REFERENCES ACCION(accion_id),
    FOREIGN KEY (lectura_id) REFERENCES LECTURA(lectura_id)
);

CREATE TABLE `mqtt_user` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `username` varchar(100) DEFAULT NULL,
  `password_hash` varchar(100) DEFAULT NULL,
  `salt` varchar(35) DEFAULT NULL,
  `is_superuser` tinyint(1) DEFAULT 0,
  `created` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `mqtt_username` (`username`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `mqtt_acl` (
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

CREATE TABLE `test` (
	`test` varchar(100)
);

DELIMITER //
CREATE PROCEDURE addUser (
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

CALL addUser('node-red', 'node-red', 'node-red', 1);
CALL addUser('mqttx', 'mqttx', 'mqttx', 0);
CALL addUser('client', 'client', 'client', 0);
CALL addUser('admin', 'admin', 'admin', 1);

insert into TIPO_SENSOR (descripcion) 
values 
	("Temperatura aire"), 
	("Humedad aire"), 
    ("Humedad suelo"), 
    ("Nivel agua");

insert into SENSOR (tipo_id, ubicacion, descripcion) 
values 
	(1, "Planta 1", "DHT-11"),
    (2, "Planta 1", "DHT-11"),
    (3, "Planta 1", "FC-28"),
    (4, "Pozo 1", "Boya");