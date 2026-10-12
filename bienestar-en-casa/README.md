# Bienestar en Casa – Sistema Web de Servicios de Estética y Bienestar a Domicilio

Proyecto final de base de datos: gestión de servicios de estética, bienestar y
masajes **no médicos** prestados a domicilio por profesionales independientes.

> Este repositorio contiene el desarrollo completo por entregas, con la
> explicación paso a paso de cómo se derivó cada decisión **solo a partir del
> universo del discurso**, para poder sustentar.

## Hitos del proyecto

| Semana | Fecha | Actividad | Estado |
|---|---|---|---|
| 10 | 13/10/2026 | **Entrega 1:** Modelo lógico (Hackolade o MySQL Workbench) | 🔄 en curso |
| 14 | 03/11/2026 | **Entrega 2:** BD relacional + triggers | ⬜ pendiente |
| 14 | 03/11/2026 | Sustentación (Modelado y Consultas SQL) | ⬜ pendiente |
| 16 | 17/11/2026 | **Entrega 3:** Modelado documental + backend básico y pruebas | ⬜ pendiente |
| 17 | 19/11/2026 | Sustentación (Modelado, Backend y Agregaciones) | ⬜ pendiente |

## Estructura

```
bienestar-en-casa/
├── README.md
├── docs/
│   ├── 01-modelo-logico.md        # metodología: del texto al modelo (guía de sustentación)
│   └── 02-guion-docente-mer-der.md # guion para explicarle MER/DER y el proceso
└── entregas/
    └── entrega1-modelo-logico/
        ├── guia_xampp.md          # instalar/arrancar XAMPP, importar y validar la BD
        ├── modelo_logico.sql      # DDL completo – fuente de verdad
        ├── diccionario_datos.md   # cada columna: tipo + frase del texto que la justifica
        ├── guia_workbench.md      # conectar Workbench a XAMPP y exportar el diagrama
        └── diagrama.pdf           # (a exportar)
```

## Entorno de trabajo

El proyecto se trabaja sobre **XAMPP** (MySQL/MariaDB + phpMyAdmin + Apache) y el
diagrama del modelo lógico se genera con **MySQL Workbench** conectado a la base
de XAMPP. Guías paso a paso: `guia_xampp.md` y `guia_workbench.md`.

## Cómo se usó este material para sustentar

1. **`docs/01-modelo-logico.md`** explica los 5 pasos de la metodología
   (sustantivos → entidades, modificadores → atributos, verbos →
   cardinalidades, reglas → decisiones, prohibiciones → lo que NO se modeló).
2. **`docs/02-guion-docente-mer-der.md`** es el guion para dar clase: qué es un
   dato, MER vs DER, los 3 niveles del modelo, los elementos del MER con
   ejemplos del proyecto, y las reglas de transformación al modelo relacional.
3. **`diccionario_datos.md`** es la referencia rápida "¿por qué esta columna?":
   cada una cita la frase exacta del universo del discurso.
4. **`modelo_logico.sql`** es el modelo en sí; de ahí se genera el diagrama
   con la guía de Workbench.

## Reglas del negocio que nunca se pierden de vista

- Snapshot de nombre/precio/duración en cada solicitud (el catálogo puede
  cambiar después).
- Estado actual de la solicitud con su `motivo` cuando aplica — **sin**
  historial de cambios (el texto lo exige así).
- Cero información clínica: sin historias clínicas, diagnósticos ni tratamientos.
- Zonas de cobertura solo como texto orientativo: **sin** cálculos de distancia.
- Contraseñas con hash irreversible + códigos de recuperación de un solo uso
  con vigencia.
