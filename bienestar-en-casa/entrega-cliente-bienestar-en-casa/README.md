# Entrega – Bienestar en Casa

Esta carpeta contiene únicamente los entregables del modelo de base de datos
relacional y documental. El archivo SQL original se conserva y también se
incluye separado por etapas para facilitar su estudio y ejecución.

Si no tienes experiencia en bases de datos, comienza por
[`INICIO-AQUI.md`](INICIO-AQUI.md). Allí se explica qué archivo abrir, qué
archivo ejecutar y en qué orden.

Para cargar datos de ejemplo en MongoDB, ejecuta después del modelo:
`mongodb/06-datos-prueba-mongodb.js`.

## Contenido

```text
entrega-cliente-bienestar-en-casa/
├── sql/
├── diagramas/
├── hackolade/
└── mongodb/
```

## 1. Modelo relacional MySQL

### Diagrama y modelo Hackolade

- `diagramas/diagrama-relacional-mysql.svg`
- `hackolade/bienestar-en-casa-mysql.hck.json`

El archivo que se importa en Hackolade para generar el modelo relacional es:

```text
sql/01-hackolade-ddl.sql
```

Ese archivo contiene únicamente la definición de las tablas, claves,
restricciones e índices. No contiene datos, consultas, triggers ni
procedimientos.

### Orden de ejecución del SQL completo

Ejecutar en este orden, usando MySQL 8:

```text
sql/01-modelo-mysql.sql
sql/02-logica-negocio.sql
sql/03-datos-prueba.sql
sql/04-consultas-y-pruebas.sql
```

Cada etapa tiene una finalidad diferente:

1. `01-modelo-mysql.sql`: crea la base `bienestar_en_casa` y sus 12 tablas.
2. `02-logica-negocio.sql`: crea triggers y procedimientos almacenados.
3. `03-datos-prueba.sql`: inserta datos y prueba estados del sistema.
4. `04-consultas-y-pruebas.sql`: ejecuta consultas y verificaciones.

`00-fuente-original.sql` es la copia completa del archivo recibido. No hace
falta ejecutarlo si se utilizan las cuatro etapas anteriores.

## 2. Modelo documental MongoDB

### Diagrama y modelo Hackolade

- `diagramas/diagrama-documental-mongodb.svg`
- `hackolade/bienestar-en-casa-mongodb.hck.json`

Los JSON Schema de `mongodb/json-schema/` sirven para importar el modelo en
Hackolade mediante:

```text
Tools → Reverse-Engineer → JSON Schema
```

Selecciona MongoDB como destino y carga los ocho archivos `.schema.json`.

### Crear las colecciones reales

Los JSON Schema documentan la estructura, pero por sí solos no crean las
colecciones en una base de datos MongoDB. Para crear la estructura real se
ejecuta:

```text
mongodb/05-modelo-mongodb.js
```

Ejemplo con MongoDB local:

```bash
mongosh "mongodb://localhost:27017" mongodb/05-modelo-mongodb.js
```

Ejemplo con MongoDB Atlas:

```bash
mongosh "mongodb+srv://USUARIO:CONTRASEÑA@CLUSTER.mongodb.net/" mongodb/05-modelo-mongodb.js
```

El script crea la base `bienestar_en_casa`, las colecciones, validadores e
índices. No borra una base existente y no inserta datos de prueba.

Para validar el resultado:

```javascript
use('bienestar_en_casa');
show collections;
db.getCollectionInfos();
```

Las colecciones esperadas son:

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

## 3. ¿Por qué MySQL tiene 12 tablas y MongoDB 8 colecciones?

No se perdió información. El modelo MongoDB usa documentos embebidos para
evitar separar información que pertenece exclusivamente al mismo documento.

### Conversión de usuarios

En SQL existen:

```text
usuarios
clientes
proveedores
```

En MongoDB se utiliza una sola colección `usuarios`. El perfil específico se
guarda dentro del documento como `cliente` o `proveedor`.

### Conversión de servicios

En SQL existen:

```text
servicios
servicios_multimedia
servicios_insumos
```

En MongoDB se utiliza una colección `servicios` con dos arrays embebidos:

```text
servicios.multimedia[]
servicios.insumos[]
```

Por eso:

```text
12 tablas SQL - 4 tablas absorbidas = 8 colecciones MongoDB
```

Las colecciones restantes conservan sus propios documentos porque se consultan
y actualizan independientemente.

## 4. Relaciones en MongoDB

MongoDB no impone claves foráneas como MySQL. Las relaciones se conservan como
referencias y están documentadas en el modelo Hackolade:

```text
direcciones.cliente_id → usuarios.id
zonas_cobertura.proveedor_id → usuarios.id
servicios.proveedor_id → usuarios.id
horarios_disponibilidad.proveedor_id → usuarios.id
periodos_no_disponibilidad.proveedor_id → usuarios.id
recuperacion_contrasena.usuario_id → usuarios.id
solicitudes.cliente_id → usuarios.id
solicitudes.proveedor_id → usuarios.id
solicitudes.servicio_id → servicios.id
solicitudes.direccion_id → direcciones.id
```

Estas referencias deben validarse en la aplicación. Las reglas de estados,
disponibilidad, solapamiento de reservas y recuperación de contraseña que en
MySQL están implementadas con triggers/procedimientos también deben
implementarse en el backend de MongoDB.

## 5. Alcance de esta entrega

Esta entrega contiene el diseño, scripts, diagramas, validadores e índices.
El script MongoDB crea la estructura, pero no realiza una migración automática
de los datos de prueba SQL. Una migración de datos sería un entregable aparte.
