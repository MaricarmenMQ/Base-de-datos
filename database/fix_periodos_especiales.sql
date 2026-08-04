USE hotel_system;

CREATE TABLE IF NOT EXISTS periodos_especiales (
  id            INT AUTO_INCREMENT PRIMARY KEY,
  nombre        VARCHAR(100) NOT NULL,
  tipo          ENUM('semana', 'fiestas', 'agosto', 'personalizado') NOT NULL,
  fecha_inicio  DATE NOT NULL,
  fecha_fin     DATE NOT NULL,
  activo        BOOLEAN NOT NULL DEFAULT TRUE,
  creado_en     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

  INDEX idx_periodos_fechas (fecha_inicio, fecha_fin),
  INDEX idx_periodos_activo (activo)
) ENGINE=InnoDB;

SELECT 'Tabla periodos_especiales creada correctamente.' AS mensaje;
