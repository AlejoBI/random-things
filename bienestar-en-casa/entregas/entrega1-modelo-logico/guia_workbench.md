# Guía: generar el modelo en MySQL Workbench (Entrega 1)

Objetivo: convertir `modelo_logico.sql` en un **diagrama ER** para entregar
(13/10/2026).

## 1. Tener MySQL Workbench instalado

Descarga desde <https://dev.mysql.com/downloads/workbench/> (la edición
Community es gratis). No necesita un servidor MySQL corriendo para generar el
diagrama.

## 2. Crear el modelo desde el script

1. Abrir Workbench → **Database ▸ Reverse Engineer...**
2. En *Connection* dejar el que haya (o **Store Connection...** si es la primera
   vez). Si no hay servidor, se puede cancelar el paso de conexión y en su
   lugar: **File ▸ Open Model...** no aplica aquí — para eso usamos el camino
   inverso (ver paso 3). *Si tienes servidor MySQL saltando: sigue el paso 2b.*
3. **2b (recomendado si tienes servidor):**
   - Crear una base de datos vacía en el servidor (phpMyAdmin o el propio
     Workbench: botón "create a new schema" → nombre `bienestar_en_casa`).
   - **Database ▸ Execute SQL Script...** → seleccionar `modelo_logico.sql`
     → ejecutar (Ctrl+Shift+Enter).
   - **Database ▸ Reverse Engineer...** → elegir ese schema → Finish.
     Workbench genera el modelo EER con las 12 tablas y relaciones.

## 3. Alternativa sin servidor MySQL (100% local)

1. **File ▸ New Model** (o Models en el panel izquierdo).
2. En *EER Diagram* → **Add Diagram**.
3. Crear las tablas a mano replicando `modelo_logico.sql`
   (doble clic en cada tabla → columna, tipo, PK/FK en las pestañas
   *Columns*, *Indexes*, *Foreign Keys*).
4. Para las FK: pestaña **Foreign Keys** → *Add*, elegir tabla referenciada y
   columna. Workbench dibuja automáticamente las líneas 1:N.

> Consejo: aunque se haga a mano, **siempre contrastar contra `modelo_logico.sql`**
> — ese archivo es la fuente de verdad.

## 4. Exportar el diagrama para entregar

1. Abrir el diagrama EER.
2. **File ▸ Export ▸ PDF** (o PNG con captura/ **File ▸ Export ▸ Image**).
3. Ajustar el layout si hace falta: seleccionar todo → usar el botón de
   "lay out tables" (el que reorganiza) para que no se solapen.
4. Guardar el archivo exportado en esta misma carpeta como `diagrama.pdf`.

## 5. Checklist antes de entregar

- [ ] 12 tablas visibles en el diagrama.
- [ ] Todas las FK con línea hacia su tabla padre (cardinalidades legibles).
- [ ] PK marcadas, UK de `usuarios.email` y `recuperacion_contrasena.codigo`.
- [ ] Los ENUM se ven como tipo en las columnas correspondientes.
- [ ] `diagrama.pdf` exportado en esta carpeta.
- [ ] Poder explicar (con `docs/01-modelo-logico.md`) de dónde salió cada tabla.

## Nota sobre Hackolade

El enunciado permite Hackolade **o** MySQL Workbench. Hackolade está pensado
principalmente para bases documentales (se usará más adelante). Para esta
entrega relacional, Workbench es la opción directa.
