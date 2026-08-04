USE hotel_system;

ALTER TABLE productos
  ADD COLUMN unidad_medida VARCHAR(20) DEFAULT 'unidad' AFTER precio;

ALTER TABLE reservas
  ADD COLUMN numero_operacion VARCHAR(50) DEFAULT NULL AFTER metodo_pago;

SELECT 'Columnas agregadas a productos y reservas correctamente.' AS mensaje;
