# Guía: generar el modelo en MySQL Workbench (Entrega 1)

Objetivo: convertir `modelo_logico.sql` en un **diagrama ER** para entregar
(13/10/2026).

> Requisito previo: el servidor MySQL de **XAMPP** corriendo y la base
> `bienestar_en_casa` importada. Si no lo tienes, sigue primero `guia_xampp.md`.

## 1. Tener MySQL Workbench instalado

Descarga desde <https://dev.mysql.com/downloads/workbench/> (la edición
Community es gratis). Workbench **no** trae servidor: se conecta al MySQL que
ya está en marcha en XAMPP (puerto `3306`).

## 2. Conectar Workbench al MySQL de XAMPP (una sola vez)

1. Abrir Workbench → en la pantalla de inicio, **MySQL Connections** → `+`.
2. Llenar:
   - **Connection Name:** `XAMPP` (o el nombre que quieras)
   - **Hostname:** `127.0.0.1`   **Port:** `3306`
   - **Username:** `root`
   - **Password:** vacío (por defecto en XAMPP) o la que hayas puesto en
     phpMyAdmin ▸ Security.
3. **Test Connection** → debe decir *Successfully made the MySQL connection*.
   Si falla, revisar que MySQL esté verde en el XAMPP Control Panel (ver
   solución de puertos en `guia_xampp.md` §7).

## 3. Generar el diagrama desde el script (Reverse Engineer)

1. Abrir la conexión `XAMPP`.
2. **Database ▸ Reverse Engineer...** → Next.
3. Confirmar la conexión → Next.
4. Elegir el schema **`bienestar_en_casa`** → Next → Next → **Execute**.
5. Workbench genera el modelo EER con las 12 tablas y sus relaciones.
   Guardarlo con **File ▸ Save Model As...** (por ejemplo `modelo.mwb`).

## 4. Alternativa sin servidor MySQL (100% local)

1. **File ▸ New Model** (o Models en el panel izquierdo).
2. En *EER Diagram* → **Add Diagram**.
3. Crear las tablas a mano replicando `modelo_logico.sql`
   (doble clic en cada tabla → columna, tipo, PK/FK en las pestañas
   *Columns*, *Indexes*, *Foreign Keys*).
4. Para las FK: pestaña **Foreign Keys** → *Add*, elegir tabla referenciada y
   columna. Workbench dibuja automáticamente las líneas 1:N.

> Consejo: aunque se haga a mano, **siempre contrastar contra `modelo_logico.sql`**
> — ese archivo es la fuente de verdad. Con XAMPP ya instalado, lo normal es usar
> el Reverse Engineer (sección 3) y no este camino manual.

## 5. Exportar el diagrama para entregar

1. Abrir el diagrama EER.
2. **File ▸ Export ▸ PDF** (o PNG con captura/ **File ▸ Export ▸ Image**).
3. Ajustar el layout si hace falta: seleccionar todo → usar el botón de
   "lay out tables" (el que reorganiza) para que no se solapen.
4. Guardar el archivo exportado en esta misma carpeta como `diagrama.pdf`.

## 6. Checklist antes de entregar

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
