
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

