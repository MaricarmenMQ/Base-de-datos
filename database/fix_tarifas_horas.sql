USE hotel_system;

CREATE TABLE IF NOT EXISTS tarifas_horas (
  id              INT AUTO_INCREMENT PRIMARY KEY,
  tipo_habitacion ENUM(
                    'matrimonial_privada_ducha',
                    'matrimonial_bano',
                    'tv_cable',
                    'simple',
                    'doble_privada',
                    'doble_tv_cable',
                    'todas'
                  ) NOT NULL,
  franja          ENUM('hasta_12', 'hasta_19', 'hasta_22', 'madrugada') NOT NULL,
  precio_normal   DECIMAL(10,2) DEFAULT NULL,
  precio_semana   DECIMAL(10,2) DEFAULT NULL,
  precio_fiestas  DECIMAL(10,2) DEFAULT NULL,
  precio_agosto   DECIMAL(10,2) DEFAULT NULL,

  UNIQUE KEY uq_tarifa_hora (tipo_habitacion, franja)
) ENGINE=InnoDB;

-- Una fila por cada combinación tipo_habitacion x franja, lista para
-- que el admin rellene los precios desde el panel (sin esto la tabla
-- quedaría vacía y el selector no tendría nada que mostrar).
INSERT IGNORE INTO tarifas_horas (tipo_habitacion, franja)
SELECT th.tipo, fr.franja
FROM (
  SELECT 'matrimonial_privada_ducha' AS tipo UNION ALL
  SELECT 'matrimonial_bano' UNION ALL
  SELECT 'tv_cable' UNION ALL
  SELECT 'simple' UNION ALL
  SELECT 'doble_privada' UNION ALL
  SELECT 'doble_tv_cable' UNION ALL
  SELECT 'todas'
) th
CROSS JOIN (
  SELECT 'hasta_12' AS franja UNION ALL
  SELECT 'hasta_19' UNION ALL
  SELECT 'hasta_22' UNION ALL
  SELECT 'madrugada'
) fr;

SELECT 'Tabla tarifas_horas creada correctamente.' AS mensaje;
