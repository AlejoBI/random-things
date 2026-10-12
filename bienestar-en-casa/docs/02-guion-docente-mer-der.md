# Guion docente — Del texto al MER/DER (y de ahí al modelo relacional)

> **Para quién es este documento:** para ti, que le vas a explicar.
> **Cómo usarlo:** bloques de ~5–15 minutos. Los ejemplos salen del propio
> proyecto (Bienestar en Casa), así que no hay que inventar nada: todo se
> encadena con lo que ya está en `docs/01-modelo-logico.md` y en
> `entregas/entrega1-modelo-logico/`.
>
> Duración total sugerida: **3 sesiones de 45–60 min**, o 1 sesión larga de 2 h.

---

## Bloque 0 — Encuadre (2 min)

Dile esto para abrir:

> "Antes de escribir una sola línea de SQL, vamos a hacer lo mismo que un
> arquitecto: primero el plano. Ese plano es el **modelo**. Y ese modelo no sale
> de la imaginación: sale del texto del proyecto, letra por letra. Hoy
> aprendemos a leer el texto y convertirlo en un modelo. Después ese modelo se
> convierte en tablas."

Objetivo de la clase, en una frase: **entender de dónde salen las tablas y por
qué son esas y no otras.**

---

## Bloque 1 — De los datos a la base de datos (5 min)

Encadenar conceptos en este orden, con ejemplos del proyecto:

| Concepto | Definición sencilla | Ejemplo del proyecto |
|---|---|---|
| **Dato** | Un valor suelto, sin contexto | `"25000"`, `"Laura"` |
| **Información** | Datos con contexto y significado | "El servicio *Masaje relajante* de Laura cuesta $25.000" |
| **Base de datos** | Colección organizada de datos que se puede consultar y mantener | Toda la tabla `servicios` |
| **SGBD** | El software que crea y administra la base de datos | MySQL / MariaDB (el de XAMPP) |
| **Modelo de datos** | La descripción de **qué** información guardamos y **cómo** se relaciona, antes de programar | el modelo que estamos haciendo |

Regla clave que debe memorizar: **el modelo describe la realidad del negocio,
no la tecnología. Por eso todavía no hablamos de tablas ni de columnas.**

---

## Bloque 2 — Los 3 niveles del modelo (7 min)

Esta es la parte que más se confunde y la que el docente seguramente va a
preguntar. Explica los tres niveles con la analogía de construir una casa:

| Nivel | Nombre | ¿Qué representa? | Analogía | Herramienta |
|---|---|---|---|---|
| **Conceptual** | **MER** (modelo entidad-relación) | Qué entidades existen y cómo se relacionan, sin pensar en el motor | El diseño "a mano alzada" con el cliente: "quiero 3 cuartos y 2 baños" | papel, draw.io, pizarra |
| **Lógico** | Modelo relacional | Cómo se representará en tablas relacionales: PK, FK, tipos | El plano técnico con medidas | MySQL Workbench, Hackolade |
| **Físico** | Modelo físico | El SQL exacto para el motor concreto (tipos, índices, charset) | Los materiales concretos de obra | `modelo_logico.sql` |

> Frase para decirle: *"El MER es el 'qué'; el modelo lógico es el 'cómo';
> el físico es el 'cómo lo ejecuto en MySQL'. Nosotros pasamos por los tres,
> pero el proyecto pide entregar el **lógico**."*

---

## Bloque 3 — MER vs DER: la pregunta directa (5 min)

Ella debe poder responder esto de memoria. Explicación:

- **MER (Modelo Entidad-Relación):** es el **modelo conceptual** propuesto por
  Peter Chen (1976). Describe el negocio mediante **entidades, atributos y
  relaciones**. Es una forma de *pensar* el problema, independiente de cualquier
  base de datos.
- **DER (Diagrama Entidad-Relación):** es la **representación gráfica** de ese
  modelo. Es el dibujo del MER: rectángulos para entidades, óvalos/dentro del
  rectángulo para atributos, rombos o líneas para las relaciones.

**La diferencia, en una frase:**
> El **MER es el modelo** (conceptos, ideas, reglas).
> El **DER es el dibujo** del modelo (la notación gráfica).
> Es la diferencia entre el plano mental y el plano impreso.

**Advertencias para que no se trabe:**

1. En la práctica la gente usa "MER" y "DER" **como sinónimos**. Si el docente
   usa uno u otro, no hay que corregirlo: se entiende por contexto.
2. Existe también el **EER (Enhanced/Extendido ER)**, que agrega conceptos como
   generalización/especialización y entidades débiles. **MySQL Workbench usa
   notación EER** (por eso el informe dice "EER Diagram").
3. A partir del **modelo lógico** ya hablamos de **tablas, PK y FK**, no de
   entidades/relaciones. Ojo con mezclar los términos:
   - Conceptual (MER): **entidad**, **relación**, **cardinalidad**.
   - Lógico/relacional: **tabla**, **columna**, **clave primaria (PK)**,
     **clave foránea (FK)**.

Tabla resumen que puedes dejarle escrita:

| Pregunta | MER / DER (conceptual) | Modelo relacional (lógico) |
|---|---|---|
| ¿Qué usa? | entidades y relaciones | tablas y columnas |
| ¿Depende del motor? | No | Sí (MySQL, aunque es estándar) |
| ¿Tiene tipos de dato? | No (solo conceptualmente) | Sí (`INT`, `VARCHAR`, `DECIMAL`...) |
| ¿Relación M:N? | Sí, se dibuja directo | Se convierte en **tabla intermedia** |
| Herramienta | papel / Workbench EER / draw.io | Workbench, Hackolade |

---

## Bloque 4 — Los elementos del MER, con ejemplos del proyecto (15 min)

Explica cada concepto y **de inmediato** da su ejemplo del proyecto. Esa es la
técnica: concepto → ejemplo real del texto.

### 4.1 Entidad
> "Un objeto del mundo real sobre el que guardo información."
- Ejemplos: **Usuario, Servicio, Solicitud, Proveedor, Cliente**.

### 4.2 Atributo
> "Una característica de la entidad."
- De `Servicio`: nombre, categoría, precio, duración, estado.

Tipos de atributos (menciónalos porque suelen preguntar):

| Tipo | Qué es | Ejemplo del proyecto |
|---|---|---|
| Simple/atómico | un solo valor | `precio` |
| Compuesto | se puede dividir | dirección (calle, número, ciudad) |
| **Multivaluado** | varios valores del mismo atributo | teléfonos, fotos de un servicio |
| Derivado | se calcula de otro | *edad* (de fecha de nacimiento); el **periodo de una reserva** (inicio + duración) |
| Clave | identifica unívocamente | `email` en usuarios, `id` en cada tabla |

### 4.3 Clave (PK / identificador)
> "El atributo que no se repite y que identifica cada registro."
- En `usuarios`: `id` (surrogate) y `email` (natural, único).
- Enséñale que es normal tener **ambas**: un id técnico y el dato único real.

### 4.4 Relación
> "Un vínculo entre dos entidades."
- `Proveedor` **ofrece** `Servicios`.
- `Cliente` **solicita** un `Servicio` a un `Proveedor`.
- Dale a cada relación un **verbo**; el verbo orienta la cardinalidad.

### 4.5 Cardinalidad
> "Cuántas instancias de una entidad se relacionan con la otra."

Explica los tres casos con ejemplos del proyecto. Insiste en **leer la frase del
texto** para decidir:

| Cardinalidad | Lectura | Ejemplo del proyecto |
|---|---|---|
| **1:1** | uno con uno | Un usuario es **un** cliente (o **un** proveedor), no los dos |
| **1:N** | uno con muchos | Un proveedor tiene **muchos** servicios |
| **M:N** | muchos con muchos | Un servicio podría ser ofrecido por varios proveedores **y** un proveedor ofrecer varios → *típicamente M:N* |

> Nota fina para el proyecto: *quién* controla la pertenencia del servicio
> define si es 1:N o M:N. En este enunciado, "cada proveedor administra **su**
> catálogo" ⇒ **1:N** (el servicio pertenece a un proveedor). Este es un ejemplo
> perfecto de que **el texto decide el modelo, no la intuición.**

### 4.6 Participación (opcional / total vs parcial)
- Un proveedor **sin** servicios: ¿existe? Sí (se registra y luego arma catálogo)
  ⇒ participación **parcial**.
- Una solicitud **siempre** tiene un servicio ⇒ participación **total**.

### 4.7 Entidad débil (mención)
- `servicios_media` no tiene sentido sin su `servicio_id`: depende de `servicios`.
  Eso es una entidad débil (su clave incluye la del padre). Aquí la resolvimos
  con una FK + `id` propio, que es lo estándar en el modelo relacional.

### 4.8 Generalización/Especialización (ISA)
- **Usuario** es el concepto general; **Cliente** y **Proveedor** son
  especializaciones. Se lee como "un Cliente **es un** Usuario".
- Esto justifica directamente la tabla `usuarios` + `clientes`/`proveedores`
  en 1:1. Enlázalo con la Decisión 1 de `docs/01-modelo-logico.md`.

### 4.9 Notaciones gráficas (para que no se asuste al ver el diagrama)

| Notación | Cómo dibuja | Dónde la verás |
|---|---|---|
| **Chen** | rectángulos, rombos, óvalos | libros y clases teóricas |
| **Pata de gallo (crow's foot)** | líneas con símbolos en los extremos | MySQL Workbench (**nuestro caso**) |

Símbolos de pata de gallo que debe reconocer:
- `|—` = uno
- `—<` (pata) = muchos
- `|—<` = uno a muchos.

---

## Bloque 5 — Del texto al MER, paso a paso (10 min)

Aquí no explicas teoría: **lo haces con ella**. Toma un párrafo del enunciado y
construyan juntos. Usen el método de 5 pasos (está en `docs/01-modelo-logico.md`):

> **Frases a subrayar:**
> 1. sustantivos → **entidades**
> 2. palabras que describen al sustantivo → **atributos**
> 3. verbos ("ofrece", "solicita", "registra") → **relaciones**
> 4. reglas explícitas ("conservar una copia...") → **decisiones de diseño**
> 5. prohibiciones ("no se almacenarán datos clínicos") → **lo que NO se modela**

**Ejemplo guiado en vivo (párrafo del catálogo):**

> *"Cada proveedor podrá administrar un catálogo de servicios. Para cada servicio
> se deberá registrar su nombre, categoría, descripción, duración estimada en
> minutos, precio y estado... Un servicio podrá tener asociadas fotografías y
> videos... También se podrán registrar los productos, insumos o equipos
> utilizados."*

Construyan:

1. Sustantivos: `proveedor`, `catálogo`, `servicio`, `nombre`, `categoría`,
   `descripción`, `duración`, `precio`, `estado`, `fotografías`, `videos`,
   `productos`, `insumos`, `equipos`.
2. Entidades (los que tienen vida propia): **Proveedor**, **Servicio**,
   **Media**, **Insumo**. Los demás son atributos.
3. Atributos de Servicio: nombre, categoría, descripción, duración_minutos,
   precio, estado.
4. Relación: Proveedor **1:N** Servicio ("cada proveedor administra un catálogo").
   Servicio **1:N** Media. Servicio **1:N** Insumo ("utilizados para prestar
   **cada** servicio").
5. Regla: "duración estimada **en minutos**" ⇒ el atributo nace con unidad y
   tipo (`INT`).

> Cierre del bloque: "¿Ves? No inventamos nada. Cada tabla tiene su frase."

---

## Bloque 6 — Del MER al modelo relacional: reglas de transformación (15 min)

Este bloque conecta el concepto con **el script que se va a entregar**. Estas
son las reglas y su aplicación concreta:

| Regla | Enunciado | Aplicación en el proyecto |
|---|---|---|
| **1. Entidad → tabla** | cada entidad se vuelve una tabla | Proveedor → `proveedores` |
| **2. Atributo simple → columna** | con su tipo | duración en minutos → `duracion_minutos INT` |
| **3. Atributo multivaluado → tabla aparte** | porque una columna guarda un solo valor | fotos/videos → `servicios_media` |
| **4. Relación 1:N → FK en el lado "muchos"** | la clave del "1" viaja al "N" | `servicios.proveedor_id` |
| **5. Relación M:N → tabla intermedia** | con las PK de ambos | (en este proyecto no hay M:N puras; si apareciera, se crearía) |
| **6. Generalización → tabla general + tablas específicas** | la PK se comparte | `usuarios` + `clientes`/`proveedores` con PK=FK |
| **7. Entidad débil → depende del padre** | FK obligatoria | `solicitudes.direccion_id`, `servicios_media.servicio_id` |

**Cierra con la conexión al entregable:**
> "Cada regla de esta tabla ya está aplicada en `modelo_logico.sql`. Cuando el
> docente pregunte '¿por qué existe esta FK?', respondes: por la regla 4."

Y enlaza las **decisiones especiales** del proyecto (que no son reglas generales
sino exigencias del texto):
- snapshot de `servicio_nombre`, `servicio_precio`, `servicio_duracion`
  → porque el texto manda "conservar una copia";
- sin `fecha_fin` → porque se calcula (inicio + duración);
- `motivo` único para rechazo/cancelación → porque el texto lo pide "cuando
  corresponda";
- sin tabla de historial de estados → por prohibición expresa;
- sin coordenadas geográficas → por prohibición expresa.

---

## Bloque 7 — Manos a la obra en MySQL Workbench (10 min)

Guía operativa (el detalle está en `guia_workbench.md`):

1. Arrancar XAMPP e importar `modelo_logico.sql` en phpMyAdmin
   (ver `guia_xampp.md`).
2. Abrir Workbench y conectarse al MySQL de XAMPP (`127.0.0.1:3306`, `root`).
3. **Database ▸ Reverse Engineer** → elegir `bienestar_en_casa`.
4. Workbench dibuja el **EER** (el DER) con las 12 tablas.
5. **File ▸ Export ▸ PDF** → guardar como `diagrama.pdf`.

> Explícale el porqué de "Reverse Engineer": tomamos el modelo físico (el SQL)
> y lo dibujamos hacia atrás para obtener el diagrama. Es el camino inverso, y
> es válido porque **el script es la fuente de verdad**.

---

## Bloque 8 — Ensayo de preguntas (10 min)

Hazle estas preguntas y que responda con sus palabras. Las respuestas están en
`docs/01-modelo-logico.md` y `diccionario_datos.md`:

1. ¿Cuál es la diferencia entre MER y DER?
2. ¿Por qué `clientes` y `proveedores` están separadas de `usuarios`?
3. ¿Por qué hay columnas `servicio_nombre`, `servicio_precio` y
   `servicio_duracion` si ya existe `servicio_id`?
4. ¿Por qué no existe una columna `fecha_fin` en `solicitudes`?
5. ¿Por qué no hay una tabla de historial de estados?
6. ¿Por qué `zonas_cobertura` guarda texto y no coordenadas?
7. ¿Qué tipo de dato usarías para el precio y por qué no `FLOAT`?
8. ¿Cuál es la cardinalidad entre proveedor y servicio y por qué?
9. ¿Qué información **no** se debe almacenar nunca en este sistema?
10. ¿Qué diferencia hay entre el modelo conceptual, lógico y físico?

---

## Bloque 9 — Cierre y enlace con lo entregado (3 min)

> "Lo que acabamos de hacer es el camino completo: **texto → MER → modelo
> lógico → script SQL → diagrama**. Todo lo que te voy a entregar es una foto de
> una etapa de ese camino."

Mapa de entregables ↔ etapas:

| Etapa | Archivo entregado |
|---|---|
| Metodología (texto → modelo) | `docs/01-modelo-logico.md` |
| Modelo lógico en sí | `entregas/entrega1-modelo-logico/modelo_logico.sql` |
| Justificación de cada columna | `entregas/entrega1-modelo-logico/diccionario_datos.md` |
| Entorno | `entregas/entrega1-modelo-logico/guia_xampp.md` |
| Diagrama (DER) | `entregas/entrega1-modelo-logico/guia_workbench.md` → `diagrama.pdf` |
| Este guion | `docs/02-guion-docente-mer-der.md` |

Checklist final para ella antes de sustentar:
- [ ] Explica MER vs DER con una frase propia.
- [ ] Nombra los 3 niveles de modelo.
- [ ] Recita las reglas de transformación MER → relacional.
- [ ] Justifica 5 decisiones de diseño citando el texto.
- [ ] Sabe qué NO se modeló y por qué.
- [ ] Abre XAMPP, phpMyAdmin y Workbench sin ayuda.
