-- ============================================================================
-- FIX: Tabla `cobros` faltante + columnas faltantes en `ventas_productos`
-- Basado en lo que backend/src/routes/cobros.routes.ts y productos.routes.ts
-- ya esperan que exista.
-- ============================================================================

USE hotel_system;

-- ============================================================================
-- 1. TABLA COBROS (no existía)
-- ============================================================================
CREATE TABLE IF NOT EXISTS cobros (
  id                 INT AUTO_INCREMENT PRIMARY KEY,
  codigo             VARCHAR(20) NOT NULL UNIQUE,
  concepto           VARCHAR(255) NOT NULL,
  tipo_cobro         ENUM(
                        'venta_directa',
                        'servicio_extra',
                        'anticipo_reserva',
                        'saldo_reserva',
                        'lavanderia',
                        'consumo_minibar',
                        'otro'
                      ) NOT NULL DEFAULT 'venta_directa',
  monto              DECIMAL(10,2) NOT NULL,
  metodo_pago        ENUM('efectivo', 'tarjeta', 'yape', 'plin', 'transferencia', 'online') NOT NULL,
  numero_operacion   VARCHAR(50) DEFAULT NULL,
  telefono_pago      VARCHAR(20) DEFAULT NULL,
  cliente_id         INT DEFAULT NULL,
  nombre_cliente     VARCHAR(200) DEFAULT NULL,
  reserva_id         INT DEFAULT NULL,
  habitacion_id      INT DEFAULT NULL,
  recepcionista_id   INT NOT NULL,
  notas              TEXT DEFAULT NULL,
  anulado            BOOLEAN NOT NULL DEFAULT FALSE,
  motivo_anulacion   VARCHAR(255) DEFAULT NULL,
  fecha_anulacion    DATETIME DEFAULT NULL,
  fecha              DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

  FOREIGN KEY (cliente_id) REFERENCES clientes(id) ON DELETE SET NULL,
  FOREIGN KEY (reserva_id) REFERENCES reservas(id) ON DELETE SET NULL,
  FOREIGN KEY (habitacion_id) REFERENCES habitaciones(id) ON DELETE SET NULL,
  FOREIGN KEY (recepcionista_id) REFERENCES usuarios(id) ON DELETE RESTRICT,
  INDEX idx_cobros_fecha (fecha),
  INDEX idx_cobros_anulado (anulado)
) ENGINE=InnoDB;

-- Trigger: genera el código automáticamente (el backend no lo manda al crear)
DELIMITER $$
DROP TRIGGER IF EXISTS tr_cobros_genera_codigo$$
CREATE TRIGGER tr_cobros_genera_codigo
BEFORE INSERT ON cobros
FOR EACH ROW
BEGIN
  IF NEW.codigo IS NULL OR NEW.codigo = '' THEN
    SET NEW.codigo = CONCAT('COB-', DATE_FORMAT(NOW(), '%Y%m%d'), '-', LPAD(FLOOR(RAND() * 10000), 4, '0'));
  END IF;
END$$
DELIMITER ;

-- ============================================================================
-- 2. COLUMNAS FALTANTES EN VENTAS_PRODUCTOS
-- (el backend ya las consulta en productos.routes.ts, pero no existían)
-- ============================================================================
ALTER TABLE ventas_productos
  ADD COLUMN IF NOT EXISTS metodo_pago ENUM('efectivo', 'tarjeta', 'yape', 'plin', 'transferencia', 'online') DEFAULT NULL AFTER notas,
  ADD COLUMN IF NOT EXISTS numero_operacion VARCHAR(50) DEFAULT NULL AFTER metodo_pago,
  ADD COLUMN IF NOT EXISTS telefono_pago VARCHAR(20) DEFAULT NULL AFTER numero_operacion;

SELECT 'Tabla cobros creada y ventas_productos actualizada correctamente.' AS mensaje;
