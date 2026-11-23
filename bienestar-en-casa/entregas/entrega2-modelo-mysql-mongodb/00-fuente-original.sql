
DROP DATABASE IF EXISTS bienestar_en_casa;
CREATE DATABASE bienestar_en_casa
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_0900_ai_ci;
USE bienestar_en_casa;

CREATE TABLE usuarios (
  id             INT          NOT NULL AUTO_INCREMENT,
  email          VARCHAR(120) NOT NULL,
  password_hash  VARCHAR(255) NOT NULL,           -- el hash lo genera el backend
  tipo           ENUM('CLIENTE','PROVEEDOR') NOT NULL,
  nombre         VARCHAR(100) NOT NULL,
  telefono       VARCHAR(20)  NULL,
  fecha_registro DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT pk_usuarios PRIMARY KEY (id),
  CONSTRAINT uq_usuarios_email UNIQUE (email)
) ENGINE=InnoDB;

CREATE TABLE clientes (
  usuario_id INT NOT NULL,
  CONSTRAINT pk_clientes PRIMARY KEY (usuario_id),
  CONSTRAINT fk_clientes_usuario FOREIGN KEY (usuario_id)
    REFERENCES usuarios (id) ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE proveedores (
  usuario_id        INT  NOT NULL,
  biografia         TEXT NULL,
  anios_experiencia INT  NULL,
  CONSTRAINT pk_proveedores PRIMARY KEY (usuario_id),
  CONSTRAINT fk_proveedores_usuario FOREIGN KEY (usuario_id)
    REFERENCES usuarios (id) ON DELETE RESTRICT,
  CONSTRAINT ck_proveedores_anios
    CHECK (anios_experiencia IS NULL OR anios_experiencia >= 0)
) ENGINE=InnoDB;

CREATE TABLE direcciones (
  id           INT          NOT NULL AUTO_INCREMENT,
  cliente_id   INT          NOT NULL,
  ciudad       VARCHAR(80)  NOT NULL,
  barrio       VARCHAR(80)  NULL,
  calle        VARCHAR(120) NOT NULL,
  numero       VARCHAR(20)  NULL,
  referencia   TEXT         NULL,
  es_principal TINYINT(1)   NOT NULL DEFAULT 0,
  CONSTRAINT pk_direcciones PRIMARY KEY (id),
  CONSTRAINT fk_direcciones_cliente FOREIGN KEY (cliente_id)
    REFERENCES clientes (usuario_id) ON DELETE CASCADE,
  CONSTRAINT ck_direcciones_principal CHECK (es_principal IN (0,1))
) ENGINE=InnoDB;

CREATE TABLE zonas_cobertura (
  id            INT          NOT NULL AUTO_INCREMENT,
  proveedor_id  INT          NOT NULL,
  ciudad        VARCHAR(80)  NOT NULL,
  barrio_sector VARCHAR(100) NOT NULL DEFAULT '',
  CONSTRAINT pk_zonas PRIMARY KEY (id),
  CONSTRAINT uq_zonas_proveedor_zona UNIQUE (proveedor_id, ciudad, barrio_sector),
  CONSTRAINT fk_zonas_proveedor FOREIGN KEY (proveedor_id)
    REFERENCES proveedores (usuario_id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE servicios (
  id               INT           NOT NULL AUTO_INCREMENT,
  proveedor_id     INT           NOT NULL,
  nombre           VARCHAR(100)  NOT NULL,
  categoria        VARCHAR(80)   NOT NULL,
  descripcion      TEXT          NULL,
  duracion_minutos INT           NOT NULL,
  precio           DECIMAL(10,2) NOT NULL,
  estado           ENUM('ACTIVO','INACTIVO') NOT NULL DEFAULT 'ACTIVO',
  CONSTRAINT pk_servicios PRIMARY KEY (id),
  CONSTRAINT uq_servicios_proveedor_nombre UNIQUE (proveedor_id, nombre),
  CONSTRAINT fk_servicios_proveedor FOREIGN KEY (proveedor_id)
    REFERENCES proveedores (usuario_id) ON DELETE RESTRICT,
  CONSTRAINT ck_servicios_duracion CHECK (duracion_minutos > 0),
  CONSTRAINT ck_servicios_precio   CHECK (precio >= 0),
  INDEX idx_servicios_categoria (categoria),
  INDEX idx_servicios_nombre (nombre)
) ENGINE=InnoDB;

CREATE TABLE servicios_multimedia (
  id          INT          NOT NULL AUTO_INCREMENT,
  servicio_id INT          NOT NULL,
  tipo        ENUM('FOTO','VIDEO') NOT NULL,
  url         VARCHAR(500) NOT NULL,
  orden       TINYINT UNSIGNED NOT NULL DEFAULT 1,
  CONSTRAINT pk_servicios_multimedia PRIMARY KEY (id),
  CONSTRAINT fk_multimedia_servicio FOREIGN KEY (servicio_id)
    REFERENCES servicios (id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE servicios_insumos (
  id          INT          NOT NULL AUTO_INCREMENT,
  servicio_id INT          NOT NULL,
  tipo        ENUM('PRODUCTO','INSUMO','EQUIPO') NOT NULL,
  nombre      VARCHAR(150) NOT NULL,
  descripcion TEXT         NULL,
  CONSTRAINT pk_servicios_insumos PRIMARY KEY (id),
  CONSTRAINT uq_insumos_servicio_nombre UNIQUE (servicio_id, nombre),
  CONSTRAINT fk_insumos_servicio FOREIGN KEY (servicio_id)
    REFERENCES servicios (id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE horarios_disponibilidad (
  id           INT  NOT NULL AUTO_INCREMENT,
  proveedor_id INT  NOT NULL,
  dia_semana   ENUM('LUNES','MARTES','MIERCOLES','JUEVES','VIERNES','SABADO','DOMINGO') NOT NULL,
  hora_inicio  TIME NOT NULL,
  hora_fin     TIME NOT NULL,
  CONSTRAINT pk_horarios PRIMARY KEY (id),
  CONSTRAINT uq_horarios_proveedor UNIQUE (proveedor_id, dia_semana, hora_inicio, hora_fin),
  CONSTRAINT fk_horarios_proveedor FOREIGN KEY (proveedor_id)
    REFERENCES proveedores (usuario_id) ON DELETE CASCADE,
  CONSTRAINT ck_horarios_horas CHECK (hora_inicio < hora_fin)
) ENGINE=InnoDB;

CREATE TABLE periodos_no_disponibilidad (
  id           INT          NOT NULL AUTO_INCREMENT,
  proveedor_id INT          NOT NULL,
  fecha_inicio DATETIME     NOT NULL,
  fecha_fin    DATETIME     NOT NULL,
  motivo       VARCHAR(200) NULL,
  CONSTRAINT pk_periodos PRIMARY KEY (id),
  CONSTRAINT fk_periodos_proveedor FOREIGN KEY (proveedor_id)
    REFERENCES proveedores (usuario_id) ON DELETE CASCADE,
  CONSTRAINT ck_periodos_fechas CHECK (fecha_inicio < fecha_fin)
) ENGINE=InnoDB;

CREATE TABLE recuperacion_contrasena (
  id               INT         NOT NULL AUTO_INCREMENT,
  usuario_id       INT         NOT NULL,
  codigo           VARCHAR(20) NOT NULL,
  fecha_expiracion DATETIME    NOT NULL,
  fecha_uso        DATETIME    NULL,
  fecha_creacion   DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  invalidado       TINYINT(1)  NOT NULL DEFAULT 0,       -- AJUSTE 1
  CONSTRAINT pk_recuperacion PRIMARY KEY (id),
  CONSTRAINT uq_recuperacion_codigo UNIQUE (codigo),
  CONSTRAINT fk_recuperacion_usuario FOREIGN KEY (usuario_id)
    REFERENCES usuarios (id) ON DELETE CASCADE,
  CONSTRAINT ck_recuperacion_vigencia CHECK (fecha_expiracion > fecha_creacion),
  CONSTRAINT ck_recuperacion_invalidado CHECK (invalidado IN (0,1)),
  CONSTRAINT ck_recuperacion_usado CHECK (fecha_uso IS NULL OR invalidado = 1)
) ENGINE=InnoDB;

CREATE TABLE solicitudes (
  id                   INT           NOT NULL AUTO_INCREMENT,
  cliente_id           INT           NOT NULL,
  proveedor_id         INT           NOT NULL,
  servicio_id          INT           NOT NULL,

  servicio_nombre      VARCHAR(100)  NOT NULL DEFAULT '',
  servicio_precio      DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  servicio_duracion    INT           NOT NULL DEFAULT 1,
  direccion_id         INT           NOT NULL,
  barrio_sector        VARCHAR(100)  NULL,
  info_localizacion    TEXT          NULL,
  observaciones        TEXT          NULL,
  fecha_hora_inicio    DATETIME      NOT NULL,          
  fecha_hora_propuesta DATETIME      NULL,              
  estado ENUM('PENDIENTE','SUGERIDA','ACEPTADA','RECHAZADA','CANCELADA','COMPLETADA')
         NOT NULL DEFAULT 'PENDIENTE',
  motivo               TEXT          NULL,
  fecha_creacion       DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  fecha_actualizacion  DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP
                                     ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT pk_solicitudes PRIMARY KEY (id),
  CONSTRAINT fk_solicitudes_cliente FOREIGN KEY (cliente_id)
    REFERENCES clientes (usuario_id) ON DELETE RESTRICT,
  CONSTRAINT fk_solicitudes_proveedor FOREIGN KEY (proveedor_id)
    REFERENCES proveedores (usuario_id) ON DELETE RESTRICT,
  CONSTRAINT fk_solicitudes_servicio FOREIGN KEY (servicio_id)
    REFERENCES servicios (id) ON DELETE RESTRICT,
  CONSTRAINT fk_solicitudes_direccion FOREIGN KEY (direccion_id)
    REFERENCES direcciones (id) ON DELETE RESTRICT,
  CONSTRAINT ck_solicitudes_precio   CHECK (servicio_precio >= 0),
  CONSTRAINT ck_solicitudes_duracion CHECK (servicio_duracion > 0),
  
  CONSTRAINT ck_solicitudes_estado CHECK (
        (estado <> 'SUGERIDA'  OR fecha_hora_propuesta IS NOT NULL)
    AND (estado <> 'PENDIENTE' OR fecha_hora_propuesta IS NULL)
    AND (estado NOT IN ('RECHAZADA','CANCELADA')
         OR (motivo IS NOT NULL AND CHAR_LENGTH(TRIM(motivo)) > 0))
  ),
  INDEX idx_solicitudes_agenda (proveedor_id, estado, fecha_hora_inicio)
) ENGINE=InnoDB;


DELIMITER $$


CREATE TRIGGER trg_t1_clientes_bi
BEFORE INSERT ON clientes
FOR EACH ROW
BEGIN
  DECLARE v_tipo VARCHAR(20);
  SELECT tipo INTO v_tipo FROM usuarios WHERE id = NEW.usuario_id;
  IF v_tipo IS NULL OR v_tipo <> 'CLIENTE' THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'T1: el usuario no es de tipo CLIENTE';
  END IF;
END$$

CREATE TRIGGER trg_t1_proveedores_bi
BEFORE INSERT ON proveedores
FOR EACH ROW
BEGIN
  DECLARE v_tipo VARCHAR(20);
  SELECT tipo INTO v_tipo FROM usuarios WHERE id = NEW.usuario_id;
  IF v_tipo IS NULL OR v_tipo <> 'PROVEEDOR' THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'T1: el usuario no es de tipo PROVEEDOR';
  END IF;
END$$

CREATE TRIGGER trg_t1_usuarios_bu
BEFORE UPDATE ON usuarios
FOR EACH ROW
BEGIN
  IF NEW.tipo <> OLD.tipo THEN
    IF EXISTS (SELECT 1 FROM clientes WHERE usuario_id = OLD.id)
       OR EXISTS (SELECT 1 FROM proveedores WHERE usuario_id = OLD.id) THEN
      SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'T1: no se puede cambiar el tipo de un usuario que ya tiene perfil';
    END IF;
  END IF;
END$$


CREATE TRIGGER trg_t2_solicitudes_bi
BEFORE INSERT ON solicitudes
FOR EACH ROW
BEGIN
  DECLARE v_estado      VARCHAR(20);
  DECLARE v_proveedor   INT;
  DECLARE v_nombre      VARCHAR(100);
  DECLARE v_precio      DECIMAL(10,2);
  DECLARE v_duracion    INT;
  DECLARE v_dir_cliente INT;

  SELECT estado, proveedor_id, nombre, precio, duracion_minutos
    INTO v_estado, v_proveedor, v_nombre, v_precio, v_duracion
    FROM servicios
   WHERE id = NEW.servicio_id;

  IF v_estado IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'T2: el servicio no existe';
  END IF;
  IF v_estado <> 'ACTIVO' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'T2: solo se pueden solicitar servicios ACTIVOS';
  END IF;
  IF v_proveedor <> NEW.proveedor_id THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'T2: el servicio no pertenece al proveedor indicado';
  END IF;
  IF NEW.fecha_hora_inicio <= NOW() THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'T2: la fecha y hora solicitadas deben ser futuras';
  END IF;

  SELECT cliente_id INTO v_dir_cliente FROM direcciones WHERE id = NEW.direccion_id;
  IF v_dir_cliente IS NULL OR v_dir_cliente <> NEW.cliente_id THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'T2: la direccion no pertenece al cliente';
  END IF;


  SET NEW.servicio_nombre      = v_nombre;
  SET NEW.servicio_precio      = v_precio;
  SET NEW.servicio_duracion    = v_duracion;
  SET NEW.estado               = 'PENDIENTE';
  SET NEW.fecha_hora_propuesta = NULL;
  SET NEW.motivo               = NULL;
END$$

CREATE TRIGGER trg_t3_snapshot_bu
BEFORE UPDATE ON solicitudes
FOR EACH ROW
BEGIN
  IF NOT (NEW.servicio_id        <=> OLD.servicio_id)
     OR NOT (NEW.proveedor_id    <=> OLD.proveedor_id)
     OR NOT (NEW.servicio_nombre <=> OLD.servicio_nombre)
     OR NOT (NEW.servicio_precio <=> OLD.servicio_precio)
     OR NOT (NEW.servicio_duracion <=> OLD.servicio_duracion) THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'T3: el servicio y los datos copiados de la solicitud no se pueden modificar';
  END IF;
END$$

CREATE TRIGGER trg_t4_transiciones_bu
BEFORE UPDATE ON solicitudes
FOR EACH ROW
FOLLOWS trg_t3_snapshot_bu
BEGIN
  IF NEW.estado <> OLD.estado THEN
    IF NOT (
         (OLD.estado = 'PENDIENTE' AND NEW.estado IN ('ACEPTADA','RECHAZADA','SUGERIDA'))
      OR (OLD.estado = 'SUGERIDA'  AND NEW.estado IN ('ACEPTADA','CANCELADA'))
      OR (OLD.estado = 'ACEPTADA'  AND NEW.estado IN ('COMPLETADA','CANCELADA'))
    ) THEN
      SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'T4: transicion de estado no permitida';
    END IF;
  END IF;
END$$

CREATE TRIGGER trg_t5_aceptacion_bu
BEFORE UPDATE ON solicitudes
FOR EACH ROW
FOLLOWS trg_t4_transiciones_bu
BEGIN
  DECLARE v_inicio DATETIME;
  DECLARE v_fin    DATETIME;
  DECLARE v_dia    VARCHAR(10);

  IF NEW.estado = 'ACEPTADA' AND OLD.estado <> 'ACEPTADA' THEN

    SET v_inicio = COALESCE(NEW.fecha_hora_propuesta, NEW.fecha_hora_inicio);
    SET v_fin    = DATE_ADD(v_inicio, INTERVAL NEW.servicio_duracion MINUTE);
    SET v_dia    = ELT(WEEKDAY(v_inicio) + 1,
                       'LUNES','MARTES','MIERCOLES','JUEVES','VIERNES','SABADO','DOMINGO');


    IF DATE(v_fin) <> DATE(v_inicio)
       OR NOT EXISTS (
            SELECT 1
              FROM horarios_disponibilidad h
             WHERE h.proveedor_id = NEW.proveedor_id
               AND h.dia_semana   = v_dia
               AND h.hora_inicio <= TIME(v_inicio)
               AND h.hora_fin    >= TIME(v_fin)) THEN
      SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'T5: el proveedor no tiene horario general que cubra ese periodo';
    END IF;

    IF EXISTS (
         SELECT 1
           FROM periodos_no_disponibilidad p
          WHERE p.proveedor_id = NEW.proveedor_id
            AND p.fecha_inicio < v_fin
            AND p.fecha_fin    > v_inicio) THEN
      SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'T5: el periodo coincide con una no disponibilidad del proveedor';
    END IF;

    IF EXISTS (
         SELECT 1
           FROM solicitudes s
          WHERE s.proveedor_id = NEW.proveedor_id
            AND s.estado = 'ACEPTADA'
            AND s.id <> NEW.id
            AND COALESCE(s.fecha_hora_propuesta, s.fecha_hora_inicio) < v_fin
            AND DATE_ADD(COALESCE(s.fecha_hora_propuesta, s.fecha_hora_inicio),
                         INTERVAL s.servicio_duracion MINUTE) > v_inicio) THEN
      SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'T5: el proveedor ya tiene una reserva aceptada que se cruza con ese periodo';
    END IF;
  END IF;
END$$

CREATE TRIGGER trg_t6_token_bu
BEFORE UPDATE ON recuperacion_contrasena
FOR EACH ROW
BEGIN

  IF OLD.fecha_uso IS NOT NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'T6: el token ya fue usado';
  END IF;

  IF NOT (NEW.fecha_uso <=> OLD.fecha_uso) THEN
    IF OLD.invalidado = 1 THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'T6: el token fue invalidado';
    ELSEIF OLD.fecha_expiracion < NOW() THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'T6: el token ya expiro';
    END IF;
  END IF;

  IF OLD.invalidado = 1 AND NEW.invalidado = 0 THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'T6: un token invalidado no se puede reactivar';
  END IF;
END$$

CREATE PROCEDURE sp_generar_recuperacion(
  IN p_usuario_id      INT,
  IN p_codigo          VARCHAR(20),
  IN p_minutos_vigencia INT
)
BEGIN
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  START TRANSACTION;
    UPDATE recuperacion_contrasena
       SET invalidado = 1
     WHERE usuario_id = p_usuario_id
       AND invalidado = 0;

    INSERT INTO recuperacion_contrasena (usuario_id, codigo, fecha_expiracion)
    VALUES (p_usuario_id, p_codigo, DATE_ADD(NOW(), INTERVAL p_minutos_vigencia MINUTE));
  COMMIT;
END$$


CREATE PROCEDURE sp_usar_recuperacion(IN p_codigo VARCHAR(20))
BEGIN
  DECLARE v_id INT;

  SELECT id INTO v_id FROM recuperacion_contrasena WHERE codigo = p_codigo;
  IF v_id IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El codigo de recuperacion no existe';
  END IF;

  UPDATE recuperacion_contrasena
     SET fecha_uso = NOW(), invalidado = 1
   WHERE id = v_id;
END$$

DELIMITER ;

USE bienestar_en_casa;

SET @lunes     = DATE_ADD(CURDATE(), INTERVAL (7 - WEEKDAY(CURDATE())) DAY);
SET @martes    = DATE_ADD(@lunes, INTERVAL 1 DAY);
SET @miercoles = DATE_ADD(@lunes, INTERVAL 2 DAY);
SET @jueves    = DATE_ADD(@lunes, INTERVAL 3 DAY);
SET @sabado    = DATE_ADD(@lunes, INTERVAL 5 DAY);

INSERT INTO usuarios (id, email, password_hash, tipo, nombre, telefono) VALUES
  (1, 'camila.torres@example.com', SHA2('Clave123*', 256), 'PROVEEDOR', 'Camila Torres',  '3001112233'),
  (2, 'andres.mejia@example.com',  SHA2('Clave123*', 256), 'PROVEEDOR', 'Andrés Mejía',   '3002223344'),
  (3, 'laura.gomez@example.com',   SHA2('Clave123*', 256), 'CLIENTE',   'Laura Gómez',    '3003334455'),
  (4, 'carlos.perez@example.com',  SHA2('Clave123*', 256), 'CLIENTE',   'Carlos Pérez',   '3004445566'),
  (5, 'sofia.ramirez@example.com', SHA2('Clave123*', 256), 'CLIENTE',   'Sofía Ramírez',  NULL),
  (6, 'valentina.rios@example.com',SHA2('Clave123*', 256), 'PROVEEDOR', 'Valentina Ríos', '3006667788');

INSERT INTO proveedores (usuario_id, biografia, anios_experiencia) VALUES
  (1, 'Terapeuta de masajes con enfoque relajante y deportivo.', 5),
  (2, 'Esteticista y maquilladora profesional a domicilio.',     3),
  (6, 'Proveedora nueva, aún sin servicios ni reservas.',        1);

INSERT INTO clientes (usuario_id) VALUES (3), (4), (5);

INSERT INTO direcciones (id, cliente_id, ciudad, barrio, calle, numero, referencia, es_principal) VALUES
  (1, 3, 'Cali',    'Granada',       'Calle 10',    '12-34', 'Edificio Los Almendros, apto 502', 1),
  (2, 3, 'Cali',    'Ciudad Jardín', 'Carrera 100', '15-20', 'Casa esquinera, portón negro',     0),
  (3, 4, 'Cali',    'San Fernando',  'Avenida 5',   '8-10',  NULL,                               1),
  (4, 5, 'Jamundí', 'Alfaguara',     'Calle 3',     '2-15',  'Conjunto Pinos, torre 2',          1);

INSERT INTO zonas_cobertura (proveedor_id, ciudad, barrio_sector) VALUES
  (1, 'Cali',    'Granada'),
  (1, 'Cali',    'San Fernando'),
  (2, 'Cali',    'Ciudad Jardín'),
  (2, 'Jamundí', '');          

INSERT INTO servicios (id, proveedor_id, nombre, categoria, descripcion, duracion_minutos, precio, estado) VALUES
  (1, 1, 'Masaje relajante 60 min',     'Masajes',         'Masaje corporal suave para aliviar el estrés.',          60,  90000.00, 'ACTIVO'),
  (2, 1, 'Limpieza facial',             'Estética facial', 'Limpieza profunda con mascarilla y tonificación.',       45,  70000.00, 'ACTIVO'),
  (3, 1, 'Masaje descontracturante',    'Masajes',         'Trabajo profundo en espalda y cuello.',                  90, 120000.00, 'INACTIVO'),
  (4, 2, 'Manicure y pedicure',         'Uñas',            'Manicure y pedicure con esmalte semipermanente.',        90,  80000.00, 'ACTIVO'),
  (5, 2, 'Maquillaje social',           'Maquillaje',      'Maquillaje para eventos, incluye peinado básico.',       60, 100000.00, 'ACTIVO');

INSERT INTO servicios_multimedia (servicio_id, tipo, url, orden) VALUES
  (1, 'FOTO',  'https://ejemplo.com/media/masaje-relajante-1.jpg', 1),
  (1, 'VIDEO', 'https://ejemplo.com/media/masaje-relajante.mp4',   2),
  (2, 'FOTO',  'https://ejemplo.com/media/limpieza-facial.jpg',    1),
  (4, 'FOTO',  'https://ejemplo.com/media/manicure.jpg',           1);

INSERT INTO servicios_insumos (servicio_id, tipo, nombre, descripcion) VALUES
  (1, 'PRODUCTO', 'Aceite de almendras',   'Aceite hipoalergénico para masaje.'),
  (1, 'EQUIPO',   'Camilla portátil',      'Camilla plegable con soporte facial.'),
  (2, 'INSUMO',   'Mascarilla de arcilla', NULL),
  (4, 'PRODUCTO', 'Esmalte semipermanente', NULL),
  (4, 'EQUIPO',   'Lámpara UV/LED',        'Para curado del esmalte.'),
  (5, 'PRODUCTO', 'Base de maquillaje',    NULL);

INSERT INTO horarios_disponibilidad (proveedor_id, dia_semana, hora_inicio, hora_fin) VALUES
  (1, 'LUNES',     '08:00:00', '17:00:00'),
  (1, 'MARTES',    '08:00:00', '17:00:00'),
  (1, 'MIERCOLES', '08:00:00', '17:00:00'),
  (1, 'JUEVES',    '08:00:00', '17:00:00'),
  (1, 'VIERNES',   '08:00:00', '17:00:00'),
  (2, 'MARTES',    '09:00:00', '15:00:00'),
  (2, 'JUEVES',    '09:00:00', '15:00:00'),
  (2, 'SABADO',    '09:00:00', '15:00:00');

INSERT INTO periodos_no_disponibilidad (proveedor_id, fecha_inicio, fecha_fin, motivo) VALUES
  (1, TIMESTAMP(@miercoles, '00:00:00'), TIMESTAMP(@miercoles, '23:59:59'), 'Cita personal');

INSERT INTO solicitudes
  (id, cliente_id, proveedor_id, servicio_id, direccion_id, barrio_sector, observaciones, fecha_hora_inicio)
VALUES
  (1, 3, 1, 1, 1, 'Granada',       'Timbre dañado, llamar al llegar.', TIMESTAMP(@lunes,     '10:00:00')),
  (2, 4, 1, 2, 3, 'San Fernando',  NULL,                               TIMESTAMP(@lunes,     '10:30:00')),
  (3, 5, 1, 1, 4, 'Alfaguara',     NULL,                               TIMESTAMP(@lunes,     '11:00:00')),
  (4, 3, 1, 1, 2, 'Ciudad Jardín', NULL,                               TIMESTAMP(@miercoles, '10:00:00')),
  (5, 4, 2, 4, 3, 'San Fernando',  NULL,                               TIMESTAMP(@lunes,     '10:00:00')),
  (6, 3, 2, 4, 1, 'Granada',       NULL,                               TIMESTAMP(@martes,    '10:00:00')),
  (7, 5, 2, 5, 4, 'Alfaguara',     'Maquillaje para matrimonio.',      TIMESTAMP(@sabado,    '09:00:00')),
  (8, 4, 1, 2, 3, 'San Fernando',  NULL,                               TIMESTAMP(@martes,    '14:00:00'));

UPDATE solicitudes SET estado = 'ACEPTADA' WHERE id = 1;
UPDATE solicitudes SET estado = 'ACEPTADA' WHERE id = 3;

UPDATE solicitudes
   SET estado = 'SUGERIDA', fecha_hora_propuesta = TIMESTAMP(@jueves, '10:00:00')
 WHERE id = 6;
UPDATE solicitudes SET estado = 'ACEPTADA' WHERE id = 6;


UPDATE solicitudes
   SET estado = 'RECHAZADA', motivo = 'Fuera de mi zona de atención.'
 WHERE id = 7;

UPDATE solicitudes SET estado = 'ACEPTADA' WHERE id = 8;
UPDATE solicitudes
   SET estado = 'CANCELADA', motivo = 'El cliente tuvo un imprevisto.'
 WHERE id = 8;

CALL sp_generar_recuperacion(3, 'AB12CD', 30);
CALL sp_generar_recuperacion(3, 'ZX98YW', 30);
CALL sp_generar_recuperacion(4, 'KLM456', 30);


SELECT id, cliente_id, proveedor_id, servicio_nombre, servicio_precio, servicio_duracion,
       estado, fecha_hora_inicio, fecha_hora_propuesta, motivo
  FROM solicitudes
 ORDER BY id;

USE bienestar_en_casa;

SET @lunes     = DATE_ADD(CURDATE(), INTERVAL (7 - WEEKDAY(CURDATE())) DAY);
SET @miercoles = DATE_ADD(@lunes, INTERVAL 2 DAY);


INSERT INTO servicios (proveedor_id, nombre, categoria, duracion_minutos, precio)
VALUES (2, 'Servicio temporal', 'Prueba', 30, 10000);
SET @sid = LAST_INSERT_ID();
INSERT INTO servicios_multimedia (servicio_id, tipo, url)
VALUES (@sid, 'FOTO', 'https://ejemplo.com/media/temporal.jpg');
SELECT COUNT(*) AS multimedia_antes FROM servicios_multimedia WHERE servicio_id = @sid;   -- 1
DELETE FROM servicios WHERE id = @sid;
SELECT COUNT(*) AS multimedia_despues FROM servicios_multimedia WHERE servicio_id = @sid; -- 0


SELECT id, estado, fecha_creacion, fecha_actualizacion FROM solicitudes WHERE id = 2;
UPDATE solicitudes SET observaciones = 'Prefiere llegada puntual.' WHERE id = 2;
SELECT id, estado, fecha_creacion, fecha_actualizacion FROM solicitudes WHERE id = 2;


INSERT INTO solicitudes
  (cliente_id, proveedor_id, servicio_id, direccion_id,
   servicio_nombre, servicio_precio, servicio_duracion, estado, fecha_hora_inicio)
VALUES
  (5, 1, 2, 4, 'DATO FALSO', 1.00, 1, 'ACEPTADA',
   TIMESTAMP(DATE_ADD(@lunes, INTERVAL 7 DAY), '10:00:00'));
SELECT id, servicio_nombre, servicio_precio, servicio_duracion, estado   
  FROM solicitudes WHERE id = LAST_INSERT_ID();

UPDATE servicios SET precio = 150000 WHERE id = 1;
SELECT s.id, s.servicio_precio AS precio_en_la_solicitud, sv.precio AS precio_actual_del_catalogo
  FROM solicitudes s JOIN servicios sv ON sv.id = s.servicio_id
 WHERE s.id IN (1, 3);
UPDATE servicios SET precio = 90000 WHERE id = 1;    -- se deja como estaba

SELECT id, COALESCE(fecha_hora_propuesta, fecha_hora_inicio) AS inicio,
       DATE_ADD(COALESCE(fecha_hora_propuesta, fecha_hora_inicio), INTERVAL servicio_duracion MINUTE) AS fin,
       estado
  FROM solicitudes
 WHERE proveedor_id = 1 AND estado = 'ACEPTADA'
 ORDER BY inicio;

UPDATE solicitudes SET estado = 'COMPLETADA' WHERE id = 3;

CALL sp_usar_recuperacion('ZX98YW');
SELECT codigo, fecha_uso, invalidado FROM recuperacion_contrasena WHERE usuario_id = 3;

INSERT INTO recuperacion_contrasena (usuario_id, codigo, fecha_creacion, fecha_expiracion)
VALUES (4, 'OLD999', NOW() - INTERVAL 2 HOUR, NOW() - INTERVAL 1 HOUR);

CALL sp_generar_recuperacion(4, 'NEW111', 30);
SELECT codigo, invalidado, fecha_expiracion FROM recuperacion_contrasena WHERE usuario_id = 4;

SELECT sv.id, sv.nombre, sv.categoria, sv.descripcion, sv.duracion_minutos, sv.precio,
       u.nombre AS proveedor
  FROM servicios sv
  JOIN proveedores p ON p.usuario_id = sv.proveedor_id
  JOIN usuarios u    ON u.id = p.usuario_id
 WHERE sv.estado = 'ACTIVO'
   AND (sv.nombre LIKE '%masaje%' OR sv.categoria LIKE '%masaje%');

SELECT sv.id, sv.nombre, sv.precio, sv.duracion_minutos,
       (SELECT GROUP_CONCAT(CONCAT(m.tipo, ': ', m.url) ORDER BY m.orden SEPARATOR ' | ')
          FROM servicios_multimedia m WHERE m.servicio_id = sv.id) AS multimedia,
       (SELECT GROUP_CONCAT(i.nombre ORDER BY i.nombre SEPARATOR ', ')
          FROM servicios_insumos i WHERE i.servicio_id = sv.id) AS insumos_y_equipos,
       (SELECT GROUP_CONCAT(CONCAT(z.ciudad, IF(z.barrio_sector = '', '', CONCAT(' - ', z.barrio_sector)))
                            SEPARATOR ', ')
          FROM zonas_cobertura z WHERE z.proveedor_id = sv.proveedor_id) AS zonas_de_atencion
  FROM servicios sv
 WHERE sv.estado = 'ACTIVO';

SELECT up.nombre AS proveedor, s.id AS solicitud, s.estado, uc.nombre AS cliente,
       s.servicio_nombre, s.servicio_precio,
       CONCAT_WS(', ', CONCAT_WS(' # ', d.calle, d.numero), d.barrio, d.ciudad) AS direccion,
       s.fecha_hora_inicio, s.fecha_hora_propuesta, s.motivo
  FROM solicitudes s
  JOIN usuarios up   ON up.id = s.proveedor_id
  JOIN usuarios uc   ON uc.id = s.cliente_id
  JOIN direcciones d ON d.id = s.direccion_id
 ORDER BY up.nombre, s.estado, s.fecha_hora_inicio;

SELECT u.nombre AS proveedor,
       COUNT(*)                                   AS total_solicitudes,
       SUM(s.estado = 'PENDIENTE')                AS pendientes,
       SUM(s.estado = 'ACEPTADA')                 AS aceptadas,
       SUM(s.estado = 'COMPLETADA')               AS completadas,
       SUM(s.estado IN ('RECHAZADA','CANCELADA')) AS rechazadas_o_canceladas,
       SUM(CASE WHEN s.estado IN ('ACEPTADA','COMPLETADA') THEN s.servicio_precio ELSE 0 END) AS valor_reservado
  FROM solicitudes s
  JOIN usuarios u ON u.id = s.proveedor_id
 GROUP BY s.proveedor_id, u.nombre;

SELECT u.id, u.nombre
  FROM proveedores p
  JOIN usuarios u ON u.id = p.usuario_id
  LEFT JOIN solicitudes s ON s.proveedor_id = p.usuario_id AND s.estado = 'ACEPTADA'
 WHERE s.id IS NULL;

SELECT s.id, uc.nombre AS cliente, s.servicio_nombre,
       COALESCE(s.fecha_hora_propuesta, s.fecha_hora_inicio) AS inicio,
       DATE_ADD(COALESCE(s.fecha_hora_propuesta, s.fecha_hora_inicio),
                INTERVAL s.servicio_duracion MINUTE) AS fin,
       CONCAT_WS(', ', CONCAT_WS(' # ', d.calle, d.numero), d.barrio, d.ciudad) AS direccion
  FROM solicitudes s
  JOIN usuarios uc   ON uc.id = s.cliente_id
  JOIN direcciones d ON d.id = s.direccion_id
 WHERE s.proveedor_id = 1
   AND s.estado = 'ACEPTADA'
 ORDER BY inicio;

SELECT u.nombre AS proveedor, h.dia_semana, h.hora_inicio, h.hora_fin
  FROM horarios_disponibilidad h
  JOIN usuarios u ON u.id = h.proveedor_id
 ORDER BY u.nombre, FIELD(h.dia_semana,'LUNES','MARTES','MIERCOLES','JUEVES','VIERNES','SABADO','DOMINGO');

SELECT u.nombre AS proveedor, p.fecha_inicio, p.fecha_fin, p.motivo
  FROM periodos_no_disponibilidad p
  JOIN usuarios u ON u.id = p.proveedor_id;
