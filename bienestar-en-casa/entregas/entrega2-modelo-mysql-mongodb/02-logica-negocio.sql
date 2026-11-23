USE bienestar_en_casa;

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
