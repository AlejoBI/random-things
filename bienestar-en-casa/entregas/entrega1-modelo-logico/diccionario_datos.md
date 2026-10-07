# Diccionario de datos – Entrega 1

Cada columna indica: **tipo MySQL → justificación (frase del texto)**.
Conventions: PK = clave primaria, FK = clave foránea, UK = única.

---

## `usuarios`
> "dos tipos de usuarios: clientes y proveedores... correo electrónico y una contraseña... hash irreversible"

| Columna | Tipo | Restricción | Origen en el texto |
|---|---|---|---|
| id | INT | PK, AUTO_INCREMENT | identidad interna de cada usuario |
| email | VARCHAR(120) | NOT NULL, **UK** | "correo electrónico" — es la credencial de login, por eso único |
| password_hash | VARCHAR(255) | NOT NULL | "almacenarse mediante un mecanismo de hash irreversible" (bcrypt) |
| tipo | ENUM('CLIENTE','PROVEEDOR') | NOT NULL | "dos tipos de usuarios" |
| nombre | VARCHAR(100) | NOT NULL | "datos... para su identificación" |
| telefono | VARCHAR(20) | NULL | dato de contacto complementario |
| fecha_registro | DATETIME | NOT NULL, DEFAULT NOW() | identificación en el sistema |

## `recuperacion_contrasena`
> "código de verificación de un solo uso o a un enlace temporal, considerando su vigencia e invalidación después de ser utilizado o cuando se genere una nueva solicitud"

| Columna | Tipo | Restricción | Origen en el texto |
|---|---|---|---|
| id | INT | PK | |
| usuario_id | INT | FK → usuarios | pertenece a un usuario |
| codigo | VARCHAR(20) | NOT NULL, **UK** | "código de verificación" (o hash del enlace temporal) |
| fecha_expiracion | DATETIME | NOT NULL | "vigencia" |
| fecha_uso | DATETIME | NULL | "invalidación después de ser utilizado" — NULL = sin usar |
| fecha_creacion | DATETIME | NOT NULL | nueva solicitud invalida las anteriores |

## `clientes` / `proveedores` (1:1 con usuarios)
> "los clientes podrán registrar sus datos personales... los proveedores contarán con un perfil profesional"

| Columna | Tipo | Restricción | Origen |
|---|---|---|---|
| usuario_id (ambas tablas) | INT | PK = FK → usuarios | herencia 1:1 |
| biografia (proveedores) | TEXT | NULL | "perfil profesional" |
| anios_experiencia (proveedores) | INT | NULL | perfil profesional |

## `direcciones`
> "una dirección principal"... "la dirección donde se prestará... principal o una dirección diferente"

| Columna | Tipo | Restricción | Origen |
|---|---|---|---|
| id | INT | PK | |
| cliente_id | INT | FK → clientes | direcciones del cliente |
| ciudad | VARCHAR(80) | NOT NULL | dirección |
| barrio | VARCHAR(80) | NULL | dirección |
| calle | VARCHAR(120) | NOT NULL | dirección |
| numero | VARCHAR(20) | NULL | dirección (puede ser s/n) |
| referencia | TEXT | NULL | "información complementaria necesaria para localizar el lugar" |
| es_principal | BOOLEAN | NOT NULL, DEFAULT FALSE | "su dirección principal" |

## `zonas_cobertura`
> "ciudades, barrios o sectores en los que prestan sus servicios... únicamente carácter orientativo... no realizará cálculos de distancia"

| Columna | Tipo | Restricción | Origen |
|---|---|---|---|
| id | INT | PK | |
| proveedor_id | INT | FK → proveedores | zonas del proveedor |
| ciudad | VARCHAR(80) | NOT NULL | "ciudades" |
| barrio_sector | VARCHAR(100) | NULL | "barrios o sectores" — solo texto, sin coordenadas |

## `servicios`
> "su nombre, categoría, descripción, duración estimada en minutos, precio y estado... activo o inactivo"

| Columna | Tipo | Restricción | Origen |
|---|---|---|---|
| id | INT | PK | |
| proveedor_id | INT | FK → proveedores | "cada proveedor podrá administrar un catálogo" |
| nombre | VARCHAR(100) | NOT NULL | "nombre" — índice compuesto con categoria |
| categoria | VARCHAR(80) | NOT NULL | "categoría" — "búsquedas de servicios por nombre o categoría" |
| descripcion | TEXT | NULL | "descripción" |
| duracion_minutos | INT | NOT NULL | "duración estimada en minutos" |
| precio | DECIMAL(10,2) | NOT NULL | "precio" — DECIMAL por dinero |
| estado | ENUM('ACTIVO','INACTIVO') | NOT NULL, DEFAULT 'ACTIVO' | "si el servicio se encuentra activo o inactivo" |

## `servicios_media`
> "fotografías y videos de referencia"

| Columna | Tipo | Restricción | Origen |
|---|---|---|---|
| id | INT | PK | |
| servicio_id | INT | FK → servicios | "asociadas a un servicio" |
| tipo | ENUM('FOTO','VIDEO') | NOT NULL | "fotografías y videos" |
| url | VARCHAR(500) | NOT NULL | ubicación del archivo/recurso |
| orden | TINYINT | DEFAULT 0 | presentación en el catálogo |

## `servicios_insumos`
> "productos, insumos o equipos utilizados para prestar cada servicio"

| Columna | Tipo | Restricción | Origen |
|---|---|---|---|
| id | INT | PK | |
| servicio_id | INT | FK → servicios | "para prestar cada servicio" |
| tipo | ENUM('PRODUCTO','INSUMO','EQUIPO') | NOT NULL | "productos, insumos o equipos" |
| nombre | VARCHAR(150) | NOT NULL | identificación |
| descripcion | TEXT | NULL | detalle |

## `horarios_disponibilidad`
> "los días en los que presta atención y las horas de inicio y finalización correspondientes"

| Columna | Tipo | Restricción | Origen |
|---|---|---|---|
| id | INT | PK | |
| proveedor_id | INT | FK → proveedores | "cada proveedor podrá registrar sus horarios" |
| dia_semana | ENUM('LUNES'...'DOMINGO') | NOT NULL | "los días en los que presta atención" |
| hora_inicio | TIME | NOT NULL | "horas de inicio" |
| hora_fin | TIME | NOT NULL | "finalización" |

## `periodos_no_disponibilidad`
> "fechas o periodos en los cuales no estará disponible"

| Columna | Tipo | Restricción | Origen |
|---|---|---|---|
| id | INT | PK | |
| proveedor_id | INT | FK → proveedores | |
| fecha_inicio | DATETIME | NOT NULL | "fechas o periodos" |
| fecha_fin | DATETIME | NOT NULL | fin del periodo |
| motivo | VARCHAR(200) | NULL | detalle opcional |

## `solicitudes`
> ver las 9 decisiones en `docs/01-modelo-logico.md`

| Columna | Tipo | Restricción | Origen |
|---|---|---|---|
| id | INT | PK | |
| cliente_id | INT | FK → clientes | "cuando un cliente desee solicitar" |
| proveedor_id | INT | FK → proveedores | "deberá seleccionar el proveedor" |
| servicio_id | INT | FK → servicios | "y el servicio correspondiente" |
| servicio_nombre | VARCHAR(100) | NOT NULL | **"conservar una copia del nombre"** — copia del catálogo al crear la solicitud |
| servicio_precio | DECIMAL(10,2) | NOT NULL | **"conservar una copia... del precio"** — no cambia si el proveedor modifica su catálogo |
| servicio_duracion | INT | NOT NULL | **"conservar una copia... duración"** + define el periodo ocupado (inicio + duración) |
| direccion_id | INT | FK → direcciones | "especificar la dirección donde se prestará" |
| barrio_sector | VARCHAR(100) | NULL | "podrá contener además el barrio o sector" |
| info_localizacion | TEXT | NULL | "información complementaria necesaria para localizar" |
| observaciones | TEXT | NULL | "observaciones adicionales" |
| fecha_hora_inicio | DATETIME | NOT NULL | "la fecha y hora en las que desea recibirlo" |
| fecha_hora_propuesta | DATETIME | NULL | "proponer una fecha y hora diferentes" (estado SUGERIDA) |
| estado | ENUM('PENDIENTE','SUGERIDA','ACEPTADA','RECHAZADA','CANCELADA','COMPLETADA') | NOT NULL, DEFAULT 'PENDIENTE' | los estados exactos del texto; "inicialmente en estado Pendiente" |
| motivo | TEXT | NULL | "el motivo por el cual fue rechazada o cancelada" |
| fecha_creacion | DATETIME | NOT NULL, DEFAULT NOW() | "la fecha de creación" |
| fecha_actualizacion | DATETIME | NOT NULL, DEFAULT NOW(), ON UPDATE NOW() | "la fecha de su última actualización" |
