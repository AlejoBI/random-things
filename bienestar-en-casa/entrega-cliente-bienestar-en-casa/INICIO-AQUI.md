# Inicio aquí

Esta carpeta contiene el diseño de la base de datos de **Bienestar en Casa**.
Si no tienes experiencia en bases de datos, sigue primero esta guía.

## ¿Qué recibiste?

Hay dos versiones del mismo sistema:

1. **MySQL:** usa tablas relacionadas.
2. **MongoDB:** usa colecciones y documentos.

Los archivos `.svg` son imágenes de los diagramas. Puedes abrirlos haciendo
doble clic desde el explorador de archivos.

## Si solo quieres estudiar los diagramas

Abre estos dos archivos:

```text
diagramas/diagrama-relacional-mysql.svg
diagramas/diagrama-documental-mongodb.svg
```

El primero muestra las tablas de MySQL. El segundo muestra las colecciones de
MongoDB.

## Si quieres abrir los modelos en Hackolade

Abre los archivos de la carpeta `hackolade/` desde Hackolade:

```text
hackolade/bienestar-en-casa-mysql.hck.json
hackolade/bienestar-en-casa-mongodb.hck.json
```

El modelo MySQL muestra 12 tablas. El modelo MongoDB muestra 8 colecciones.

## Si quieres crear la base MySQL

Necesitas tener instalado MySQL, XAMPP o una herramienta como MySQL Workbench.
Ejecuta los archivos en este orden:

```text
sql/01-modelo-mysql.sql
sql/02-logica-negocio.sql
sql/03-datos-prueba.sql
sql/04-consultas-y-pruebas.sql
```

No ejecutes `00-fuente-original.sql` si ya ejecutaste los cuatro archivos
anteriores: es la versión completa original y se conserva solo como respaldo.

## Si quieres crear la estructura MongoDB

Necesitas tener instalado MongoDB y `mongosh`, o usar MongoDB Atlas.

Ejecuta este único archivo:

```text
mongodb/05-modelo-mongodb.js
```

Si también quieres cargar los datos de ejemplo equivalentes a los datos de
MySQL, ejecuta después:

```text
mongodb/06-datos-prueba-mongodb.js
```

Ejemplo para una instalación local:

```bash
mongosh "mongodb://localhost:27017" mongodb/05-modelo-mongodb.js
```

Después de ejecutarlo se crearán estas 8 colecciones:

```text
usuarios
direcciones
zonas_cobertura
servicios
horarios_disponibilidad
periodos_no_disponibilidad
recuperacion_contrasena
solicitudes
```

El primer script crea la estructura, los validadores y los índices. El segundo
carga los datos de prueba. El segundo puede ejecutarse nuevamente sin duplicar
los documentos de ejemplo.

## ¿Qué son los JSON Schema?

Los archivos de `mongodb/json-schema/` describen cómo deben ser los documentos
de MongoDB. Se utilizan para estudiar o importar el modelo en Hackolade.

Por sí solos no crean la base de datos. Para crear las colecciones se utiliza
`mongodb/05-modelo-mongodb.js`.

## ¿Por qué hay 12 tablas y 8 colecciones?

No falta información. MongoDB permite guardar algunos datos relacionados dentro
del mismo documento:

- `clientes` y `proveedores` quedan dentro de `usuarios`.
- `servicios_multimedia` y `servicios_insumos` quedan dentro de `servicios`.

Por eso:

```text
12 tablas SQL → 8 colecciones MongoDB
```

Es una adaptación del diseño, no una pérdida de datos.

## Importante

Esta entrega contiene el diseño y la estructura de las bases de datos. No
incluye una migración automática de los datos de MySQL a MongoDB. Eso requeriría
un script adicional.
