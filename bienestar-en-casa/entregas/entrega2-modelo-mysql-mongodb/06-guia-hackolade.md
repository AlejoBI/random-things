# Guía para generar el diagrama en Hackolade

## Archivo que se debe importar

Para el diagrama relacional usa únicamente:

```text
01-hackolade-ddl.sql
```

No importes `00-fuente-original.sql` ni `01-modelo-mysql.sql`: contienen
comandos de ejecución que no son necesarios para el reverse-engineering del
DDL.

Para el diagrama documental de MongoDB importa los ocho archivos de
`07-json-schema-mongodb/` mediante `Tools > Reverse-Engineer > JSON Schema` y
selecciona MongoDB como destino.

## Relaciones que deben aparecer

```text
usuarios 1 ── 1 clientes 1 ── N direcciones
usuarios 1 ── 1 proveedores 1 ── N zonas_cobertura
                                      1 ── N horarios_disponibilidad
                                      1 ── N periodos_no_disponibilidad
                                      1 ── N servicios 1 ── N servicios_multimedia
                                                         1 ── N servicios_insumos
usuarios 1 ── N recuperacion_contrasena
solicitudes N ── 1 clientes
solicitudes N ── 1 proveedores
solicitudes N ── 1 servicios
solicitudes N ── 1 direcciones
```

## Revisión después de importar

- `clientes.usuario_id` y `proveedores.usuario_id` son simultáneamente PK y FK
  hacia `usuarios.id`.
- `solicitudes` debe conservar las cuatro FK: cliente, proveedor, servicio y
  dirección.
- `servicios_multimedia` y `servicios_insumos` dependen de `servicios`.
- Las columnas `servicio_nombre`, `servicio_precio` y `servicio_duracion` de
  `solicitudes` son un snapshot intencional, no relaciones duplicadas.
- Los triggers y procedimientos de `02-logica-negocio.sql` no forman parte del
  diagrama entidad-relación; se entregan aparte como lógica de negocio.

En Hackolade selecciona el dialecto **MySQL** y verifica que el nombre de la
tabla sea `servicios_multimedia`. Ese es el nombre del archivo fuente recibido;
no debe cambiarse por `servicios_media` al generar este diagrama.
