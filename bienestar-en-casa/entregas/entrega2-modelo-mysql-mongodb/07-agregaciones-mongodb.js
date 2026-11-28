/*
 * Bienestar en Casa - consultas mediante agregaciones MongoDB
 * Ejecutar DESPUÉS de 05-modelo-mongodb.js y 06-datos-prueba-mongodb.js.
 * Requiere MongoDB 5.0 o superior ($setWindowFields y $rank).
 *
 * Ejemplo:
 * mongosh "mongodb://localhost:27017" mongodb/07-agregaciones-mongodb.js
 *
 * Las consultas que buscan máximos conservan todos los empates mediante $rank.
 */

use('bienestar_en_casa');

const requiredCollections = ['usuarios', 'servicios', 'solicitudes'];
const missingCollections = requiredCollections.filter(
  (name) => !db.getCollectionNames().includes(name)
);
if (missingCollections.length > 0) {
  throw new Error(
    `Faltan colecciones: ${missingCollections.join(', ')}. Ejecuta primero 05-modelo-mongodb.js.`
  );
}

/*
 * 1. Servicios con mayor número de reservas completadas.
 * Cuenta por servicio; $addToSet evita repetir clientes. $rank conserva empates.
 */
print('\n=== Consulta 1: servicios con más reservas completadas ===');
printjson(db.solicitudes.aggregate([
  { $match: { estado: 'COMPLETADA' } },
  {
    $group: {
      _id: '$servicio_id',
      reservas_completadas: { $sum: 1 },
      clientes_ids: { $addToSet: '$cliente_id' }
    }
  },
  {
    $setWindowFields: {
      sortBy: { reservas_completadas: -1 },
      output: { posicion: { $rank: {} } }
    }
  },
  { $match: { posicion: 1 } },
  { $lookup: { from: 'servicios', localField: '_id', foreignField: 'id', as: 'servicio' } },
  { $unwind: '$servicio' },
  { $lookup: { from: 'usuarios', localField: 'servicio.proveedor_id', foreignField: 'id', as: 'proveedor' } },
  { $unwind: '$proveedor' },
  {
    $lookup: {
      from: 'usuarios',
      let: { ids: '$clientes_ids' },
      pipeline: [
        { $match: { $expr: { $in: ['$id', '$$ids'] } } },
        { $sort: { nombre: 1 } },
        { $project: { _id: 0, nombre: 1 } }
      ],
      as: 'clientes'
    }
  },
  {
    $project: {
      _id: 0,
      servicio: '$servicio.nombre',
      categoria: '$servicio.categoria',
      proveedor: '$proveedor.nombre',
      reservas_completadas: 1,
      clientes: { $map: { input: '$clientes', as: 'cliente', in: '$$cliente.nombre' } }
    }
  },
  { $sort: { servicio: 1 } }
]).toArray());

/*
 * 2. Distribución de solicitudes y reservas por estado para un proveedor.
 * Se parte de usuarios para que un proveedor sin solicitudes también aparezca.
 * Los seis estados se muestran siempre; proveedor sin registros: conteos cero
 * y porcentaje "No aplica".
 */
const estadosSolicitud = [
  'PENDIENTE', 'SUGERIDA', 'RECHAZADA', 'CANCELADA', 'ACEPTADA', 'COMPLETADA'
];

const consultaDistribucionProveedor = (proveedorId) => db.usuarios.aggregate([
  { $match: { id: proveedorId, tipo: 'PROVEEDOR' } },
  {
    $lookup: {
      from: 'solicitudes',
      let: { idProveedor: '$id' },
      pipeline: [
        { $match: { $expr: { $eq: ['$proveedor_id', '$$idProveedor'] } } },
        { $group: { _id: '$estado', cantidad: { $sum: 1 } } }
      ],
      as: 'conteos'
    }
  },
  { $set: { total_registros: { $sum: '$conteos.cantidad' } } },
  {
    $set: {
      distribucion_por_estado: {
        $map: {
          input: estadosSolicitud,
          as: 'estado',
          in: {
            $let: {
              vars: {
                cantidadEstado: {
                  $ifNull: [
                    {
                      $arrayElemAt: [
                        {
                          $map: {
                            input: {
                              $filter: {
                                input: '$conteos',
                                as: 'conteo',
                                cond: { $eq: ['$$conteo._id', '$$estado'] }
                              }
                            },
                            as: 'coincidencia',
                            in: '$$coincidencia.cantidad'
                          }
                        },
                        0
                      ]
                    },
                    0
                  ]
                }
              },
              in: {
                estado: '$$estado',
                cantidad: '$$cantidadEstado',
                porcentaje: {
                  $cond: [
                    { $eq: ['$total_registros', 0] },
                    'No aplica',
                    {
                      $round: [
                        { $multiply: [{ $divide: ['$$cantidadEstado', '$total_registros'] }, 100] },
                        2
                      ]
                    }
                  ]
                }
              }
            }
          }
        }
      }
    }
  },
  { $project: { _id: 0, proveedor: '$nombre', total_registros: 1, distribucion_por_estado: 1 } }
]);

print('\n=== Consulta 2: distribución por estado (proveedor 1) ===');
printjson(consultaDistribucionProveedor(1).toArray());
print('\n=== Consulta 2: distribución por estado (proveedor 2) ===');
printjson(consultaDistribucionProveedor(2).toArray());
print('\n=== Consulta 2: proveedor 6 sin registros (conteos cero) ===');
printjson(consultaDistribucionProveedor(6).toArray());

/*
 * 3. Servicio o servicios con el precio actual más alto, activos o inactivos.
 * Se parte del catálogo completo para conservar servicios sin solicitudes.
 */
print('\n=== Consulta 3: servicios con el precio más alto ===');
printjson(db.servicios.aggregate([
  {
    $setWindowFields: {
      sortBy: { precio: -1 },
      output: { posicion: { $rank: {} } }
    }
  },
  { $match: { posicion: 1 } },
  { $lookup: { from: 'usuarios', localField: 'proveedor_id', foreignField: 'id', as: 'proveedor' } },
  { $unwind: '$proveedor' },
  {
    $lookup: {
      from: 'solicitudes',
      let: { idServicio: '$id' },
      pipeline: [
        { $match: { $expr: { $eq: ['$servicio_id', '$$idServicio'] } } },
        {
          $group: {
            _id: null,
            total_solicitudes: { $sum: 1 },
            aceptadas_o_completadas: {
              $sum: { $cond: [{ $in: ['$estado', ['ACEPTADA', 'COMPLETADA']] }, 1, 0] }
            }
          }
        }
      ],
      as: 'conteos'
    }
  },
  {
    $project: {
      _id: 0,
      servicio: '$nombre',
      precio_actual: '$precio',
      categoria: 1,
      proveedor: '$proveedor.nombre',
      total_solicitudes: { $ifNull: [{ $arrayElemAt: ['$conteos.total_solicitudes', 0] }, 0] },
      reservas_aceptadas_o_completadas: {
        $ifNull: [{ $arrayElemAt: ['$conteos.aceptadas_o_completadas', 0] }, 0]
      }
    }
  },
  { $sort: { servicio: 1 } }
]).toArray());

/*
 * 4. Cliente o clientes con más solicitudes, contando todos los estados.
 * Agrupa también por servicio para devolver el detalle solicitado.
 */
print('\n=== Consulta 4: clientes con más solicitudes ===');
printjson(db.solicitudes.aggregate([
  {
    $group: {
      _id: { cliente_id: '$cliente_id', servicio_id: '$servicio_id' },
      cantidad: { $sum: 1 }
    }
  },
  { $lookup: { from: 'servicios', localField: '_id.servicio_id', foreignField: 'id', as: 'servicio' } },
  { $unwind: '$servicio' },
  { $sort: { 'servicio.nombre': 1 } },
  {
    $group: {
      _id: '$_id.cliente_id',
      total_solicitudes: { $sum: '$cantidad' },
      servicios_solicitados: {
        $push: { servicio: '$servicio.nombre', cantidad: '$cantidad' }
      }
    }
  },
  {
    $setWindowFields: {
      sortBy: { total_solicitudes: -1 },
      output: { posicion: { $rank: {} } }
    }
  },
  { $match: { posicion: 1 } },
  { $lookup: { from: 'usuarios', localField: '_id', foreignField: 'id', as: 'cliente' } },
  { $unwind: '$cliente' },
  {
    $project: {
      _id: 0,
      cliente: '$cliente.nombre',
      total_solicitudes: 1,
      servicios_solicitados: 1
    }
  },
  { $sort: { cliente: 1 } }
]).toArray());

/*
 * 5. Servicio o servicios con más recursos multimedia.
 * Multimedia está embebida en servicios.multimedia[].
 */
print('\n=== Consulta 5: servicios con más recursos multimedia ===');
printjson(db.servicios.aggregate([
  {
    $set: {
      multimedia: { $ifNull: ['$multimedia', []] }
    }
  },
  {
    $set: {
      cantidad_fotografias: {
        $size: { $filter: { input: '$multimedia', as: 'recurso', cond: { $eq: ['$$recurso.tipo', 'FOTO'] } } }
      },
      cantidad_videos: {
        $size: { $filter: { input: '$multimedia', as: 'recurso', cond: { $eq: ['$$recurso.tipo', 'VIDEO'] } } }
      }
    }
  },
  { $set: { total_recursos: { $add: ['$cantidad_fotografias', '$cantidad_videos'] } } },
  { $match: { total_recursos: { $gt: 0 } } },
  {
    $setWindowFields: {
      sortBy: { total_recursos: -1 },
      output: { posicion: { $rank: {} } }
    }
  },
  { $match: { posicion: 1 } },
  { $lookup: { from: 'usuarios', localField: 'proveedor_id', foreignField: 'id', as: 'proveedor' } },
  { $unwind: '$proveedor' },
  {
    $project: {
      _id: 0,
      servicio: '$nombre',
      proveedor: '$proveedor.nombre',
      categoria: 1,
      cantidad_fotografias: 1,
      cantidad_videos: 1,
      total_recursos: 1,
      recursos_multimedia: {
        $map: {
          input: '$multimedia',
          as: 'recurso',
          in: { tipo: '$$recurso.tipo', url: '$$recurso.url', orden: '$$recurso.orden' }
        }
      }
    }
  },
  { $sort: { servicio: 1 } }
]).toArray());
