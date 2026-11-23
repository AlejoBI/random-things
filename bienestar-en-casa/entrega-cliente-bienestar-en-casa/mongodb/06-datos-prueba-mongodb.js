/*
 * Bienestar en Casa - datos de prueba para MongoDB
 * Equivalente documental de sql/03-datos-prueba.sql.
 * Ejecutar DESPUÉS de 05-modelo-mongodb.js.
 *
 * Utiliza replaceOne + upsert para poder ejecutarse nuevamente sin duplicar
 * estos documentos. No elimina documentos ajenos a esta carga de prueba.
 */

use('bienestar_en_casa');

const requiredCollections = [
  'usuarios', 'direcciones', 'zonas_cobertura', 'servicios',
  'horarios_disponibilidad', 'periodos_no_disponibilidad',
  'recuperacion_contrasena', 'solicitudes'
];
const missing = requiredCollections.filter(
  (name) => !db.getCollectionNames().includes(name)
);
if (missing.length > 0) {
  throw new Error(`Faltan colecciones: ${missing.join(', ')}. Ejecuta primero 05-modelo-mongodb.js.`);
}

const upsertMany = (collectionName, documents) => {
  db.getCollection(collectionName).bulkWrite(documents.map((document) => ({
    replaceOne: { filter: { id: document.id }, replacement: document, upsert: true }
  })));
};

// Es el mismo hash de demostración generado por SHA2('Clave123*', 256) en SQL.
const demoPasswordHash = '60a19b4cbeaa530bc1ed49ab40c58d90015ce59571403589bf71bca960c939cc';

upsertMany('usuarios', [
  { id: 1, email: 'camila.torres@example.com', password_hash: demoPasswordHash, tipo: 'PROVEEDOR', nombre: 'Camila Torres', telefono: '3001112233', fecha_registro: new Date(), proveedor: { biografia: 'Terapeuta de masajes con enfoque relajante y deportivo.', anios_experiencia: 5 } },
  { id: 2, email: 'andres.mejia@example.com', password_hash: demoPasswordHash, tipo: 'PROVEEDOR', nombre: 'Andrés Mejía', telefono: '3002223344', fecha_registro: new Date(), proveedor: { biografia: 'Esteticista y maquilladora profesional a domicilio.', anios_experiencia: 3 } },
  { id: 3, email: 'laura.gomez@example.com', password_hash: demoPasswordHash, tipo: 'CLIENTE', nombre: 'Laura Gómez', telefono: '3003334455', fecha_registro: new Date(), cliente: {} },
  { id: 4, email: 'carlos.perez@example.com', password_hash: demoPasswordHash, tipo: 'CLIENTE', nombre: 'Carlos Pérez', telefono: '3004445566', fecha_registro: new Date(), cliente: {} },
  { id: 5, email: 'sofia.ramirez@example.com', password_hash: demoPasswordHash, tipo: 'CLIENTE', nombre: 'Sofía Ramírez', telefono: null, fecha_registro: new Date(), cliente: {} },
  { id: 6, email: 'valentina.rios@example.com', password_hash: demoPasswordHash, tipo: 'PROVEEDOR', nombre: 'Valentina Ríos', telefono: '3006667788', fecha_registro: new Date(), proveedor: { biografia: 'Proveedora nueva, aún sin servicios ni reservas.', anios_experiencia: 1 } }
]);

upsertMany('direcciones', [
  { id: 1, cliente_id: 3, ciudad: 'Cali', barrio: 'Granada', calle: 'Calle 10', numero: '12-34', referencia: 'Edificio Los Almendros, apto 502', es_principal: true },
  { id: 2, cliente_id: 3, ciudad: 'Cali', barrio: 'Ciudad Jardín', calle: 'Carrera 100', numero: '15-20', referencia: 'Casa esquinera, portón negro', es_principal: false },
  { id: 3, cliente_id: 4, ciudad: 'Cali', barrio: 'San Fernando', calle: 'Avenida 5', numero: '8-10', referencia: null, es_principal: true },
  { id: 4, cliente_id: 5, ciudad: 'Jamundí', barrio: 'Alfaguara', calle: 'Calle 3', numero: '2-15', referencia: 'Conjunto Pinos, torre 2', es_principal: true }
]);

upsertMany('zonas_cobertura', [
  { id: 1, proveedor_id: 1, ciudad: 'Cali', barrio_sector: 'Granada' },
  { id: 2, proveedor_id: 1, ciudad: 'Cali', barrio_sector: 'San Fernando' },
  { id: 3, proveedor_id: 2, ciudad: 'Cali', barrio_sector: 'Ciudad Jardín' },
  { id: 4, proveedor_id: 2, ciudad: 'Jamundí', barrio_sector: '' }
]);

upsertMany('servicios', [
  { id: 1, proveedor_id: 1, nombre: 'Masaje relajante 60 min', categoria: 'Masajes', descripcion: 'Masaje corporal suave para aliviar el estrés.', duracion_minutos: 60, precio: 90000, estado: 'ACTIVO', multimedia: [
    { id: 1, tipo: 'FOTO', url: 'https://ejemplo.com/media/masaje-relajante-1.jpg', orden: 1 },
    { id: 2, tipo: 'VIDEO', url: 'https://ejemplo.com/media/masaje-relajante.mp4', orden: 2 }
  ], insumos: [
    { id: 1, tipo: 'PRODUCTO', nombre: 'Aceite de almendras', descripcion: 'Aceite hipoalergénico para masaje.' },
    { id: 2, tipo: 'EQUIPO', nombre: 'Camilla portátil', descripcion: 'Camilla plegable con soporte facial.' }
  ] },
  { id: 2, proveedor_id: 1, nombre: 'Limpieza facial', categoria: 'Estética facial', descripcion: 'Limpieza profunda con mascarilla y tonificación.', duracion_minutos: 45, precio: 70000, estado: 'ACTIVO', multimedia: [
    { id: 3, tipo: 'FOTO', url: 'https://ejemplo.com/media/limpieza-facial.jpg', orden: 1 }
  ], insumos: [{ id: 3, tipo: 'INSUMO', nombre: 'Mascarilla de arcilla', descripcion: null }] },
  { id: 3, proveedor_id: 1, nombre: 'Masaje descontracturante', categoria: 'Masajes', descripcion: 'Trabajo profundo en espalda y cuello.', duracion_minutos: 90, precio: 120000, estado: 'INACTIVO', multimedia: [], insumos: [] },
  { id: 4, proveedor_id: 2, nombre: 'Manicure y pedicure', categoria: 'Uñas', descripcion: 'Manicure y pedicure con esmalte semipermanente.', duracion_minutos: 90, precio: 80000, estado: 'ACTIVO', multimedia: [
    { id: 4, tipo: 'FOTO', url: 'https://ejemplo.com/media/manicure.jpg', orden: 1 }
  ], insumos: [
    { id: 4, tipo: 'PRODUCTO', nombre: 'Esmalte semipermanente', descripcion: null },
    { id: 5, tipo: 'EQUIPO', nombre: 'Lámpara UV/LED', descripcion: 'Para curado del esmalte.' }
  ] },
  { id: 5, proveedor_id: 2, nombre: 'Maquillaje social', categoria: 'Maquillaje', descripcion: 'Maquillaje para eventos, incluye peinado básico.', duracion_minutos: 60, precio: 100000, estado: 'ACTIVO', multimedia: [], insumos: [{ id: 6, tipo: 'PRODUCTO', nombre: 'Base de maquillaje', descripcion: null }] }
]);

upsertMany('horarios_disponibilidad', [
  { id: 1, proveedor_id: 1, dia_semana: 'LUNES', hora_inicio: '08:00:00', hora_fin: '17:00:00' },
  { id: 2, proveedor_id: 1, dia_semana: 'MARTES', hora_inicio: '08:00:00', hora_fin: '17:00:00' },
  { id: 3, proveedor_id: 1, dia_semana: 'MIERCOLES', hora_inicio: '08:00:00', hora_fin: '17:00:00' },
  { id: 4, proveedor_id: 1, dia_semana: 'JUEVES', hora_inicio: '08:00:00', hora_fin: '17:00:00' },
  { id: 5, proveedor_id: 1, dia_semana: 'VIERNES', hora_inicio: '08:00:00', hora_fin: '17:00:00' },
  { id: 6, proveedor_id: 2, dia_semana: 'MARTES', hora_inicio: '09:00:00', hora_fin: '15:00:00' },
  { id: 7, proveedor_id: 2, dia_semana: 'JUEVES', hora_inicio: '09:00:00', hora_fin: '15:00:00' },
  { id: 8, proveedor_id: 2, dia_semana: 'SABADO', hora_inicio: '09:00:00', hora_fin: '15:00:00' }
]);

const today = new Date();
const daysToNextMonday = today.getDay() === 0 ? 1 : 8 - today.getDay();
const monday = new Date(today);
monday.setDate(today.getDate() + daysToNextMonday);
monday.setHours(0, 0, 0, 0);
const at = (base, days, hour, minute) => {
  const result = new Date(base);
  result.setDate(base.getDate() + days);
  result.setHours(hour, minute, 0, 0);
  return result;
};

upsertMany('periodos_no_disponibilidad', [
  { id: 1, proveedor_id: 1, fecha_inicio: at(monday, 2, 0, 0), fecha_fin: at(monday, 2, 23, 59), motivo: 'Cita personal' }
]);

const now = new Date();
upsertMany('recuperacion_contrasena', [
  { id: 1, usuario_id: 3, codigo: 'AB12CD', fecha_expiracion: new Date(now.getTime() + 30 * 60000), fecha_uso: null, fecha_creacion: now, invalidado: true },
  { id: 2, usuario_id: 3, codigo: 'ZX98YW', fecha_expiracion: new Date(now.getTime() + 30 * 60000), fecha_uso: now, fecha_creacion: now, invalidado: true },
  { id: 3, usuario_id: 4, codigo: 'KLM456', fecha_expiracion: new Date(now.getTime() + 30 * 60000), fecha_uso: null, fecha_creacion: now, invalidado: true },
  { id: 4, usuario_id: 4, codigo: 'OLD999', fecha_expiracion: new Date(now.getTime() - 60 * 60000), fecha_uso: null, fecha_creacion: new Date(now.getTime() - 120 * 60000), invalidado: true },
  { id: 5, usuario_id: 4, codigo: 'NEW111', fecha_expiracion: new Date(now.getTime() + 30 * 60000), fecha_uso: null, fecha_creacion: now, invalidado: false }
]);

// Estados finales equivalentes a las actualizaciones y triggers del SQL.
upsertMany('solicitudes', [
  { id: 1, cliente_id: 3, proveedor_id: 1, servicio_id: 1, servicio_nombre: 'Masaje relajante 60 min', servicio_precio: 90000, servicio_duracion: 60, direccion_id: 1, barrio_sector: 'Granada', info_localizacion: null, observaciones: 'Timbre dañado, llamar al llegar.', fecha_hora_inicio: at(monday, 0, 10, 0), fecha_hora_propuesta: null, estado: 'ACEPTADA', motivo: null, fecha_creacion: now, fecha_actualizacion: now },
  { id: 2, cliente_id: 4, proveedor_id: 1, servicio_id: 2, servicio_nombre: 'Limpieza facial', servicio_precio: 70000, servicio_duracion: 45, direccion_id: 3, barrio_sector: 'San Fernando', info_localizacion: null, observaciones: 'Prefiere llegada puntual.', fecha_hora_inicio: at(monday, 0, 10, 30), fecha_hora_propuesta: null, estado: 'PENDIENTE', motivo: null, fecha_creacion: now, fecha_actualizacion: now },
  { id: 3, cliente_id: 5, proveedor_id: 1, servicio_id: 1, servicio_nombre: 'Masaje relajante 60 min', servicio_precio: 90000, servicio_duracion: 60, direccion_id: 4, barrio_sector: 'Alfaguara', info_localizacion: null, observaciones: null, fecha_hora_inicio: at(monday, 0, 11, 0), fecha_hora_propuesta: null, estado: 'COMPLETADA', motivo: null, fecha_creacion: now, fecha_actualizacion: now },
  { id: 4, cliente_id: 3, proveedor_id: 1, servicio_id: 1, servicio_nombre: 'Masaje relajante 60 min', servicio_precio: 90000, servicio_duracion: 60, direccion_id: 2, barrio_sector: 'Ciudad Jardín', info_localizacion: null, observaciones: null, fecha_hora_inicio: at(monday, 2, 10, 0), fecha_hora_propuesta: null, estado: 'PENDIENTE', motivo: null, fecha_creacion: now, fecha_actualizacion: now },
  { id: 5, cliente_id: 4, proveedor_id: 2, servicio_id: 4, servicio_nombre: 'Manicure y pedicure', servicio_precio: 80000, servicio_duracion: 90, direccion_id: 3, barrio_sector: 'San Fernando', info_localizacion: null, observaciones: null, fecha_hora_inicio: at(monday, 0, 10, 0), fecha_hora_propuesta: null, estado: 'PENDIENTE', motivo: null, fecha_creacion: now, fecha_actualizacion: now },
  { id: 6, cliente_id: 3, proveedor_id: 2, servicio_id: 4, servicio_nombre: 'Manicure y pedicure', servicio_precio: 80000, servicio_duracion: 90, direccion_id: 1, barrio_sector: 'Granada', info_localizacion: null, observaciones: null, fecha_hora_inicio: at(monday, 1, 10, 0), fecha_hora_propuesta: at(monday, 3, 10, 0), estado: 'ACEPTADA', motivo: null, fecha_creacion: now, fecha_actualizacion: now },
  { id: 7, cliente_id: 5, proveedor_id: 2, servicio_id: 5, servicio_nombre: 'Maquillaje social', servicio_precio: 100000, servicio_duracion: 60, direccion_id: 4, barrio_sector: 'Alfaguara', info_localizacion: null, observaciones: 'Maquillaje para matrimonio.', fecha_hora_inicio: at(monday, 5, 9, 0), fecha_hora_propuesta: null, estado: 'RECHAZADA', motivo: 'Fuera de mi zona de atención.', fecha_creacion: now, fecha_actualizacion: now },
  { id: 8, cliente_id: 4, proveedor_id: 1, servicio_id: 2, servicio_nombre: 'Limpieza facial', servicio_precio: 70000, servicio_duracion: 45, direccion_id: 3, barrio_sector: 'San Fernando', info_localizacion: null, observaciones: null, fecha_hora_inicio: at(monday, 1, 14, 0), fecha_hora_propuesta: null, estado: 'CANCELADA', motivo: 'El cliente tuvo un imprevisto.', fecha_creacion: now, fecha_actualizacion: now },
  { id: 9, cliente_id: 5, proveedor_id: 1, servicio_id: 2, servicio_nombre: 'Limpieza facial', servicio_precio: 70000, servicio_duracion: 45, direccion_id: 4, barrio_sector: null, info_localizacion: null, observaciones: null, fecha_hora_inicio: at(monday, 7, 10, 0), fecha_hora_propuesta: null, estado: 'PENDIENTE', motivo: null, fecha_creacion: now, fecha_actualizacion: now }
]);

print('Datos de prueba MongoDB cargados correctamente.');
printjson({ usuarios: db.usuarios.countDocuments(), direcciones: db.direcciones.countDocuments(), servicios: db.servicios.countDocuments(), solicitudes: db.solicitudes.countDocuments(), recuperacion_contrasena: db.recuperacion_contrasena.countDocuments() });
