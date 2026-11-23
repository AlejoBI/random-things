/*
 * Bienestar en Casa - modelo documental MongoDB
 * Fuente: 00-fuente-original.sql
 * Ejecutar con mongosh.
 *
 * Este archivo modela los datos y las restricciones estructurales. Las reglas
 * que en MySQL están en triggers/procedimientos deben validarse en el backend.
 */

use('bienestar_en_casa');

// Permite volver a ejecutar el diseño sin borrar datos existentes.
const ensureCollection = (name, options) => {
  if (!db.getCollectionNames().includes(name)) db.createCollection(name, options);
};

ensureCollection('usuarios', {
  validator: {
    $jsonSchema: {
      bsonType: 'object',
      required: ['email', 'password_hash', 'tipo', 'nombre', 'fecha_registro'],
      properties: {
        email: { bsonType: 'string', maxLength: 120 },
        password_hash: { bsonType: 'string', maxLength: 255 },
        tipo: { enum: ['CLIENTE', 'PROVEEDOR'] },
        nombre: { bsonType: 'string', maxLength: 100 },
        telefono: { bsonType: ['string', 'null'], maxLength: 20 },
        fecha_registro: { bsonType: 'date' },
        // Equivalentes de las tablas clientes y proveedores.
        cliente: { bsonType: ['object', 'null'] },
        proveedor: {
          bsonType: ['object', 'null'],
          properties: {
            biografia: { bsonType: ['string', 'null'] },
            anios_experiencia: { bsonType: ['int', 'long', 'null'], minimum: 0 }
          }
        }
      }
    }
  },
  validationLevel: 'strict',
  validationAction: 'error'
});

ensureCollection('direcciones', {
  validator: {
    $jsonSchema: {
      bsonType: 'object',
      required: ['cliente_id', 'ciudad', 'calle', 'es_principal'],
      properties: {
        cliente_id: { bsonType: ['objectId', 'int', 'long'] },
        ciudad: { bsonType: 'string', maxLength: 80 },
        barrio: { bsonType: ['string', 'null'], maxLength: 80 },
        calle: { bsonType: 'string', maxLength: 120 },
        numero: { bsonType: ['string', 'null'], maxLength: 20 },
        referencia: { bsonType: ['string', 'null'] },
        es_principal: { bsonType: 'bool' }
      }
    }
  }
});

ensureCollection('zonas_cobertura');
ensureCollection('horarios_disponibilidad');
ensureCollection('periodos_no_disponibilidad');

ensureCollection('servicios', {
  validator: {
    $jsonSchema: {
      bsonType: 'object',
      required: [
        'proveedor_id', 'nombre', 'categoria', 'duracion_minutos',
        'precio', 'estado', 'multimedia', 'insumos'
      ],
      properties: {
        proveedor_id: { bsonType: ['objectId', 'int', 'long'] },
        nombre: { bsonType: 'string', maxLength: 100 },
        categoria: { bsonType: 'string', maxLength: 80 },
        descripcion: { bsonType: ['string', 'null'] },
        duracion_minutos: { bsonType: ['int', 'long'], minimum: 1 },
        precio: { bsonType: ['double', 'decimal', 'int', 'long'], minimum: 0 },
        estado: { enum: ['ACTIVO', 'INACTIVO'] },
        multimedia: {
          bsonType: 'array',
          items: { bsonType: 'object', required: ['tipo', 'url', 'orden'] }
        },
        insumos: {
          bsonType: 'array',
          items: { bsonType: 'object', required: ['tipo', 'nombre'] }
        }
      }
    }
  }
});

ensureCollection('recuperacion_contrasena');

ensureCollection('solicitudes', {
  validator: {
    $jsonSchema: {
      bsonType: 'object',
      required: [
        'cliente_id', 'proveedor_id', 'servicio_id', 'servicio_nombre',
        'servicio_precio', 'servicio_duracion', 'direccion_id',
        'fecha_hora_inicio', 'estado', 'fecha_creacion', 'fecha_actualizacion'
      ],
      properties: {
        cliente_id: { bsonType: ['objectId', 'int', 'long'] },
        proveedor_id: { bsonType: ['objectId', 'int', 'long'] },
        servicio_id: { bsonType: ['objectId', 'int', 'long'] },
        servicio_nombre: { bsonType: 'string', maxLength: 100 },
        servicio_precio: { bsonType: ['double', 'decimal', 'int', 'long'], minimum: 0 },
        servicio_duracion: { bsonType: ['int', 'long'], minimum: 1 },
        direccion_id: { bsonType: ['objectId', 'int', 'long'] },
        barrio_sector: { bsonType: ['string', 'null'], maxLength: 100 },
        info_localizacion: { bsonType: ['string', 'null'] },
        observaciones: { bsonType: ['string', 'null'] },
        fecha_hora_inicio: { bsonType: 'date' },
        fecha_hora_propuesta: { bsonType: ['date', 'null'] },
        estado: { enum: ['PENDIENTE', 'SUGERIDA', 'ACEPTADA', 'RECHAZADA', 'CANCELADA', 'COMPLETADA'] },
        motivo: { bsonType: ['string', 'null'] },
        fecha_creacion: { bsonType: 'date' },
        fecha_actualizacion: { bsonType: 'date' }
      }
    }
  }
});

// Índices equivalentes a los UNIQUE/INDEX del SQL y a las consultas del archivo.
db.usuarios.createIndex({ email: 1 }, { unique: true });
db.direcciones.createIndex({ cliente_id: 1 });
db.zonas_cobertura.createIndex({ proveedor_id: 1, ciudad: 1, barrio_sector: 1 }, { unique: true });
db.servicios.createIndex({ proveedor_id: 1, nombre: 1 }, { unique: true });
db.servicios.createIndex({ categoria: 1 });
db.servicios.createIndex({ nombre: 1 });
db.horarios_disponibilidad.createIndex({ proveedor_id: 1, dia_semana: 1, hora_inicio: 1, hora_fin: 1 }, { unique: true });
db.periodos_no_disponibilidad.createIndex({ proveedor_id: 1, fecha_inicio: 1, fecha_fin: 1 });
db.recuperacion_contrasena.createIndex({ codigo: 1 }, { unique: true });
db.recuperacion_contrasena.createIndex({ usuario_id: 1, invalidado: 1 });
db.solicitudes.createIndex({ proveedor_id: 1, estado: 1, fecha_hora_inicio: 1 });
db.solicitudes.createIndex({ cliente_id: 1 });

/*
 * Reglas que debe implementar la aplicación:
 * 1. tipo CLIENTE/PROVEEDOR debe coincidir con el perfil embebido.
 * 2. Una solicitud solo usa servicios ACTIVOS del proveedor indicado.
 * 3. Al crearla se copian nombre, precio y duración del servicio.
 * 4. Validar transiciones de estado y motivo en RECHAZADA/CANCELADA.
 * 5. Validar horario, periodos no disponibles y reservas solapadas.
 * 6. Los códigos de recuperación son de un solo uso, expiran y se invalidan
 *    al generar otro código para el mismo usuario.
 */
