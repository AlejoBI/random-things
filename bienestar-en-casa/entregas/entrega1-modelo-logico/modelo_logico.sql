-- ============================================================================
-- Bienestar en Casa – Sistema Web de Servicios de Estética y Bienestar a Domicilio
-- Entrega 1: Modelo lógico de la base de datos (MySQL Workbench)
-- ----------------------------------------------------------------------------
-- Este script ES la fuente de verdad del modelo. Con él se genera el diagrama:
--   Database > Reverse Engineer... en MySQL Workbench.
-- ============================================================================

CREATE DATABASE IF NOT EXISTS bienestar_en_casa
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE bienestar_en_casa;

-- ============================================================================
-- BLOQUE 1 – Identificación y acceso
-- Texto: "El sistema deberá manejar información de dos tipos de usuarios:
--         clientes y proveedores. Cada usuario tendrá los datos necesarios
--         para su identificación y acceso al sistema... correo electrónico y
--         una contraseña... hash irreversible... código de verificación de un
--         solo uso o a enlace temporal."
-- ============================================================================

CREATE TABLE usuarios (
  id              INT             NOT NULL AUTO_INCREMENT,
  email           VARCHAR(120)    NOT NULL,
  password_hash   VARCHAR(255)    NOT NULL,           -- hash irreversible (bcrypt), nunca texto plano
  tipo            ENUM('CLIENTE','PROVEEDOR') NOT NULL, -- discriminador de la relación 1:1
  nombre          VARCHAR(100)    NOT NULL,
  telefono        VARCHAR(20)     NULL,
  fecha_registro  DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_usuarios_email (email)
) ENGINE=InnoDB;

-- Texto: "un código de verificación de un solo uso... considerando su vigencia
--         e invalidación después de ser utilizado o cuando se genere una nueva
--         solicitud de recuperación."
CREATE TABLE recuperacion_contrasena (
  id                INT           NOT NULL AUTO_INCREMENT,
  usuario_id        INT           NOT NULL,
  codigo            VARCHAR(20)   NOT NULL,           -- valor del código o enlace de un solo uso
  fecha_expiracion  DATETIME      NOT NULL,           -- vigencia del código
  fecha_uso         DATETIME      NULL,               -- NULL = sin usar; al setearse, el código queda invalidado
  fecha_creacion    DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_recuperacion_codigo (codigo),
  CONSTRAINT fk_recuperacion_usuario
    FOREIGN KEY (usuario_id) REFERENCES usuarios (id)
    ON DELETE CASCADE
) ENGINE=InnoDB;

-- ============================================================================
-- BLOQUE 2 – Perfiles extendidos (relación 1:1 con usuarios)
-- Texto: "Los clientes podrán registrar sus datos personales y una dirección
--         principal, mientras que los proveedores contarán con un perfil
--         profesional..."
-- Decisión: usuarios es la tabla única de credenciales; clientes y proveedores
--           la extienden en 1:1 (PK = FK) para no duplicar email/contraseña.
-- ============================================================================

CREATE TABLE clientes (
  usuario_id  INT NOT NULL,
  PRIMARY KEY (usuario_id),
  CONSTRAINT fk_clientes_usuario
    FOREIGN KEY (usuario_id) REFERENCES usuarios (id)
    ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE proveedores (
  usuario_id         INT NOT NULL,
  biografia          TEXT    NULL,                     -- perfil profesional
  anios_experiencia  INT     NULL,
  PRIMARY KEY (usuario_id),
  CONSTRAINT fk_proveedores_usuario
    FOREIGN KEY (usuario_id) REFERENCES usuarios (id)
    ON DELETE CASCADE
) ENGINE=InnoDB;

-- ============================================================================
-- BLOQUE 3 – Direcciones del cliente y zonas del proveedor
-- Texto: "una dirección principal" ... "La dirección donde se prestará el
--         servicio, que podrá corresponder a su dirección principal o a una
--         dirección diferente" ... "ciudades, barrios o sectores en los que
--         prestan sus servicios."
-- Texto (restricción): "Las zonas de atención... tendrán únicamente carácter
--         orientativo, por lo que el sistema no realizará cálculos de
--         distancia" -> solo texto, sin coordenadas.
-- ============================================================================

CREATE TABLE direcciones (
  id            INT           NOT NULL AUTO_INCREMENT,
  cliente_id    INT           NOT NULL,
  ciudad        VARCHAR(80)   NOT NULL,
  barrio        VARCHAR(80)   NULL,
  calle         VARCHAR(120)  NOT NULL,
  numero        VARCHAR(20)   NULL,
  referencia    TEXT          NULL,                    -- información complementaria para localizar el lugar
  es_principal  BOOLEAN       NOT NULL DEFAULT FALSE,
  PRIMARY KEY (id),
  CONSTRAINT fk_direcciones_cliente
    FOREIGN KEY (cliente_id) REFERENCES clientes (usuario_id)
    ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE zonas_cobertura (
  id             INT           NOT NULL AUTO_INCREMENT,
  proveedor_id   INT           NOT NULL,
  ciudad         VARCHAR(80)   NOT NULL,
  barrio_sector  VARCHAR(100)  NULL,
  PRIMARY KEY (id),
  CONSTRAINT fk_zonas_proveedor
    FOREIGN KEY (proveedor_id) REFERENCES proveedores (usuario_id)
    ON DELETE CASCADE
) ENGINE=InnoDB;

-- ============================================================================
-- BLOQUE 4 – Catálogo de servicios del proveedor
-- Texto: "nombre, categoría, descripción, duración estimada en minutos,
--         precio y estado... fotografías y videos de referencia... productos,
--         insumos o equipos utilizados para prestar cada servicio."
-- ============================================================================

CREATE TABLE servicios (
  id                INT             NOT NULL AUTO_INCREMENT,
  proveedor_id      INT             NOT NULL,
  nombre            VARCHAR(100)    NOT NULL,
  categoria         VARCHAR(80)     NOT NULL,
  descripcion       TEXT            NULL,
  duracion_minutos  INT             NOT NULL,
  precio            DECIMAL(10,2)   NOT NULL,
  estado            ENUM('ACTIVO','INACTIVO') NOT NULL DEFAULT 'ACTIVO',
  PRIMARY KEY (id),
  KEY idx_servicios_busqueda (nombre, categoria),      -- búsquedas por nombre o categoría
  CONSTRAINT fk_servicios_proveedor
    FOREIGN KEY (proveedor_id) REFERENCES proveedores (usuario_id)
    ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE servicios_media (
  id           INT            NOT NULL AUTO_INCREMENT,
  servicio_id  INT            NOT NULL,
  tipo         ENUM('FOTO','VIDEO') NOT NULL,
  url          VARCHAR(500)   NOT NULL,
  orden        TINYINT        NOT NULL DEFAULT 0,
  PRIMARY KEY (id),
  CONSTRAINT fk_media_servicio
    FOREIGN KEY (servicio_id) REFERENCES servicios (id)
    ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE servicios_insumos (
  id           INT             NOT NULL AUTO_INCREMENT,
  servicio_id  INT             NOT NULL,
  tipo         ENUM('PRODUCTO','INSUMO','EQUIPO') NOT NULL,
  nombre       VARCHAR(150)    NOT NULL,
  descripcion  TEXT            NULL,
  PRIMARY KEY (id),
  CONSTRAINT fk_insumos_servicio
    FOREIGN KEY (servicio_id) REFERENCES servicios (id)
    ON DELETE CASCADE
) ENGINE=InnoDB;

-- ============================================================================
-- BLOQUE 5 – Disponibilidad del proveedor
-- Texto: "días en los que presta atención y las horas de inicio y finalización
--         correspondientes. También podrá registrar fechas o periodos en los
--         cuales no estará disponible."
-- ============================================================================

CREATE TABLE horarios_disponibilidad (
  id             INT           NOT NULL AUTO_INCREMENT,
  proveedor_id   INT           NOT NULL,
  dia_semana     ENUM('LUNES','MARTES','MIERCOLES','JUEVES','VIERNES','SABADO','DOMINGO') NOT NULL,
  hora_inicio    TIME          NOT NULL,
  hora_fin       TIME          NOT NULL,
  PRIMARY KEY (id),
  KEY idx_horarios_proveedor_dia (proveedor_id, dia_semana),
  CONSTRAINT fk_horarios_proveedor
    FOREIGN KEY (proveedor_id) REFERENCES proveedores (usuario_id)
    ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE periodos_no_disponibilidad (
  id             INT           NOT NULL AUTO_INCREMENT,
  proveedor_id   INT           NOT NULL,
  fecha_inicio   DATETIME      NOT NULL,
  fecha_fin      DATETIME      NOT NULL,
  motivo         VARCHAR(200)  NULL,
  PRIMARY KEY (id),
  KEY idx_ausencias_proveedor (proveedor_id, fecha_inicio, fecha_fin),
  CONSTRAINT fk_ausencias_proveedor
    FOREIGN KEY (proveedor_id) REFERENCES proveedores (usuario_id)
    ON DELETE CASCADE
) ENGINE=InnoDB;

-- ============================================================================
-- BLOQUE 6 – Solicitudes / Reservas
-- Texto: "conservar una copia del nombre, precio y duración del servicio...
--         estado Pendiente... Sugerida... Aceptada... Rechazada... Cancelada...
--         Completada... el motivo por el cual fue rechazada o cancelada...
--         fecha de creación, fecha de su última actualización"
-- Texto (restricción): "no requiere mantener un historial detallado de cada
--         uno de los cambios de estado" -> un solo registro con estado actual,
--         no una tabla de auditoría.
-- Decisión: solicitud y reserva son la MISMA tabla; el estado refleja el ciclo
--           de vida. Las columnas servicio_* son un snapshot intencional
--           (desnormalización) para que cambios futuros del catálogo no alteren
--           solicitudes ya creadas.
-- ============================================================================

CREATE TABLE solicitudes (
  id                        INT           NOT NULL AUTO_INCREMENT,
  cliente_id                INT           NOT NULL,
  proveedor_id              INT           NOT NULL,
  servicio_id               INT           NOT NULL,
  -- --- snapshot del servicio al momento de crear la solicitud ---
  -- El prefijo servicio_ agrupa estas columnas: son la copia de las condiciones
  -- del catálogo al momento de crear la solicitud (no una lectura viva de la
  -- tabla servicios). Así, cambios futuros del proveedor no alteran la solicitud.
  servicio_nombre           VARCHAR(100)  NOT NULL,
  servicio_precio           DECIMAL(10,2) NOT NULL,
  servicio_duracion         INT           NOT NULL,   -- define el periodo ocupado: inicio + duración
  -- --- lugar de prestación ---
  direccion_id              INT           NOT NULL,   -- dirección principal u otra del cliente
  barrio_sector             VARCHAR(100)  NULL,
  info_localizacion         TEXT          NULL,
  observaciones             TEXT          NULL,
  -- --- fechas ---
  fecha_hora_inicio         DATETIME      NOT NULL,   -- fecha/hora solicitada por el cliente
  fecha_hora_propuesta      DATETIME      NULL,       -- solo cuando estado = SUGERIDA
  -- --- ciclo de vida ---
  estado                    ENUM('PENDIENTE','SUGERIDA','ACEPTADA','RECHAZADA','CANCELADA','COMPLETADA')
                            NOT NULL DEFAULT 'PENDIENTE',
  motivo                    TEXT          NULL,       -- rechazo o cancelación, según corresponda
  fecha_creacion            DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  fecha_actualizacion       DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP
                                      ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_solicitudes_proveedor_estado (proveedor_id, estado),
  KEY idx_solicitudes_cliente (cliente_id),
  CONSTRAINT fk_solicitudes_cliente
    FOREIGN KEY (cliente_id) REFERENCES clientes (usuario_id),
  CONSTRAINT fk_solicitudes_proveedor
    FOREIGN KEY (proveedor_id) REFERENCES proveedores (usuario_id),
  CONSTRAINT fk_solicitudes_servicio
    FOREIGN KEY (servicio_id) REFERENCES servicios (id),
  CONSTRAINT fk_solicitudes_direccion
    FOREIGN KEY (direccion_id) REFERENCES direcciones (id)
) ENGINE=InnoDB;
