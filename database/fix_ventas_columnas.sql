USE hotel_system;

ALTER TABLE ventas_productos
  ADD COLUMN metodo_pago ENUM('efectivo', 'tarjeta', 'yape', 'plin', 'transferencia', 'online') DEFAULT NULL AFTER notas;

ALTER TABLE ventas_productos
  ADD COLUMN numero_operacion VARCHAR(50) DEFAULT NULL AFTER metodo_pago;

ALTER TABLE ventas_productos
  ADD COLUMN telefono_pago VARCHAR(20) DEFAULT NULL AFTER numero_operacion;

SELECT 'Columnas agregadas a ventas_productos correctamente.' AS mensaje;
