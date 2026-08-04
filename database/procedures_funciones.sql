-- ============================================================================
-- HOTEL MANAGEMENT SYSTEM - FUNCIONES Y PROCEDIMIENTOS ALMACENADOS
-- Complemento a schema.sql (que ya trae triggers y vistas)
-- Motor: MySQL 8.0+ / MariaDB 10.5+
-- ============================================================================
-- Filosofía: el gestor de BD hace el trabajo pesado (cálculo de precios,
-- validación de disponibilidad, control de stock), no la lógica de la app.
-- ============================================================================

USE hotel_system;

DELIMITER $$

-- ============================================================================
-- FUNCIÓN 1: fn_calcular_precio_reserva
-- Calcula el precio total de una estadía según tipo de habitación,
-- temporada vigente (si aplica) y número de noches.
-- ============================================================================
DROP FUNCTION IF EXISTS fn_calcular_precio_reserva$$

CREATE FUNCTION fn_calcular_precio_reserva(
  p_habitacion_id  INT,
  p_fecha_checkin  DATETIME,
  p_fecha_checkout DATETIME
) RETURNS DECIMAL(10,2)
DETERMINISTIC
READS SQL DATA
BEGIN
  DECLARE v_tipo            VARCHAR(30);
  DECLARE v_precio_base     DECIMAL(10,2);
  DECLARE v_noches          INT;
  DECLARE v_precio_temporada DECIMAL(10,2);
  DECLARE v_total           DECIMAL(10,2);

  -- Datos base de la habitación
  SELECT tipo, precio_base_noche
    INTO v_tipo, v_precio_base
  FROM habitaciones
  WHERE id = p_habitacion_id;

  -- Mínimo 1 noche (evita precio 0 en reservas del mismo día)
  SET v_noches = GREATEST(DATEDIFF(p_fecha_checkout, p_fecha_checkin), 1);

  -- ¿El check-in cae dentro de alguna temporada activa con tarifa
  -- especial para este tipo de habitación?
  SELECT tnt.precio
    INTO v_precio_temporada
  FROM temporadas t
  JOIN tarifas_noche_temporada tnt ON tnt.temporada_id = t.id
  WHERE t.activo = TRUE
    AND DATE(p_fecha_checkin) BETWEEN t.fecha_inicio AND t.fecha_fin
    AND tnt.tipo_habitacion = v_tipo
  LIMIT 1;

  IF v_precio_temporada IS NOT NULL THEN
    SET v_total = v_precio_temporada * v_noches;
  ELSE
    SET v_total = v_precio_base * v_noches;
  END IF;

  RETURN v_total;
END$$

-- ============================================================================
-- FUNCIÓN 2: fn_habitacion_disponible
-- Devuelve 1 si la habitación está libre en el rango de fechas dado
-- (sin cruce con otra reserva activa o de fecha abierta), 0 si no.
-- ============================================================================
DROP FUNCTION IF EXISTS fn_habitacion_disponible$$

CREATE FUNCTION fn_habitacion_disponible(
  p_habitacion_id  INT,
  p_fecha_checkin  DATETIME,
  p_fecha_checkout DATETIME
) RETURNS TINYINT(1)
DETERMINISTIC
READS SQL DATA
BEGIN
  DECLARE v_conflictos INT;

  SELECT COUNT(*)
    INTO v_conflictos
  FROM reservas
  WHERE habitacion_id = p_habitacion_id
    AND estado IN ('activa', 'fecha_abierta')
    AND fecha_check_in < p_fecha_checkout
    AND COALESCE(fecha_check_out, DATE_ADD(fecha_check_in, INTERVAL 1 YEAR)) > p_fecha_checkin;

  RETURN v_conflictos = 0;
END$$

-- ============================================================================
-- PROCEDIMIENTO 1: sp_crear_reserva
-- Valida disponibilidad (fn_habitacion_disponible), calcula el precio
-- (fn_calcular_precio_reserva), genera código único, inserta la reserva
-- y marca la habitación como reservada. El trigger tr_reserva_actualiza_cliente
-- ya existente se encarga del resto cuando se haga el check-out.
-- ============================================================================
DROP PROCEDURE IF EXISTS sp_crear_reserva$$

CREATE PROCEDURE sp_crear_reserva(
  IN  p_cliente_id       INT,
  IN  p_habitacion_id    INT,
  IN  p_recepcionista_id INT,
  IN  p_fecha_checkin    DATETIME,
  IN  p_fecha_checkout   DATETIME,
  IN  p_metodo_pago      VARCHAR(20),
  OUT p_reserva_id       INT,
  OUT p_mensaje          VARCHAR(255)
)
BEGIN
  DECLARE v_disponible TINYINT;
  DECLARE v_precio     DECIMAL(10,2);
  DECLARE v_codigo     VARCHAR(20);

  SET v_disponible = fn_habitacion_disponible(p_habitacion_id, p_fecha_checkin, p_fecha_checkout);

  IF v_disponible = 0 THEN
    SET p_reserva_id = NULL;
    SET p_mensaje = 'La habitación no está disponible en esas fechas.';
  ELSE
    SET v_precio = fn_calcular_precio_reserva(p_habitacion_id, p_fecha_checkin, p_fecha_checkout);
    SET v_codigo = CONCAT('RES-', DATE_FORMAT(NOW(), '%Y%m%d'), '-', LPAD(FLOOR(RAND() * 10000), 4, '0'));

    INSERT INTO reservas (
      codigo, cliente_id, habitacion_id, recepcionista_id,
      fecha_check_in, fecha_check_out, tipo_estancia,
      precio_total, estado_pago, metodo_pago, estado, origen
    ) VALUES (
      v_codigo, p_cliente_id, p_habitacion_id, p_recepcionista_id,
      p_fecha_checkin, p_fecha_checkout, 'por_noche',
      v_precio, 'pendiente', p_metodo_pago, 'activa', 'presencial'
    );

    SET p_reserva_id = LAST_INSERT_ID();

    UPDATE habitaciones
    SET estado_ocupacion = 'reservada'
    WHERE id = p_habitacion_id;

    SET p_mensaje = CONCAT('Reserva creada: ', v_codigo, ' — Total: S/ ', v_precio);
  END IF;
END$$

-- ============================================================================
-- PROCEDIMIENTO 2: sp_registrar_venta_producto
-- Registra la venta de un producto asociada (o no) a una reserva,
-- valida y descuenta stock cuando aplica.
-- ============================================================================
DROP PROCEDURE IF EXISTS sp_registrar_venta_producto$$

CREATE PROCEDURE sp_registrar_venta_producto(
  IN  p_reserva_id  INT,
  IN  p_producto_id INT,
  IN  p_cantidad    INT,
  IN  p_usuario_id  INT,
  OUT p_mensaje     VARCHAR(255)
)
BEGIN
  DECLARE v_stock  INT;
  DECLARE v_precio DECIMAL(10,2);

  SELECT stock, precio
    INTO v_stock, v_precio
  FROM productos
  WHERE id = p_producto_id;

  IF v_stock IS NOT NULL AND v_stock < p_cantidad THEN
    SET p_mensaje = CONCAT('Stock insuficiente. Disponible: ', v_stock);
  ELSE
    INSERT INTO ventas_productos (
      reserva_id, producto_id, cantidad, precio_unitario, vendido_por_usuario_id
    ) VALUES (
      p_reserva_id, p_producto_id, p_cantidad, v_precio, p_usuario_id
    );

    IF v_stock IS NOT NULL THEN
      UPDATE productos SET stock = stock - p_cantidad WHERE id = p_producto_id;
    END IF;

    SET p_mensaje = 'Venta registrada correctamente.';
  END IF;
END$$

DELIMITER ;

SELECT 'Funciones y procedimientos creados correctamente.' AS mensaje;
