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
