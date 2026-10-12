# Guía: instalar y usar XAMPP (entorno del proyecto)

XAMPP es el entorno que usamos para este proyecto. Instala de una sola vez:

| Componente | Para qué lo usamos aquí |
|---|---|
| **MySQL / MariaDB** | el motor de base de datos del proyecto |
| **phpMyAdmin** | interfaz web para importar el script y ejecutar consultas |
| **Apache** | servidor web que sirve a phpMyAdmin (y más adelante al backend) |
| PHP | necesario para que phpMyAdmin funcione |

> Nota: XAMPP trae **MariaDB**, que es compatible con MySQL. Los scripts, triggers
> y consultas del proyecto funcionan igual.

---

## 1. Descargar e instalar

1. Ir a <https://www.apachefriends.org/> → descargar **XAMPP para Windows**.
2. Ejecutar el instalador. Seleccionar al menos: **Apache, MySQL, PHP, phpMyAdmin**.
3. Instalarlo en una ruta **sin espacios ni tildes**, por ejemplo `C:\xampp`
   (evita problemas de permisos y rutas).
4. Al terminar, dejar marcado "Do you want to start the Control Panel now?".

## 2. Arrancar los servicios

1. Abrir el **XAMPP Control Panel**.
2. Pulsar **Start** en **Apache** y en **MySQL**.
3. Los dos deben quedar en **verde**. Los puertos por defecto son:
   - Apache: `80` (y `443`)
   - MySQL: `3306` ← este es el que usará el proyecto.
4. Verificar en el navegador: <http://localhost/phpmyadmin> debe abrir sin error.

> Si Apache no arranca, casi siempre es porque el puerto 80 está ocupado
> (Skype, IIS, otro servidor). En el Control Panel → **Config ▸ Service and
> Port Settings** se puede cambiar el puerto.

## 3. Ver la base de datos

Introducción solo informativa: al entrar a phpMyAdmin verás las bases por
defecto (`information_schema`, `mysql`, `performance_schema`, `phpmyadmin`).
La nuestra todavía no existe.

## 4. Importar `modelo_logico.sql` (crea toda la base de datos)

1. phpMyAdmin → pestaña **Import** (Importar).
2. **Choose File** → seleccionar `entrega1-modelo-logico/modelo_logico.sql`.
3. Dejar el resto por defecto y pulsar **Import** (Continuar).
4. El script hace `CREATE DATABASE bienestar_en_casa` y `USE ...`, así que **no
   hace falta crear la base a mano**.

Resultado esperado: en el panel izquierdo aparece **`bienestar_en_casa`** con
**12 tablas**:

```
clientes, direcciones, horarios_disponibilidad, periodos_no_disponibilidad,
proveedores, recuperacion_contrasena, servicios, servicios_insumos,
servicios_media, solicitudes, usuarios, zonas_cobertura
```

## 5. Validar que todo quedó bien

Cada paso es un clic; sirve para confirmar antes de la entrega:

1. Clic en `bienestar_en_casa` → pestaña **Structure** → contar 12 tablas.
2. Pestaña **SQL** y ejecutar una consulta de prueba, por ejemplo:

```sql
SHOW TABLES;
```

3. Verificar que una tabla quedó completa, por ejemplo:

```sql
DESCRIBE solicitudes;
```

4. Verificar las relaciones (FK) creadas:

```sql
SELECT TABLE_NAME, COLUMN_NAME, REFERENCED_TABLE_NAME, REFERENCED_COLUMN_NAME
FROM information_schema.KEY_COLUMN_USAGE
WHERE TABLE_SCHEMA = 'bienestar_en_casa'
  AND REFERENCED_TABLE_NAME IS NOT NULL;
```

Si no hay errores y las tablas/FK aparecen, **el modelo lógico está validado**.

## 6. Ejecutar consultas del proyecto

phpMyAdmin → seleccionar `bienestar_en_casa` → pestaña **SQL** → pegar la
consulta → **Go / Continuar**. Ahí se practican las consultas que se
sustentarán el **07/10** (búsquedas por nombre/categoría, disponibilidad,
solicitudes por estado, etc.).

## 7. Errores frecuentes y solución

| Síntoma | Causa probable | Solución |
|---|---|---|
| Apache no arranca (puerto 80 ocupado) | Skype/IIS/otro web server | cambiar puerto en Config ▸ Service and Port Settings |
| MySQL no arranca (puerto 3306 ocupado) | ya hay otro MySQL/MariaDB instalado o corriendo | detener el otro servicio (services.msc) o cambiar el puerto |
| `#1046 No database selected` al importar | se ejecutó un fragmento sin `USE` | importar el script completo, que ya trae `USE bienestar_en_casa` |
| No puedo entrar a phpMyAdmin por contraseña | se activó password de root en MySQL | usar la contraseña configurada en **Security**, o restaurar sin password |
| `#1050 Table already exists` al reimportar | se ejecutó dos veces | el script usa `CREATE DATABASE IF NOT EXISTS`, pero no `DROP TABLE`; borrar la base y volver a importar |

## 8. Siguiente paso: el diagrama

Con MySQL corriendo en XAMPP, el diagrama se generó con **MySQL Workbench**
conectándose a ese servidor. Ver `guia_workbench.md`.

## Desinstalar / limpiar

Para reiniciar de cero: phpMyAdmin → `bienestar_en_casa` → pestaña
**Operations** → *Drop the database*, y volver a importar el script.
