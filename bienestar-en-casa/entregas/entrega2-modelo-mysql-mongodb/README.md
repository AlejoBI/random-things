# Entrega 2 – Modelo MySQL y MongoDB

Esta carpeta fue preparada a partir de `ENTRAGA.2.BDM.PROYECTO.sql`, recibido
como fuente de verdad. El archivo original se conserva íntegramente en
`00-fuente-original.sql`.

## Archivos

| Archivo | Contenido | Uso |
|---|---|---|
| `00-fuente-original.sql` | Copia exacta del archivo entregado | Respaldo y trazabilidad |
| `01-modelo-mysql.sql` | Base de datos, tablas, claves, restricciones e índices | Ejecutar en MySQL |
| `01-hackolade-ddl.sql` | Solo `CREATE TABLE`, sin datos ni comandos de base de datos | Importar en Hackolade como MySQL DDL |
| `02-logica-negocio.sql` | Triggers y procedimientos almacenados | Ejecutar después del modelo |
| `03-datos-prueba.sql` | Datos iniciales y pruebas de estados | Ejecutar después del modelo y la lógica |
| `04-consultas-y-pruebas.sql` | Consultas, actualizaciones y verificaciones finales | Ejecutar con la base cargada |
| `05-modelo-mongodb.js` | Colecciones, validadores, índices y decisiones de modelado | Ejecutar en `mongosh` |
| `06-datos-prueba-mongodb.js` | Datos de prueba equivalentes al SQL, adaptados a 8 colecciones | Ejecutar después del modelo MongoDB |
| `07-json-schema-mongodb/` | Ocho archivos `.schema.json`, uno por colección | Importar en Hackolade como JSON Schema |

## Orden recomendado para MySQL

```text
01-modelo-mysql.sql
02-logica-negocio.sql
03-datos-prueba.sql
04-consultas-y-pruebas.sql
```

`01-hackolade-ddl.sql` es el archivo que debe utilizarse para generar el
diagrama relacional. Es DDL puro: no contiene `INSERT`, `SELECT`, pruebas,
triggers, procedimientos ni `DROP DATABASE`.

Para ejecutar el SQL completo se debe usar `01-modelo-mysql.sql`, seguido de
`02-logica-negocio.sql`, `03-datos-prueba.sql` y `04-consultas-y-pruebas.sql`.
El archivo de lógica selecciona explícitamente la base `bienestar_en_casa`, por
lo que también funciona si se ejecuta en una ventana separada.

## Decisiones del modelo MongoDB

- `usuarios` conserva los datos comunes y el perfil específico (`cliente` o
  `proveedor`) en el mismo documento.
- `direcciones`, `zonas_cobertura`, `horarios_disponibilidad` y
  `periodos_no_disponibilidad` permanecen como colecciones porque se consultan
  y actualizan de forma independiente.
- `servicios_multimedia` y `servicios_insumos` se embeben dentro de `servicios`:
  pertenecen exclusivamente a un servicio y se leen junto con él.
- `solicitudes` conserva referencias a cliente, proveedor, servicio y dirección,
  además de la copia `servicio_nombre`, `servicio_precio` y
  `servicio_duracion`, tal como exige el SQL.
- `06-datos-prueba-mongodb.js` carga los datos de demostración y los estados
  finales equivalentes a las pruebas del SQL. Usa `upsert`, por lo que puede
  ejecutarse nuevamente sin duplicar esos documentos.
- MongoDB no reproduce automáticamente los triggers SQL. Las reglas de estados,
  disponibilidad, solapamiento y recuperación deben implementarse en la capa
  de aplicación o en transacciones.

## Nota de compatibilidad

El SQL entregado usa sintaxis específica de MySQL 8 (`ENUM`, `DELIMITER`,
`SIGNAL`, `FOLLOWS`, `utf8mb4_0900_ai_ci` y triggers). Para Hackolade debe
importarse `01-hackolade-ddl.sql`, seleccionando MySQL como dialecto. Para el
modelo documental se deben importar los archivos de `07-json-schema-mongodb/`
como JSON Schema y seleccionar MongoDB como destino.
