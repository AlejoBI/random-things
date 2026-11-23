CREATE TABLE usuarios (
  id             INT          NOT NULL AUTO_INCREMENT,
  email          VARCHAR(120) NOT NULL,
  password_hash  VARCHAR(255) NOT NULL,           -- el hash lo genera el backend
  tipo           ENUM('CLIENTE','PROVEEDOR') NOT NULL,
  nombre         VARCHAR(100) NOT NULL,
  telefono       VARCHAR(20)  NULL,
  fecha_registro DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT pk_usuarios PRIMARY KEY (id),
  CONSTRAINT uq_usuarios_email UNIQUE (email)
) ENGINE=InnoDB;

CREATE TABLE clientes (
  usuario_id INT NOT NULL,
  CONSTRAINT pk_clientes PRIMARY KEY (usuario_id),
  CONSTRAINT fk_clientes_usuario FOREIGN KEY (usuario_id)
    REFERENCES usuarios (id) ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE proveedores (
  usuario_id        INT  NOT NULL,
  biografia         TEXT NULL,
  anios_experiencia INT  NULL,
  CONSTRAINT pk_proveedores PRIMARY KEY (usuario_id),
  CONSTRAINT fk_proveedores_usuario FOREIGN KEY (usuario_id)
    REFERENCES usuarios (id) ON DELETE RESTRICT,
  CONSTRAINT ck_proveedores_anios
    CHECK (anios_experiencia IS NULL OR anios_experiencia >= 0)
) ENGINE=InnoDB;

CREATE TABLE direcciones (
  id           INT          NOT NULL AUTO_INCREMENT,
  cliente_id   INT          NOT NULL,
  ciudad       VARCHAR(80)  NOT NULL,
  barrio       VARCHAR(80)  NULL,
  calle        VARCHAR(120) NOT NULL,
  numero       VARCHAR(20)  NULL,
  referencia   TEXT         NULL,
  es_principal TINYINT(1)   NOT NULL DEFAULT 0,
  CONSTRAINT pk_direcciones PRIMARY KEY (id),
  CONSTRAINT fk_direcciones_cliente FOREIGN KEY (cliente_id)
    REFERENCES clientes (usuario_id) ON DELETE CASCADE,
  CONSTRAINT ck_direcciones_principal CHECK (es_principal IN (0,1))
) ENGINE=InnoDB;

CREATE TABLE zonas_cobertura (
  id            INT          NOT NULL AUTO_INCREMENT,
  proveedor_id  INT          NOT NULL,
  ciudad        VARCHAR(80)  NOT NULL,
  barrio_sector VARCHAR(100) NOT NULL DEFAULT '',
  CONSTRAINT pk_zonas PRIMARY KEY (id),
  CONSTRAINT uq_zonas_proveedor_zona UNIQUE (proveedor_id, ciudad, barrio_sector),
  CONSTRAINT fk_zonas_proveedor FOREIGN KEY (proveedor_id)
    REFERENCES proveedores (usuario_id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE servicios (
  id               INT           NOT NULL AUTO_INCREMENT,
  proveedor_id     INT           NOT NULL,
  nombre           VARCHAR(100)  NOT NULL,
  categoria        VARCHAR(80)   NOT NULL,
  descripcion      TEXT          NULL,
  duracion_minutos INT           NOT NULL,
  precio           DECIMAL(10,2) NOT NULL,
  estado           ENUM('ACTIVO','INACTIVO') NOT NULL DEFAULT 'ACTIVO',
  CONSTRAINT pk_servicios PRIMARY KEY (id),
  CONSTRAINT uq_servicios_proveedor_nombre UNIQUE (proveedor_id, nombre),
  CONSTRAINT fk_servicios_proveedor FOREIGN KEY (proveedor_id)
    REFERENCES proveedores (usuario_id) ON DELETE RESTRICT,
  CONSTRAINT ck_servicios_duracion CHECK (duracion_minutos > 0),
  CONSTRAINT ck_servicios_precio   CHECK (precio >= 0),
  INDEX idx_servicios_categoria (categoria),
  INDEX idx_servicios_nombre (nombre)
) ENGINE=InnoDB;

CREATE TABLE servicios_multimedia (
  id          INT          NOT NULL AUTO_INCREMENT,
  servicio_id INT          NOT NULL,
  tipo        ENUM('FOTO','VIDEO') NOT NULL,
  url         VARCHAR(500) NOT NULL,
  orden       TINYINT UNSIGNED NOT NULL DEFAULT 1,
  CONSTRAINT pk_servicios_multimedia PRIMARY KEY (id),
  CONSTRAINT fk_multimedia_servicio FOREIGN KEY (servicio_id)
    REFERENCES servicios (id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE servicios_insumos (
  id          INT          NOT NULL AUTO_INCREMENT,
  servicio_id INT          NOT NULL,
  tipo        ENUM('PRODUCTO','INSUMO','EQUIPO') NOT NULL,
  nombre      VARCHAR(150) NOT NULL,
  descripcion TEXT         NULL,
  CONSTRAINT pk_servicios_insumos PRIMARY KEY (id),
  CONSTRAINT uq_insumos_servicio_nombre UNIQUE (servicio_id, nombre),
  CONSTRAINT fk_insumos_servicio FOREIGN KEY (servicio_id)
    REFERENCES servicios (id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE horarios_disponibilidad (
  id           INT  NOT NULL AUTO_INCREMENT,
  proveedor_id INT  NOT NULL,
  dia_semana   ENUM('LUNES','MARTES','MIERCOLES','JUEVES','VIERNES','SABADO','DOMINGO') NOT NULL,
  hora_inicio  TIME NOT NULL,
  hora_fin     TIME NOT NULL,
  CONSTRAINT pk_horarios PRIMARY KEY (id),
  CONSTRAINT uq_horarios_proveedor UNIQUE (proveedor_id, dia_semana, hora_inicio, hora_fin),
  CONSTRAINT fk_horarios_proveedor FOREIGN KEY (proveedor_id)
    REFERENCES proveedores (usuario_id) ON DELETE CASCADE,
  CONSTRAINT ck_horarios_horas CHECK (hora_inicio < hora_fin)
) ENGINE=InnoDB;

CREATE TABLE periodos_no_disponibilidad (
  id           INT          NOT NULL AUTO_INCREMENT,
  proveedor_id INT          NOT NULL,
  fecha_inicio DATETIME     NOT NULL,
  fecha_fin    DATETIME     NOT NULL,
  motivo       VARCHAR(200) NULL,
  CONSTRAINT pk_periodos PRIMARY KEY (id),
  CONSTRAINT fk_periodos_proveedor FOREIGN KEY (proveedor_id)
    REFERENCES proveedores (usuario_id) ON DELETE CASCADE,
  CONSTRAINT ck_periodos_fechas CHECK (fecha_inicio < fecha_fin)
) ENGINE=InnoDB;

CREATE TABLE recuperacion_contrasena (
  id               INT         NOT NULL AUTO_INCREMENT,
  usuario_id       INT         NOT NULL,
  codigo           VARCHAR(20) NOT NULL,
  fecha_expiracion DATETIME    NOT NULL,
  fecha_uso        DATETIME    NULL,
  fecha_creacion   DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  invalidado       TINYINT(1)  NOT NULL DEFAULT 0,       -- AJUSTE 1
  CONSTRAINT pk_recuperacion PRIMARY KEY (id),
  CONSTRAINT uq_recuperacion_codigo UNIQUE (codigo),
  CONSTRAINT fk_recuperacion_usuario FOREIGN KEY (usuario_id)
    REFERENCES usuarios (id) ON DELETE CASCADE,
  CONSTRAINT ck_recuperacion_vigencia CHECK (fecha_expiracion > fecha_creacion),
  CONSTRAINT ck_recuperacion_invalidado CHECK (invalidado IN (0,1)),
  CONSTRAINT ck_recuperacion_usado CHECK (fecha_uso IS NULL OR invalidado = 1)
) ENGINE=InnoDB;

CREATE TABLE solicitudes (
  id                   INT           NOT NULL AUTO_INCREMENT,
  cliente_id           INT           NOT NULL,
  proveedor_id         INT           NOT NULL,
  servicio_id          INT           NOT NULL,

  servicio_nombre      VARCHAR(100)  NOT NULL DEFAULT '',
  servicio_precio      DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  servicio_duracion    INT           NOT NULL DEFAULT 1,
  direccion_id         INT           NOT NULL,
  barrio_sector        VARCHAR(100)  NULL,
  info_localizacion    TEXT          NULL,
  observaciones        TEXT          NULL,
  fecha_hora_inicio    DATETIME      NOT NULL,          
  fecha_hora_propuesta DATETIME      NULL,              
  estado ENUM('PENDIENTE','SUGERIDA','ACEPTADA','RECHAZADA','CANCELADA','COMPLETADA')
         NOT NULL DEFAULT 'PENDIENTE',
  motivo               TEXT          NULL,
  fecha_creacion       DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  fecha_actualizacion  DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP
                                     ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT pk_solicitudes PRIMARY KEY (id),
  CONSTRAINT fk_solicitudes_cliente FOREIGN KEY (cliente_id)
    REFERENCES clientes (usuario_id) ON DELETE RESTRICT,
  CONSTRAINT fk_solicitudes_proveedor FOREIGN KEY (proveedor_id)
    REFERENCES proveedores (usuario_id) ON DELETE RESTRICT,
  CONSTRAINT fk_solicitudes_servicio FOREIGN KEY (servicio_id)
    REFERENCES servicios (id) ON DELETE RESTRICT,
  CONSTRAINT fk_solicitudes_direccion FOREIGN KEY (direccion_id)
    REFERENCES direcciones (id) ON DELETE RESTRICT,
  CONSTRAINT ck_solicitudes_precio   CHECK (servicio_precio >= 0),
  CONSTRAINT ck_solicitudes_duracion CHECK (servicio_duracion > 0),
  
  CONSTRAINT ck_solicitudes_estado CHECK (
        (estado <> 'SUGERIDA'  OR fecha_hora_propuesta IS NOT NULL)
    AND (estado <> 'PENDIENTE' OR fecha_hora_propuesta IS NULL)
    AND (estado NOT IN ('RECHAZADA','CANCELADA')
         OR (motivo IS NOT NULL AND CHAR_LENGTH(TRIM(motivo)) > 0))
  ),
  INDEX idx_solicitudes_agenda (proveedor_id, estado, fecha_hora_inicio)
) ENGINE=InnoDB;
