# JSON Schema para Hackolade (MongoDB)

Estos archivos son la entrada JSON correcta para el modelo documental. En
Hackolade selecciona:

```text
Tools → Reverse-Engineer → JSON Schema
```

Selecciona los ocho archivos `.schema.json` al mismo tiempo y elige MongoDB
como destino. Cada archivo representa una colección. Los tipos, campos,
enumeraciones y campos embebidos se basan en el SQL fuente.

El archivo `05-modelo-mongodb.js` es distinto: sirve para crear las
colecciones, validadores e índices en `mongosh`; no es el archivo de entrada
del importador JSON de Hackolade.

## Colecciones

- `usuarios`: incluye los perfiles específicos de cliente/proveedor.
- `direcciones`
- `zonas_cobertura`
- `servicios`: incluye `multimedia` e `insumos` embebidos.
- `horarios_disponibilidad`
- `periodos_no_disponibilidad`
- `recuperacion_contrasena`
- `solicitudes`: mantiene las referencias y el snapshot del servicio.
