# 01 – Modelo lógico: cómo se derivó SOLO del texto

> Guía de sustentación. Cada decisión de este documento nace de una frase
> exacta del *Universo del Discurso*. Si te preguntan "¿por qué esta tabla?",
> la respuesta es: léelo abajo.

---

## Metodología (los 5 pasos que se aplicaron)

1. **Subrayar sustantivos** → candidatos a entidades (tablas).
2. **Sustantivos modificados** → atributos (columnas) con su tipo de dato.
3. **Verbos y frases de relación** → cardinalidades (1:1, 1:N, N:M).
4. **Reglas de negocio explícitas** → restricciones, índices y decisiones de diseño.
5. **Prohibiciones explícitas** → lo que NO se modela (igual de importante).

---

## Paso 1 – Sustantivos → entidades

Del texto se extrajeron estos sustantivos relevantes:

| Frase del texto | Entidad creada |
|---|---|
| "dos tipos de usuarios: clientes y proveedores" | `usuarios`, `clientes`, `proveedores` |
| "un código de verificación de un solo uso o a un enlace temporal" | `recuperacion_contrasena` |
| "una dirección principal" / "dirección donde se prestará" | `direcciones` |
| "ciudades, barrios o sectores en los que prestan sus servicios" | `zonas_cobertura` |
| "catálogo de servicios" | `servicios` |
| "fotografías y videos de referencia" | `servicios_media` |
| "productos, insumos o equipos utilizados" | `servicios_insumos` |
| "horarios generales de disponibilidad" | `horarios_disponibilidad` |
| "fechas o periodos en los cuales no estará disponible" | `periodos_no_disponibilidad` |
| "solicitud" / "reserva" | `solicitudes` |

Sustantivos descartados como tabla (porque son atributos o no aportan):
- *barrio, sector, precio, duración, categoría, motivo, observaciones* → columnas.
- *reserva* como tabla aparte → ver decisión 4 abajo.

---

## Paso 2 – Sustantivos modificados → atributos

Ejemplos representativos (el detalle completo está en `diccionario_datos.md`):

- "duración estimada **en minutos**" → `duracion_minutos INT` (el "en minutos"
  del texto define la unidad, por eso no es un campo libre).
- "precio" → `precio DECIMAL(10,2)` (dinero: nunca FLOAT, pierde decimales).
- "estado, que permitirá identificar si el servicio se encuentra **activo o
  inactivo**" → `ENUM('ACTIVO','INACTIVO')`: el texto da exactamente los dos
  valores, un ENUM impide guardar cualquier otra cosa.
- "correo electrónico" → `email VARCHAR(120) UNIQUE` (el UNIQUE garantiza que
  dos cuentas no compartan correo, que es la credencial de login).
- "hash irreversible" → `password_hash VARCHAR(255)`: se guarda el hash (bcrypt),
  jamás la contraseña en texto plano.
- "fecha de creación, la fecha de su última actualización" →
  `fecha_creacion DATETIME DEFAULT CURRENT_TIMESTAMP` y
  `fecha_actualizacion DATETIME ... ON UPDATE CURRENT_TIMESTAMP`.

---

## Paso 3 – Verbos → cardinalidades

| Frase del texto | Relación |
|---|---|
| "Cada proveedor podrá administrar un catálogo de servicios" | PROVEEDOR 1:N SERVICIO |
| "Un servicio podrá tener asociadas fotografías y videos" | SERVICIO 1:N MEDIA |
| "los productos... utilizados para prestar cada servicio" | SERVICIO 1:N INSUMOS |
| "Cada proveedor podrá registrar sus horarios" | PROVEEDOR 1:N HORARIO |
| "también podrá registrar fechas o periodos... no disponible" | PROVEEDOR 1:N AUSENCIA |
| "Cuando un cliente desee solicitar un servicio deberá seleccionar el proveedor y el servicio" | CLIENTE N:1 ... PROVEEDOR N:1 ... SERVICIO N:1 sobre SOLICITUDES |
| "la dirección... podrá corresponder a su dirección principal o a una dirección diferente" | CLIENTE 1:N DIRECCIONES; SOLICITUDES N:1 DIRECCIONES |

**Clientes y proveedores son 1:1 con usuarios**, no N:1, porque un correo = una
cuenta = un tipo. Se resuelve con `PK = FK` (`clientes.usuario_id`), el patrón
clásico de herencia 1:1 en MySQL.

No hay relaciones N:M directas: "servicio ↔ insumo" es 1:N porque el insumo se
registra **por servicio** según el texto ("utilizados para prestar **cada**
servicio"), no es un catálogo global compartido.

---

## Paso 4 – Reglas de negocio → decisiones de diseño

### Decisión 1: tabla única `usuarios` con discriminador `tipo`
Texto: "manejar información de **dos tipos de usuarios**... cada usuario tendrá
los datos necesarios para su identificación y acceso".
Email, contraseña y recuperación son comunes a ambos → van en `usuarios`;
`tipo ENUM('CLIENTE','PROVEEDOR')` dice a qué perfil pertenece. Las tablas
`clientes` y `proveedores` guardan solo lo propio de cada uno.

### Decisión 2: snapshot del servicio en la solicitud
Texto: "Al crear la solicitud se deberá **conservar una copia** del nombre,
precio y duración del servicio seleccionado, de manera que las modificaciones
posteriores realizadas por el proveedor en su catálogo **no alteren** las
condiciones de las solicitudes o reservas creadas previamente."
→ Columnas `servicio_nombre`, `servicio_precio`, `servicio_duracion`. El
prefijo `servicio_` las agrupa y las distingue de las columnas propias de la
solicitud; el comentario en el DDL y este documento dejan claro que son la
**copia del catálogo al momento de crear la solicitud**, no una lectura viva de
la tabla `servicios`. Es una **desnormalización deliberada** y está
justificada por el enunciado. `servicio_id` se conserva igualmente como
referencia para poder mostrar el servicio actual si hace falta.

### Decisión 3: un solo campo `fecha_hora_inicio` + duración copiada
Texto: "Para determinar el periodo ocupado por una reserva se deberá considerar
la fecha y hora de inicio junto con la duración almacenada para el servicio."
→ El modelo NO guarda `fecha_fin`: se calcula (`inicio + servicio_duracion`).
Guardar el fin sería redundante y se desincronizaría si cambia.

### Decisión 4: solicitud y reserva son la misma tabla
Texto: "Toda solicitud se registrará inicialmente en estado Pendiente... cuando
una solicitud sea aceptada, se confirmará la prestación... Una reserva aceptada
podrá posteriormente marcarse como Completada".
El texto usa "solicitud" y "reserva" para el **mismo objeto en distintos
momentos de su ciclo de vida**, por eso existe una sola tabla `solicitudes` con
`estado ENUM(...)` que refleja en qué punto está:
`PENDIENTE → (SUGERIDA →) ACEPTADA → COMPLETADA | RECHAZADA | CANCELADA`.
Además, si existieran dos tablas, ¿cómo se migraría el registro y quién
garantizaría la transición? Con una sola tabla eso no es un problema.

### Decisión 5: NO hay historial de estados
Texto: "El sistema **no requiere** mantener un historial detallado de cada uno
de los cambios de estado por los que haya pasado una solicitud."
→ Un solo registro con `estado` actual. Si en el futuro lo pidieran, ahí sí se
agregaría una tabla de auditoría. Decir esto en la sustentación demuestra que
leíste las restricciones, no solo lo que "suena bien".

### Decisión 6: `fecha_hora_propuesta` nullable
Texto: "Cuando el proveedor proponga un horario diferente, la solicitud pasará
al estado Sugerida, y el cliente podrá aceptar o rechazar la propuesta."
→ La hora propuesta vive en la misma fila; solo se llena cuando
`estado = 'SUGERIDA'`. Al aceptarla, ese valor pasa a ser la hora definitiva.

### Decisión 7: un solo campo `motivo`
Texto: "cuando corresponda, el motivo por el cual fue **rechazada o cancelada**."
→ Una única columna `motivo TEXT NULL`, que se llena cuando el estado es
RECHAZADA o CANCELADA. En los demás estados queda NULL.

### Decisión 8: recuperación de contraseña invalidable
Texto: "código de verificación de un solo uso... vigencia e invalidación después
de ser utilizado o cuando se genere una nueva solicitud de recuperación."
→ `codigo UNIQUE` (un solo uso lógico), `fecha_expiracion` (vigencia),
`fecha_uso NULL` (NULL = sin usar). Una nueva solicitud invalida las anteriores
poniendo `fecha_uso` a las filas viejas. Todo esto se enforceará con **triggers
en la Entrega 2**.

### Decisión 9: zonas solo texto
Texto: "tendrán únicamente carácter orientativo, por lo que el sistema **no
realizará cálculos de distancia**... El proveedor será responsable de revisar
la dirección."
→ `zonas_cobertura` guarda `ciudad` y `barrio_sector` como VARCHAR. Sin
coordenadas, sin radio de cobertura, sin geolocalización. El texto prohíbe
expresamente esa funcionalidad.

---

## Paso 5 – Lo que NO se modeló (y hay que decirlo en la sustentación)

| Prohibido / innecesario en el texto | Consecuencia en el modelo |
|---|---|
| "no realizará cálculos de distancia" | sin coordenadas ni tablas geográficas |
| "no requiere mantener un historial detallado de cambios de estado" | sin tabla de auditoría/auditoría_estados |
| "no se deberán almacenar historias clínicas, diagnósticos, tratamientos ni otro tipo de información clínica" | ninguna tabla clínica; los servicios son de estética/masajes **no médicos** |
| "no contempla el desarrollo de una interfaz gráfica" | nada de tablas de UI/sesiones de navegador |
| "no deberá incorporar funcionalidades diferentes a las establecidas" | nada de carritos, pagos, reseñas, favoritos, mensajería... |

---

## Resumen de cardinalidades (para dibujar/leer el diagrama)

```
usuarios 1 ── 1 clientes 1 ── N direcciones
usuarios 1 ── 1 proveedores 1 ── N zonas_cobertura
                            1 ── N horarios_disponibilidad
                            1 ── N periodos_no_disponibilidad
                            1 ── N servicios 1 ── N servicios_media
                                               1 ── N servicios_insumos
usuarios 1 ── N recuperacion_contrasena

solicitudes N ── 1 clientes
solicitudes N ── 1 proveedores
solicitudes N ── 1 servicios   (más las copias snapshot en la propia fila)
solicitudes N ── 1 direcciones
```
