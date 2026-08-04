-- ============================================================================
-- HOTEL MANAGEMENT SYSTEM - SCHEMA v2 (con datos reales del cliente)
-- Motor: MySQL 8.0+ / MariaDB 10.5+ (compatible con XAMPP)
-- Charset: utf8mb4 (soporta tildes, ñ, emojis)
-- ============================================================================
--
-- CAMBIOS respecto a v1:
-- - 4 franjas horarias (5am-12pm, 12pm-7pm, 7pm-10pm, 10pm-5am) en vez de 3
-- - 6 tipos de habitación reales del cliente
-- - Tabla "temporadas" para Fiestas Patrias, Año Nuevo, Semana Santa, Temp. Alta
-- - Tabla "productos" para venta (toallas, calefacción, etc.)
-- - Tabla "turnos_limpieza" para el control mañana/tarde
-- - Campos "procedencia" y "motivo_viaje" en clientes
-- - Tipos de documento extendidos (DNI, CI, Pasaporte, Otros)
-- ============================================================================

-- ⚠️ ATENCIÓN: este script ELIMINA la BD si ya existe. Solo en desarrollo.
DROP DATABASE IF EXISTS hotel_system;
CREATE DATABASE hotel_system
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE hotel_system;

-- ============================================================================
-- 1. USUARIOS DEL SISTEMA (admin, recepcionista, limpieza)
-- ============================================================================
CREATE TABLE usuarios (
  id              INT AUTO_INCREMENT PRIMARY KEY,
  username        VARCHAR(50)  NOT NULL UNIQUE,
  password_hash   VARCHAR(255) NOT NULL,           -- bcrypt hash, NUNCA en claro
  nombres         VARCHAR(100) NOT NULL,
  apellidos       VARCHAR(100) NOT NULL,
  dni             VARCHAR(20)  UNIQUE,
  email           VARCHAR(150) UNIQUE,
  telefono        VARCHAR(30),
  rol             ENUM('admin','recepcionista','limpieza') NOT NULL,
  turno           ENUM('mañana','tarde','noche','rotativo') DEFAULT NULL,
  hora_inicio_turno TIME DEFAULT NULL,
  hora_fin_turno    TIME DEFAULT NULL,
  salario         DECIMAL(10,2) DEFAULT NULL,
  activo          BOOLEAN NOT NULL DEFAULT TRUE,
  ultimo_login    DATETIME DEFAULT NULL,
  creado_en       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  actualizado_en  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

  INDEX idx_usuarios_rol (rol),
  INDEX idx_usuarios_activo (activo)
) ENGINE=InnoDB;

-- ============================================================================
-- 2. CLIENTES (huéspedes) - 12 campos del registro real del cliente
-- ============================================================================
CREATE TABLE clientes (
  id              INT AUTO_INCREMENT PRIMARY KEY,
  -- Documento
  tipo_documento  ENUM('DNI','CI','Pasaporte','Otros') NOT NULL DEFAULT 'DNI',
  numero_documento VARCHAR(20) NOT NULL,
  -- Datos personales
  nombres         VARCHAR(100) NOT NULL,
  apellidos       VARCHAR(100) NOT NULL,
  fecha_nacimiento DATE        DEFAULT NULL,
  nacionalidad    VARCHAR(80)  DEFAULT 'Peruana',
  procedencia     VARCHAR(150) DEFAULT NULL,       -- ciudad/país de donde viene
  motivo_viaje    ENUM('turismo','negocios','salud','familia','transito','otro') DEFAULT 'turismo',
  -- Contacto
  telefono        VARCHAR(30),
  email           VARCHAR(150),
  direccion       VARCHAR(255),
  -- Tipo de cliente
  tipo_cliente    ENUM('frecuente','temporal') NOT NULL DEFAULT 'temporal',
  descuento_porcentaje    DECIMAL(5,2) DEFAULT 0.00,
  total_estancias         INT NOT NULL DEFAULT 0,
  monto_total_gastado     DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  fecha_ultima_estancia   DATE DEFAULT NULL,
  -- Metadata
  notas           TEXT,
  activo          BOOLEAN NOT NULL DEFAULT TRUE,
  creado_en       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  actualizado_en  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

  UNIQUE KEY uk_documento (tipo_documento, numero_documento),
  INDEX idx_clientes_doc (numero_documento),
  INDEX idx_clientes_nombre (apellidos, nombres),
  INDEX idx_clientes_tipo (tipo_cliente),
  FULLTEXT INDEX idx_clientes_busqueda (nombres, apellidos, numero_documento)
) ENGINE=InnoDB;

-- ============================================================================
-- 3. HABITACIONES + camas
-- ============================================================================
-- Los 6 tipos REALES del hotel:
-- 1: matrimonial_privada_ducha → Matrimonial privada con ducha y baño
-- 2: matrimonial_bano           → Matrimonial solo con baño
-- 3: tv_cable                   → Habitación con TV cable
-- 4: simple                     → Habitación simple
-- 5: doble_privada              → Doble privada con baño y ducha
-- 6: doble_tv_cable             → Doble con TV cable

CREATE TABLE habitaciones (
  id              INT AUTO_INCREMENT PRIMARY KEY,
  numero          VARCHAR(10)  NOT NULL UNIQUE,
  piso            INT NOT NULL,
  tipo            ENUM(
                    'matrimonial_privada_ducha',
                    'matrimonial_bano',
                    'tv_cable',
                    'simple',
                    'doble_privada',
                    'doble_tv_cable'
                  ) NOT NULL,
  capacidad       INT NOT NULL DEFAULT 1,
  -- Características de baño
  bano_privado    BOOLEAN NOT NULL DEFAULT TRUE,
  tiene_ducha     BOOLEAN NOT NULL DEFAULT TRUE,
  bano_con_jacuzzi BOOLEAN NOT NULL DEFAULT FALSE,
  -- Características de TV
  tiene_tv            BOOLEAN NOT NULL DEFAULT FALSE,
  tiene_control_remoto BOOLEAN NOT NULL DEFAULT FALSE,
  tiene_cable_tv      BOOLEAN NOT NULL DEFAULT FALSE,
  -- Otros amenities
  tiene_wifi          BOOLEAN NOT NULL DEFAULT TRUE,
  tiene_calefaccion   BOOLEAN NOT NULL DEFAULT FALSE,
  tiene_ventana       BOOLEAN NOT NULL DEFAULT TRUE,
  tiene_balcon        BOOLEAN NOT NULL DEFAULT FALSE,
  -- Estados operativos
  estado_ocupacion ENUM('disponible','ocupada','reservada','fuera_de_servicio') NOT NULL DEFAULT 'disponible',
  estado_limpieza  ENUM('limpia','sucia','en_limpieza','limpieza_pendiente_validacion') NOT NULL DEFAULT 'limpia',
  -- Precio referencial (el real viene de tarifas_franjas según tipo + hora)
  precio_base_noche   DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  -- Metadata
  notas               TEXT,
  imagen_url          VARCHAR(500) DEFAULT NULL,
  activo              BOOLEAN NOT NULL DEFAULT TRUE,
  creado_en           DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  actualizado_en      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

  INDEX idx_hab_estado_ocup (estado_ocupacion),
  INDEX idx_hab_estado_limp (estado_limpieza),
  INDEX idx_hab_piso (piso),
  INDEX idx_hab_tipo (tipo)
) ENGINE=InnoDB;

-- Camas dentro de cada habitación (1 habitación → N camas)
CREATE TABLE camas_habitacion (
  id              INT AUTO_INCREMENT PRIMARY KEY,
  habitacion_id   INT NOT NULL,
  tipo_cama       ENUM('individual','matrimonial','queen','king','litera_individual','litera_matrimonial','sofa_cama') NOT NULL,
  cantidad        INT NOT NULL DEFAULT 1,

  FOREIGN KEY (habitacion_id) REFERENCES habitaciones(id) ON DELETE CASCADE,
  INDEX idx_camas_hab (habitacion_id)
) ENGINE=InnoDB;

-- ============================================================================
-- 4. TARIFAS POR FRANJA HORARIA (4 franjas reales del cliente)
-- ============================================================================
-- Franjas reales:
--   05:00 - 12:00 (mañana)
--   12:00 - 19:00 (tarde)
--   19:00 - 22:00 (noche)
--   22:00 - 05:00 (madrugada / noche completa)

CREATE TABLE tarifas_franjas (
  id              INT AUTO_INCREMENT PRIMARY KEY,
  nombre          VARCHAR(80) NOT NULL,            -- "Franja 5am-12pm"
  hora_inicio     TIME NOT NULL,
  hora_fin        TIME NOT NULL,
  tipo_habitacion ENUM(
                    'matrimonial_privada_ducha',
                    'matrimonial_bano',
                    'tv_cable',
                    'simple',
                    'doble_privada',
                    'doble_tv_cable',
                    'todas'
                  ) NOT NULL DEFAULT 'todas',
  precio          DECIMAL(10,2) DEFAULT NULL,     -- NULL = no disponible (ej: simple en madrugada)
  dia_semana      ENUM('lunes','martes','miercoles','jueves','viernes','sabado','domingo') DEFAULT NULL,
  vigente_desde   DATE DEFAULT NULL,
  vigente_hasta   DATE DEFAULT NULL,
  activo          BOOLEAN NOT NULL DEFAULT TRUE,
  creado_en       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  actualizado_en  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

  INDEX idx_tarifas_horario (hora_inicio, hora_fin),
  INDEX idx_tarifas_tipo (tipo_habitacion)
) ENGINE=InnoDB;

-- ============================================================================
-- 5. TEMPORADAS (Fiestas Patrias, Año Nuevo, Semana Santa, Temporada Alta)
-- ============================================================================
CREATE TABLE temporadas (
  id              INT AUTO_INCREMENT PRIMARY KEY,
  nombre          VARCHAR(80) NOT NULL UNIQUE,
  tipo            ENUM('regular','fiestas_patrias','año_nuevo','semana_santa','temporada_alta','otro') NOT NULL DEFAULT 'otro',
  fecha_inicio    DATE NOT NULL,
  fecha_fin       DATE NOT NULL,
  -- Multiplicador o sobreprecio sobre la tarifa por noche
  multiplicador_precio DECIMAL(4,2) DEFAULT 1.00, -- 1.40 = 40% más caro
  notas           TEXT,
  activo          BOOLEAN NOT NULL DEFAULT TRUE,
  creado_en       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

  INDEX idx_temp_fechas (fecha_inicio, fecha_fin)
) ENGINE=InnoDB;

-- Tarifa por noche completa por tipo de habitación + temporada
CREATE TABLE tarifas_noche_temporada (
  id              INT AUTO_INCREMENT PRIMARY KEY,
  temporada_id    INT NOT NULL,
  tipo_habitacion ENUM(
                    'matrimonial_privada_ducha',
                    'matrimonial_bano',
                    'tv_cable',
                    'simple',
                    'doble_privada',
                    'doble_tv_cable'
                  ) NOT NULL,
  precio          DECIMAL(10,2) NOT NULL,

  FOREIGN KEY (temporada_id) REFERENCES temporadas(id) ON DELETE CASCADE,
  UNIQUE KEY uk_temp_tipo (temporada_id, tipo_habitacion)
) ENGINE=InnoDB;

-- ============================================================================
-- 6. RESERVAS / ESTANCIAS
-- ============================================================================
CREATE TABLE reservas (
  id              INT AUTO_INCREMENT PRIMARY KEY,
  codigo          VARCHAR(20) NOT NULL UNIQUE,
  cliente_id      INT NOT NULL,
  habitacion_id   INT NOT NULL,
  recepcionista_id INT NOT NULL,
  -- Fechas / horas (12 campos del registro real)
  fecha_check_in  DATETIME NOT NULL,
  fecha_check_out DATETIME DEFAULT NULL,
  fecha_check_out_real DATETIME DEFAULT NULL,
  noches          INT DEFAULT NULL,
  horas           INT DEFAULT NULL,                -- estancias por horas
  tipo_estancia   ENUM('por_horas','por_noche','fecha_abierta') NOT NULL DEFAULT 'por_noche',
  -- Pago
  precio_total    DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  monto_pagado    DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  descuento_aplicado DECIMAL(10,2) DEFAULT 0.00,
  estado_pago     ENUM('pagado','pendiente','parcial','reembolsado') NOT NULL DEFAULT 'pendiente',
  metodo_pago     ENUM('efectivo','tarjeta','transferencia','yape','plin','online') DEFAULT NULL,
  codigo_pago_online VARCHAR(50) DEFAULT NULL,
  -- Estado
  estado          ENUM('activa','check_out','cancelada','fecha_abierta','no_show') NOT NULL DEFAULT 'activa',
  origen          ENUM('presencial','telefono','web','booking','otro') NOT NULL DEFAULT 'presencial',
  notas           TEXT,
  creado_en       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  actualizado_en  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

  FOREIGN KEY (cliente_id) REFERENCES clientes(id) ON DELETE RESTRICT,
  FOREIGN KEY (habitacion_id) REFERENCES habitaciones(id) ON DELETE RESTRICT,
  FOREIGN KEY (recepcionista_id) REFERENCES usuarios(id) ON DELETE RESTRICT,

  INDEX idx_reservas_cliente (cliente_id),
  INDEX idx_reservas_hab (habitacion_id),
  INDEX idx_reservas_fechas (fecha_check_in, fecha_check_out),
  INDEX idx_reservas_estado (estado)
) ENGINE=InnoDB;

-- ============================================================================
-- 7. INSUMOS ENTREGADOS al cliente (toalla, jabón, papel higiénico)
-- ============================================================================
CREATE TABLE insumos_entregados (
  id              INT AUTO_INCREMENT PRIMARY KEY,
  reserva_id      INT NOT NULL,
  tipo_insumo     ENUM('toalla','jabon','papel_higienico') NOT NULL,
  cantidad        INT NOT NULL DEFAULT 1,
  fecha_entrega   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  entregado_por_usuario_id INT,
  notas           TEXT,

  FOREIGN KEY (reserva_id) REFERENCES reservas(id) ON DELETE CASCADE,
  FOREIGN KEY (entregado_por_usuario_id) REFERENCES usuarios(id) ON DELETE SET NULL,
  INDEX idx_insumos_reserva (reserva_id)
) ENGINE=InnoDB;

-- ============================================================================
-- 8. PRODUCTOS EN VENTA (toallas extra, calefacción, surtido, etc.)
-- ============================================================================
CREATE TABLE productos (
  id              INT AUTO_INCREMENT PRIMARY KEY,
  nombre          VARCHAR(100) NOT NULL,
  categoria       ENUM('alquiler','consumible','servicio','surtido','otro') NOT NULL DEFAULT 'otro',
  precio          DECIMAL(10,2) NOT NULL,
  stock           INT DEFAULT NULL,                -- NULL = ilimitado/no aplica
  descripcion     TEXT,
  activo          BOOLEAN NOT NULL DEFAULT TRUE,
  creado_en       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- Ventas de productos (asociadas a una reserva)
CREATE TABLE ventas_productos (
  id              INT AUTO_INCREMENT PRIMARY KEY,
  reserva_id      INT DEFAULT NULL,                -- NULL = venta directa sin reserva
  producto_id     INT NOT NULL,
  cantidad        INT NOT NULL DEFAULT 1,
  precio_unitario DECIMAL(10,2) NOT NULL,
  subtotal        DECIMAL(10,2) GENERATED ALWAYS AS (cantidad * precio_unitario) STORED,
  vendido_por_usuario_id INT NOT NULL,
  fecha_venta     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  notas           TEXT,

  FOREIGN KEY (reserva_id) REFERENCES reservas(id) ON DELETE SET NULL,
  FOREIGN KEY (producto_id) REFERENCES productos(id) ON DELETE RESTRICT,
  FOREIGN KEY (vendido_por_usuario_id) REFERENCES usuarios(id) ON DELETE RESTRICT,
  INDEX idx_ventas_reserva (reserva_id),
  INDEX idx_ventas_fecha (fecha_venta)
) ENGINE=InnoDB;

-- ============================================================================
-- 9. OBJETOS PERDIDOS
-- ============================================================================
CREATE TABLE objetos_perdidos (
  id              INT AUTO_INCREMENT PRIMARY KEY,
  reserva_id      INT DEFAULT NULL,
  habitacion_id   INT DEFAULT NULL,
  descripcion     VARCHAR(255) NOT NULL,
  ubicacion       VARCHAR(150),
  fecha_encontrado DATE NOT NULL,
  reportado_por_usuario_id INT,
  estado          ENUM('en_custodia','devuelto','desechado') NOT NULL DEFAULT 'en_custodia',
  notas           TEXT,
  creado_en       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  actualizado_en  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

  FOREIGN KEY (reserva_id) REFERENCES reservas(id) ON DELETE SET NULL,
  FOREIGN KEY (habitacion_id) REFERENCES habitaciones(id) ON DELETE SET NULL,
  FOREIGN KEY (reportado_por_usuario_id) REFERENCES usuarios(id) ON DELETE SET NULL
) ENGINE=InnoDB;

-- ============================================================================
-- 10. LIMPIEZA - el corazón del sistema
-- ============================================================================
CREATE TABLE limpieza_registros (
  id                  INT AUTO_INCREMENT PRIMARY KEY,
  habitacion_id       INT NOT NULL,
  reserva_previa_id   INT DEFAULT NULL,
  -- Quién limpió y quién validó
  empleado_limpieza_id INT DEFAULT NULL,
  recepcionista_validador_id INT DEFAULT NULL,
  -- Turno en que ocurre la limpieza (resuelve "26 habs por turno mañana/tarde")
  turno               ENUM('mañana','tarde','noche') DEFAULT NULL,
  -- Estados (5 etapas del flujo)
  estado              ENUM(
                        'pendiente',
                        'en_progreso',
                        'completada_por_limpieza',
                        'validada_por_recepcion',
                        'rechazada'
                      ) NOT NULL DEFAULT 'pendiente',
  -- Timestamps de cada etapa (auditoría completa)
  fecha_creacion      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  fecha_inicio_limpieza DATETIME DEFAULT NULL,
  fecha_fin_limpieza  DATETIME DEFAULT NULL,
  fecha_validacion    DATETIME DEFAULT NULL,
  fecha_rechazo       DATETIME DEFAULT NULL,
  -- Notas
  notas_limpieza      TEXT,
  notas_validacion    TEXT,
  motivo_rechazo      TEXT,
  -- Calculado automáticamente
  duracion_minutos    INT GENERATED ALWAYS AS (
                        TIMESTAMPDIFF(MINUTE, fecha_inicio_limpieza, fecha_fin_limpieza)
                      ) VIRTUAL,

  FOREIGN KEY (habitacion_id) REFERENCES habitaciones(id) ON DELETE CASCADE,
  FOREIGN KEY (reserva_previa_id) REFERENCES reservas(id) ON DELETE SET NULL,
  FOREIGN KEY (empleado_limpieza_id) REFERENCES usuarios(id) ON DELETE SET NULL,
  FOREIGN KEY (recepcionista_validador_id) REFERENCES usuarios(id) ON DELETE SET NULL,

  INDEX idx_limpieza_estado (estado),
  INDEX idx_limpieza_empleado (empleado_limpieza_id),
  INDEX idx_limpieza_hab (habitacion_id),
  INDEX idx_limpieza_fecha (fecha_creacion),
  INDEX idx_limpieza_turno (turno)
) ENGINE=InnoDB;

-- Resumen diario por turno (lo que pidió el cliente: "26 habs por turno")
CREATE TABLE turnos_limpieza (
  id              INT AUTO_INCREMENT PRIMARY KEY,
  fecha           DATE NOT NULL,
  turno           ENUM('mañana','tarde','noche') NOT NULL,
  encargado_id    INT NOT NULL,
  hora_inicio     DATETIME DEFAULT NULL,
  hora_fin        DATETIME DEFAULT NULL,
  total_habitaciones_asignadas INT DEFAULT 0,
  total_habitaciones_limpiadas INT DEFAULT 0,
  notas           TEXT,
  creado_en       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

  FOREIGN KEY (encargado_id) REFERENCES usuarios(id) ON DELETE RESTRICT,
  UNIQUE KEY uk_turno_fecha (fecha, turno, encargado_id),
  INDEX idx_turnos_fecha (fecha)
) ENGINE=InnoDB;

-- ============================================================================
-- 11. AUDITORÍA GENERAL
-- ============================================================================
CREATE TABLE auditoria (
  id              BIGINT AUTO_INCREMENT PRIMARY KEY,
  usuario_id      INT DEFAULT NULL,
  usuario_nombre  VARCHAR(150),
  accion          VARCHAR(80) NOT NULL,
  entidad         VARCHAR(50),
  entidad_id      INT,
  datos_antes     JSON,
  datos_despues   JSON,
  ip_address      VARCHAR(45),
  user_agent      VARCHAR(255),
  timestamp       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

  FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE SET NULL,
  INDEX idx_auditoria_usuario (usuario_id),
  INDEX idx_auditoria_accion (accion),
  INDEX idx_auditoria_timestamp (timestamp)
) ENGINE=InnoDB;

-- ============================================================================
-- 12. SESIONES (JWT refresh tokens)
-- ============================================================================
CREATE TABLE sesiones (
  id              INT AUTO_INCREMENT PRIMARY KEY,
  usuario_id      INT NOT NULL,
  refresh_token   VARCHAR(500) NOT NULL UNIQUE,
  ip_address      VARCHAR(45),
  user_agent      VARCHAR(255),
  expira_en       DATETIME NOT NULL,
  revocada        BOOLEAN NOT NULL DEFAULT FALSE,
  creado_en       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

  FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE,
  INDEX idx_sesiones_usuario (usuario_id),
  INDEX idx_sesiones_token (refresh_token)
) ENGINE=InnoDB;

-- ============================================================================
-- 13. NOTIFICACIONES (Socket.IO + históricas)
-- ============================================================================
CREATE TABLE notificaciones (
  id              INT AUTO_INCREMENT PRIMARY KEY,
  destinatario_rol  ENUM('admin','recepcionista','limpieza','todos') NOT NULL,
  destinatario_usuario_id INT DEFAULT NULL,
  tipo            VARCHAR(50) NOT NULL,
  titulo          VARCHAR(150) NOT NULL,
  mensaje         TEXT,
  data_extra      JSON,
  leida           BOOLEAN NOT NULL DEFAULT FALSE,
  fecha_lectura   DATETIME DEFAULT NULL,
  creado_en       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

  FOREIGN KEY (destinatario_usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE,
  INDEX idx_notif_destinatario (destinatario_usuario_id, leida),
  INDEX idx_notif_rol (destinatario_rol, leida)
) ENGINE=InnoDB;

-- ============================================================================
-- 14. CONFIGURACIÓN DEL HOTEL
-- ============================================================================
CREATE TABLE configuracion_hotel (
  id              INT AUTO_INCREMENT PRIMARY KEY,
  clave           VARCHAR(100) NOT NULL UNIQUE,
  valor           TEXT,
  tipo            ENUM('string','number','boolean','json') NOT NULL DEFAULT 'string',
  descripcion     VARCHAR(255),
  actualizado_en  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- ============================================================================
-- TRIGGERS - automatizan el flujo limpieza ↔ recepción
-- ============================================================================

DELIMITER //

-- Cuando una reserva pasa a 'check_out', se crea automáticamente
-- un registro de limpieza pendiente
CREATE TRIGGER tr_reserva_checkout_crea_limpieza
AFTER UPDATE ON reservas
FOR EACH ROW
BEGIN
  IF NEW.estado = 'check_out' AND OLD.estado <> 'check_out' THEN
    INSERT INTO limpieza_registros (habitacion_id, reserva_previa_id, estado)
    VALUES (NEW.habitacion_id, NEW.id, 'pendiente');

    UPDATE habitaciones
    SET estado_ocupacion = 'disponible',
        estado_limpieza = 'sucia'
    WHERE id = NEW.habitacion_id;
  END IF;
END//

-- Cuando cambia estado de limpieza, sincroniza el de la habitación
CREATE TRIGGER tr_limpieza_actualiza_habitacion
AFTER UPDATE ON limpieza_registros
FOR EACH ROW
BEGIN
  IF NEW.estado = 'en_progreso' AND OLD.estado <> 'en_progreso' THEN
    UPDATE habitaciones
    SET estado_limpieza = 'en_limpieza'
    WHERE id = NEW.habitacion_id;
  END IF;

  IF NEW.estado = 'completada_por_limpieza'
     AND OLD.estado <> 'completada_por_limpieza' THEN
    UPDATE habitaciones
    SET estado_limpieza = 'limpieza_pendiente_validacion'
    WHERE id = NEW.habitacion_id;
  END IF;

  IF NEW.estado = 'validada_por_recepcion'
     AND OLD.estado <> 'validada_por_recepcion' THEN
    UPDATE habitaciones
    SET estado_limpieza = 'limpia'
    WHERE id = NEW.habitacion_id;
  END IF;
END//

-- Auto-actualiza contadores del cliente al crear/cerrar reservas
CREATE TRIGGER tr_reserva_actualiza_cliente
AFTER UPDATE ON reservas
FOR EACH ROW
BEGIN
  IF NEW.estado = 'check_out' AND OLD.estado <> 'check_out' THEN
    UPDATE clientes
    SET total_estancias = total_estancias + 1,
        monto_total_gastado = monto_total_gastado + NEW.monto_pagado,
        fecha_ultima_estancia = DATE(NEW.fecha_check_out_real)
    WHERE id = NEW.cliente_id;

    -- Auto-promoción a frecuente al alcanzar X estancias
    UPDATE clientes
    SET tipo_cliente = 'frecuente'
    WHERE id = NEW.cliente_id
      AND total_estancias >= (
        SELECT CAST(valor AS UNSIGNED)
        FROM configuracion_hotel
        WHERE clave = 'estancias_para_frecuente'
        LIMIT 1
      )
      AND tipo_cliente = 'temporal';
  END IF;
END//

DELIMITER ;

-- ============================================================================
-- VIEWS útiles para reportes
-- ============================================================================

-- Vista: habitaciones con su info completa (camas, estado, etc.)
CREATE VIEW vista_habitaciones_completa AS
SELECT
  h.*,
  CASE h.tipo
    WHEN 'matrimonial_privada_ducha' THEN 'Matrimonial privada c/n ducha y baño'
    WHEN 'matrimonial_bano'           THEN 'Matrimonial solo c/n baño'
    WHEN 'tv_cable'                   THEN 'TV cable'
    WHEN 'simple'                     THEN 'Simple'
    WHEN 'doble_privada'              THEN 'Doble privada baño y ducha'
    WHEN 'doble_tv_cable'             THEN 'Doble c/n TV cable'
  END AS tipo_descripcion,
  COALESCE((
    SELECT GROUP_CONCAT(CONCAT(c.cantidad,' ',c.tipo_cama) SEPARATOR ', ')
    FROM camas_habitacion c WHERE c.habitacion_id = h.id
  ), 'Sin camas') AS resumen_camas,
  (SELECT COUNT(*) FROM reservas r
    WHERE r.habitacion_id = h.id AND r.estado = 'activa') AS reservas_activas
FROM habitaciones h;

-- Vista: estadísticas de limpieza por empleado
CREATE VIEW vista_limpieza_por_empleado AS
SELECT
  u.id              AS empleado_id,
  CONCAT(u.nombres,' ',u.apellidos) AS empleado_nombre,
  DATE(lr.fecha_fin_limpieza) AS fecha,
  lr.turno,
  COUNT(*)          AS habitaciones_limpiadas,
  AVG(TIMESTAMPDIFF(MINUTE, lr.fecha_inicio_limpieza, lr.fecha_fin_limpieza)) AS promedio_minutos
FROM limpieza_registros lr
JOIN usuarios u ON u.id = lr.empleado_limpieza_id
WHERE lr.estado IN ('completada_por_limpieza','validada_por_recepcion')
GROUP BY u.id, DATE(lr.fecha_fin_limpieza), lr.turno;

-- Vista: clientes frecuentes
CREATE VIEW vista_clientes_frecuentes AS
SELECT
  c.*,
  (SELECT COUNT(*) FROM reservas r WHERE r.cliente_id = c.id) AS total_reservas,
  (SELECT MAX(r.fecha_check_in) FROM reservas r WHERE r.cliente_id = c.id) AS ultima_visita
FROM clientes c
WHERE c.tipo_cliente = 'frecuente';

-- Vista: módulos del dashboard (lo que pidió el cliente)
CREATE VIEW vista_dashboard_modulos AS
SELECT
  (SELECT COUNT(*) FROM habitaciones WHERE estado_ocupacion='disponible' AND estado_limpieza='limpia' AND activo=TRUE) AS hab_disponibles,
  (SELECT COUNT(*) FROM habitaciones WHERE estado_ocupacion='ocupada' AND activo=TRUE) AS hab_ocupadas,
  (SELECT COUNT(*) FROM habitaciones WHERE estado_ocupacion='reservada' AND activo=TRUE) AS hab_reservadas,
  (SELECT COUNT(*) FROM habitaciones WHERE estado_limpieza='sucia' AND activo=TRUE) AS hab_por_limpiar,
  (SELECT COUNT(*) FROM habitaciones WHERE estado_limpieza='en_limpieza' AND activo=TRUE) AS hab_en_limpieza,
  (SELECT COUNT(*) FROM habitaciones WHERE estado_limpieza='limpieza_pendiente_validacion' AND activo=TRUE) AS hab_pendiente_validacion,
  (SELECT COUNT(*) FROM clientes WHERE tipo_cliente='frecuente' AND activo=TRUE) AS clientes_frecuentes,
  (SELECT COUNT(*) FROM reservas WHERE estado='activa') AS reservas_activas;

-- ============================================================================
-- FIN DEL SCHEMA v2
-- ============================================================================
SELECT 'Schema v2 creado correctamente. Ahora ejecuta seed.sql para cargar datos.' AS mensaje;
