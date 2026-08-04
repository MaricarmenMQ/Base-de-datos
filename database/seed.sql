-- ============================================================================
-- SEED DATA v2 - DATOS REALES DEL HOTEL DEL CLIENTE
-- Ejecutar DESPUÉS de schema.sql
-- ============================================================================
-- Fuente: hotel_admin_completo.html (especificaciones del cliente)
-- ============================================================================

USE hotel_system;

-- ----------------------------------------------------------------------------
-- USUARIOS DEL SISTEMA
-- ----------------------------------------------------------------------------
-- Las contraseñas en SQL son PLACEHOLDERS. Para activar logins, después de
-- importar este SQL ejecuta desde el backend (Fase 2): npm run seed:passwords
--
-- Equivalencias en texto plano (después de seed:passwords):
--   admin       → "admin123"
--   recep1/2/3  → "recep123"
--   limpieza1/2 → "limp123"
-- ----------------------------------------------------------------------------

INSERT INTO usuarios (username, password_hash, nombres, apellidos, dni, email, rol, turno, hora_inicio_turno, hora_fin_turno, salario, activo) VALUES
('admin',     'PLACEHOLDER_RUN_SEED_PASSWORDS', 'Administrador', 'del Sistema', '00000001', 'admin@hotel.local',           'admin',         'rotativo', '08:00:00', '18:00:00', 4500.00, TRUE),
('recep1',    'PLACEHOLDER_RUN_SEED_PASSWORDS', 'María',        'González',     '12345678', 'maria.gonzalez@hotel.local',  'recepcionista', 'mañana',   '07:00:00', '15:00:00', 2200.00, TRUE),
('recep2',    'PLACEHOLDER_RUN_SEED_PASSWORDS', 'Carlos',       'Ramírez',      '23456789', 'carlos.ramirez@hotel.local',  'recepcionista', 'tarde',    '15:00:00', '23:00:00', 2100.00, TRUE),
('recep3',    'PLACEHOLDER_RUN_SEED_PASSWORDS', 'Lucía',        'Vargas',       '34567890', 'lucia.vargas@hotel.local',    'recepcionista', 'noche',    '23:00:00', '07:00:00', 2300.00, TRUE),
('limpieza1', 'PLACEHOLDER_RUN_SEED_PASSWORDS', 'Juanita',      'Sánchez',      '45678901', 'juanita.sanchez@hotel.local', 'limpieza',      'mañana',   '07:00:00', '15:00:00', 1500.00, TRUE),
('limpieza2', 'PLACEHOLDER_RUN_SEED_PASSWORDS', 'Rosa',         'Quispe',       '56789012', 'rosa.quispe@hotel.local',     'limpieza',      'tarde',    '15:00:00', '23:00:00', 1500.00, TRUE);

-- ----------------------------------------------------------------------------
-- CLIENTES (con campos REALES del registro: 12 campos del cliente)
-- ----------------------------------------------------------------------------
INSERT INTO clientes (tipo_documento, numero_documento, nombres, apellidos, fecha_nacimiento, nacionalidad, procedencia, motivo_viaje, telefono, email, direccion, tipo_cliente, descuento_porcentaje, total_estancias, monto_total_gastado, fecha_ultima_estancia) VALUES
('DNI',       '70123456', 'Juan',     'Pérez Llamoja',     '1985-04-12', 'Peruana',  'Lima',        'turismo',  '+51 987 654 321',  'juan.perez@email.com',     'Av. Arequipa 1234, Lima',     'frecuente', 10.00, 12, 850.00,  '2026-04-15'),
('DNI',       '70234567', 'Ana',      'Martínez Salas',    '1990-09-23', 'Peruana',  'Arequipa',    'negocios', '+51 956 234 567',  'ana.martinez@email.com',   'Jr. Cusco 567, Lima',         'temporal',  0.00,   1, 70.00,   '2026-04-28'),
('Pasaporte', 'AB123456', 'Robert',   'Smith',             '1978-11-05', 'Británica','London, UK',  'turismo',  '+44 20 1234 5678', 'robert.smith@email.com',   '10 Downing St, London',       'temporal',  0.00,   1, 350.00,  '2026-04-29'),
('CI',        'FR987654', 'Sophie',   'Laurent',           '1992-02-18', 'Francesa', 'Paris',       'turismo',  '+33 1 23 45 67 89','sophie.laurent@email.com', '5 Rue de Paris',              'temporal',  0.00,   1, 220.00,  '2026-04-30'),
('DNI',       '70345678', 'Carlos',   'López Ríos',        '1980-07-30', 'Peruana',  'Cusco',       'familia',  '+51 922 345 678',  'carlos.lopez@email.com',   'Av. Brasil 890, Lima',        'frecuente', 15.00, 28, 2100.00, '2026-04-20'),
('DNI',       '70456789', 'Patricia', 'Mendoza Flores',    '1988-12-10', 'Peruana',  'Trujillo',    'negocios', '+51 944 567 890',  'patricia.mendoza@email.com','Calle Los Pinos 234, Lima',  'temporal',  0.00,   2, 130.00,  '2026-03-15');

-- ============================================================================
-- HABITACIONES REALES DEL CLIENTE (25 habitaciones, 3 pisos: 2, 3, 4)
-- ============================================================================
-- Mapeo de tipos del HTML → ENUM del schema:
--   "Matrimonial privada c/n ducha y baño" → matrimonial_privada_ducha
--   "Matrimonial c/n baño" / "solo c/n baño" → matrimonial_bano
--   "TV cable"                              → tv_cable
--   "Simple"                                → simple
--   "Doble privada baño y ducha"            → doble_privada
--   "Doble c/n TV cable" / "Doble familiar..." → doble_tv_cable / doble_privada
-- ============================================================================

-- ----------------------------------------------------------------------------
-- PISO 2 (8 habitaciones: 201-208)
-- ----------------------------------------------------------------------------
INSERT INTO habitaciones (numero, piso, tipo, capacidad, bano_privado, tiene_ducha, tiene_tv, tiene_cable_tv, tiene_control_remoto, tiene_wifi, precio_base_noche, estado_ocupacion, estado_limpieza) VALUES
('201', 2, 'matrimonial_privada_ducha', 2, TRUE,  TRUE,  FALSE, FALSE, FALSE, TRUE, 50.00,  'disponible', 'limpia'),
('202', 2, 'tv_cable',                  2, TRUE,  TRUE,  TRUE,  TRUE,  TRUE,  TRUE, 35.00,  'disponible', 'limpia'),
('203', 2, 'doble_privada',             3, TRUE,  TRUE,  FALSE, FALSE, FALSE, TRUE, 70.00,  'ocupada',    'limpia'),
('204', 2, 'matrimonial_privada_ducha', 2, TRUE,  TRUE,  FALSE, FALSE, FALSE, TRUE, 50.00,  'disponible', 'limpia'),
('205', 2, 'matrimonial_bano',          2, TRUE,  FALSE, FALSE, FALSE, FALSE, TRUE, 40.00,  'disponible', 'limpia'),
('206', 2, 'doble_tv_cable',            3, TRUE,  TRUE,  TRUE,  TRUE,  TRUE,  TRUE, 50.00,  'ocupada',    'sucia'),
('207', 2, 'tv_cable',                  2, TRUE,  TRUE,  TRUE,  TRUE,  TRUE,  TRUE, 35.00,  'disponible', 'limpia'),
('208', 2, 'matrimonial_bano',          2, TRUE,  FALSE, FALSE, FALSE, FALSE, TRUE, 40.00,  'reservada',  'limpia');

-- ----------------------------------------------------------------------------
-- PISO 3 (9 habitaciones: 301-309)
-- ----------------------------------------------------------------------------
INSERT INTO habitaciones (numero, piso, tipo, capacidad, bano_privado, tiene_ducha, tiene_tv, tiene_cable_tv, tiene_control_remoto, tiene_wifi, precio_base_noche, estado_ocupacion, estado_limpieza) VALUES
('301', 3, 'tv_cable',                  2, TRUE,  TRUE,  TRUE,  TRUE,  TRUE,  TRUE, 35.00,  'disponible', 'limpia'),
('302', 3, 'tv_cable',                  2, TRUE,  TRUE,  TRUE,  TRUE,  TRUE,  TRUE, 35.00,  'disponible', 'limpia'),
('303', 3, 'matrimonial_privada_ducha', 2, TRUE,  TRUE,  FALSE, FALSE, FALSE, TRUE, 50.00,  'ocupada',    'limpia'),
('304', 3, 'matrimonial_privada_ducha', 2, TRUE,  TRUE,  FALSE, FALSE, FALSE, TRUE, 50.00,  'disponible', 'limpia'),
('305', 3, 'doble_tv_cable',            3, TRUE,  TRUE,  TRUE,  TRUE,  TRUE,  TRUE, 50.00,  'disponible', 'en_limpieza'),
('306', 3, 'matrimonial_privada_ducha', 2, TRUE,  TRUE,  FALSE, FALSE, FALSE, TRUE, 50.00,  'ocupada',    'limpia'),
('307', 3, 'tv_cable',                  2, TRUE,  TRUE,  TRUE,  TRUE,  TRUE,  TRUE, 35.00,  'disponible', 'limpia'),
('308', 3, 'simple',                    1, TRUE,  TRUE,  FALSE, FALSE, FALSE, TRUE, 25.00,  'disponible', 'limpia'),
('309', 3, 'simple',                    1, TRUE,  TRUE,  FALSE, FALSE, FALSE, TRUE, 25.00,  'disponible', 'limpia');

-- ----------------------------------------------------------------------------
-- PISO 4 (8 habitaciones: 401-408)
-- ----------------------------------------------------------------------------
INSERT INTO habitaciones (numero, piso, tipo, capacidad, bano_privado, tiene_ducha, tiene_tv, tiene_cable_tv, tiene_control_remoto, tiene_wifi, precio_base_noche, estado_ocupacion, estado_limpieza) VALUES
('401', 4, 'matrimonial_privada_ducha', 2, TRUE,  TRUE,  FALSE, FALSE, FALSE, TRUE, 50.00,  'disponible', 'limpia'),
('402', 4, 'tv_cable',                  2, TRUE,  TRUE,  TRUE,  TRUE,  TRUE,  TRUE, 35.00,  'disponible', 'limpia'),
('403', 4, 'matrimonial_privada_ducha', 2, TRUE,  TRUE,  FALSE, FALSE, FALSE, TRUE, 50.00,  'ocupada',    'limpia'),
('404', 4, 'matrimonial_privada_ducha', 2, TRUE,  TRUE,  FALSE, FALSE, FALSE, TRUE, 50.00,  'disponible', 'limpia'),
('405', 4, 'matrimonial_privada_ducha', 2, TRUE,  TRUE,  FALSE, FALSE, FALSE, TRUE, 50.00,  'disponible', 'limpia'),
('406', 4, 'matrimonial_privada_ducha', 2, TRUE,  TRUE,  FALSE, FALSE, FALSE, TRUE, 50.00,  'disponible', 'limpia'),
('407', 4, 'tv_cable',                  2, TRUE,  TRUE,  TRUE,  TRUE,  TRUE,  TRUE, 35.00,  'disponible', 'limpia'),
('408', 4, 'tv_cable',                  2, TRUE,  TRUE,  TRUE,  TRUE,  TRUE,  TRUE, 35.00,  'disponible', 'limpia');

-- ============================================================================
-- CAMAS POR HABITACIÓN
-- ============================================================================
-- Asunciones (validar con cliente):
-- - Matrimoniales privadas y c/baño → 1 cama matrimonial
-- - TV cable → 1 cama matrimonial (tipo de cama no especificado en HTML)
-- - Simple → 1 cama individual
-- - Doble → 2 camas individuales (twin)
-- - Doble familiar → 1 matrimonial + 1 individual

INSERT INTO camas_habitacion (habitacion_id, tipo_cama, cantidad)
SELECT h.id, 'matrimonial', 1 FROM habitaciones h WHERE h.tipo IN ('matrimonial_privada_ducha','matrimonial_bano','tv_cable');

INSERT INTO camas_habitacion (habitacion_id, tipo_cama, cantidad)
SELECT h.id, 'individual', 1 FROM habitaciones h WHERE h.tipo = 'simple';

-- Habitación 203 - Doble familiar (matrimonial + individual)
INSERT INTO camas_habitacion (habitacion_id, tipo_cama, cantidad)
SELECT id, 'matrimonial', 1 FROM habitaciones WHERE numero = '203';
INSERT INTO camas_habitacion (habitacion_id, tipo_cama, cantidad)
SELECT id, 'individual', 1 FROM habitaciones WHERE numero = '203';

-- Habitaciones 206 y 305 - Doble c/n TV cable (2 individuales)
INSERT INTO camas_habitacion (habitacion_id, tipo_cama, cantidad)
SELECT id, 'individual', 2 FROM habitaciones WHERE numero IN ('206','305');

-- ============================================================================
-- TARIFAS POR FRANJA HORARIA - DATOS REALES DEL CLIENTE
-- ============================================================================
-- Franjas: 5am-12pm, 12pm-7pm, 7pm-10pm, 10pm-5am
-- ============================================================================

-- TIPO 1: Matrimonial privada c/n ducha
INSERT INTO tarifas_franjas (nombre, hora_inicio, hora_fin, tipo_habitacion, precio) VALUES
('Mat. privada c/ducha — 5am-12pm',  '05:00:00','12:00:00','matrimonial_privada_ducha', 35.00),
('Mat. privada c/ducha — 12pm-7pm',  '12:00:00','19:00:00','matrimonial_privada_ducha', 40.00),
('Mat. privada c/ducha — 7pm-10pm',  '19:00:00','22:00:00','matrimonial_privada_ducha', 50.00),
('Mat. privada c/ducha — 10pm-5am',  '22:00:00','05:00:00','matrimonial_privada_ducha', 70.00);

-- TIPO 2: Matrimonial solo c/baño
INSERT INTO tarifas_franjas (nombre, hora_inicio, hora_fin, tipo_habitacion, precio) VALUES
('Mat. c/baño — 5am-12pm',  '05:00:00','12:00:00','matrimonial_bano', 30.00),
('Mat. c/baño — 12pm-7pm',  '12:00:00','19:00:00','matrimonial_bano', 35.00),
('Mat. c/baño — 7pm-10pm',  '19:00:00','22:00:00','matrimonial_bano', 40.00),
('Mat. c/baño — 10pm-5am',  '22:00:00','05:00:00','matrimonial_bano', 50.00);

-- TIPO 3: TV cable
INSERT INTO tarifas_franjas (nombre, hora_inicio, hora_fin, tipo_habitacion, precio) VALUES
('TV cable — 5am-12pm',  '05:00:00','12:00:00','tv_cable', 25.00),
('TV cable — 12pm-7pm',  '12:00:00','19:00:00','tv_cable', 30.00),
('TV cable — 7pm-10pm',  '19:00:00','22:00:00','tv_cable', 35.00),
('TV cable — 10pm-5am',  '22:00:00','05:00:00','tv_cable', 40.00);

-- TIPO 4: Simple (no disponible 10pm-5am según el cliente)
INSERT INTO tarifas_franjas (nombre, hora_inicio, hora_fin, tipo_habitacion, precio) VALUES
('Simple — 5am-12pm',  '05:00:00','12:00:00','simple', 15.00),
('Simple — 12pm-7pm',  '12:00:00','19:00:00','simple', 20.00),
('Simple — 7pm-10pm',  '19:00:00','22:00:00','simple', 25.00),
('Simple — 10pm-5am',  '22:00:00','05:00:00','simple', NULL);   -- "—" en el HTML = no disponible

-- TIPO 5: Doble privada baño y ducha
INSERT INTO tarifas_franjas (nombre, hora_inicio, hora_fin, tipo_habitacion, precio) VALUES
('Doble privada — 5am-12pm',  '05:00:00','12:00:00','doble_privada', 50.00),
('Doble privada — 12pm-7pm',  '12:00:00','19:00:00','doble_privada', 60.00),
('Doble privada — 7pm-10pm',  '19:00:00','22:00:00','doble_privada', 70.00),
('Doble privada — 10pm-5am',  '22:00:00','05:00:00','doble_privada', 80.00);

-- TIPO 6: Doble c/n TV cable
INSERT INTO tarifas_franjas (nombre, hora_inicio, hora_fin, tipo_habitacion, precio) VALUES
('Doble TV cable — 5am-12pm',  '05:00:00','12:00:00','doble_tv_cable', 35.00),
('Doble TV cable — 12pm-7pm',  '12:00:00','19:00:00','doble_tv_cable', 45.00),
('Doble TV cable — 7pm-10pm',  '19:00:00','22:00:00','doble_tv_cable', 50.00),
('Doble TV cable — 10pm-5am',  '22:00:00','05:00:00','doble_tv_cable', 60.00);

-- ============================================================================
-- TEMPORADAS Y TARIFAS POR NOCHE COMPLETA - DATOS REALES DEL CLIENTE
-- ============================================================================
-- ⚠️ Aviso del cliente en el HTML: las columnas de Fiestas, Año Nuevo,
-- Semana Santa y Temporada Alta tienen "datos parcialmente inventados".
-- Los dejamos como están pero el cliente debe confirmar.
-- ============================================================================

INSERT INTO temporadas (nombre, tipo, fecha_inicio, fecha_fin, multiplicador_precio, notas) VALUES
('Tarifa Regular',           'regular',          '2026-01-01', '2026-12-31', 1.00, 'Tarifa base por noche'),
('Fiestas Patrias 2026',     'fiestas_patrias',  '2026-07-26', '2026-07-30', 1.40, 'Verificar precios con propietario'),
('Año Nuevo 2026-2027',      'año_nuevo',        '2026-12-29', '2027-01-02', 1.70, 'Verificar precios con propietario'),
('Semana Santa 2026',        'semana_santa',     '2026-03-29', '2026-04-05', 1.30, 'Verificar precios con propietario'),
('Temporada Alta 2026',      'temporada_alta',   '2026-07-01', '2026-08-31', 1.60, 'Verificar precios con propietario');

-- Tarifas por noche por tipo y temporada
-- Tipo 1: Matrimonial privada c/n ducha
INSERT INTO tarifas_noche_temporada (temporada_id, tipo_habitacion, precio) VALUES
(1, 'matrimonial_privada_ducha', 50.00),
(2, 'matrimonial_privada_ducha', 70.00),
(3, 'matrimonial_privada_ducha', 85.00),
(4, 'matrimonial_privada_ducha', 65.00),
(5, 'matrimonial_privada_ducha', 80.00);

-- Tipo 2: Matrimonial solo c/baño
INSERT INTO tarifas_noche_temporada (temporada_id, tipo_habitacion, precio) VALUES
(1, 'matrimonial_bano', 40.00),
(2, 'matrimonial_bano', 55.00),
(3, 'matrimonial_bano', 70.00),
(4, 'matrimonial_bano', 50.00),
(5, 'matrimonial_bano', 60.00);

-- Tipo 3: TV cable
INSERT INTO tarifas_noche_temporada (temporada_id, tipo_habitacion, precio) VALUES
(1, 'tv_cable', 35.00),
(2, 'tv_cable', 50.00),
(3, 'tv_cable', 60.00),
(4, 'tv_cable', 45.00),
(5, 'tv_cable', 55.00);

-- Tipo 4: Simple
INSERT INTO tarifas_noche_temporada (temporada_id, tipo_habitacion, precio) VALUES
(1, 'simple', 25.00),
(2, 'simple', 35.00),
(3, 'simple', 45.00),
(4, 'simple', 30.00),
(5, 'simple', 40.00);

-- Tipo 5: Doble privada baño y ducha
INSERT INTO tarifas_noche_temporada (temporada_id, tipo_habitacion, precio) VALUES
(1, 'doble_privada', 70.00),
(2, 'doble_privada', 95.00),
(3, 'doble_privada', 120.00),
(4, 'doble_privada', 90.00),
(5, 'doble_privada', 110.00);

-- Tipo 6: Doble c/n TV cable
INSERT INTO tarifas_noche_temporada (temporada_id, tipo_habitacion, precio) VALUES
(1, 'doble_tv_cable', 50.00),
(2, 'doble_tv_cable', 70.00),
(3, 'doble_tv_cable', 90.00),
(4, 'doble_tv_cable', 65.00),
(5, 'doble_tv_cable', 80.00);

-- ============================================================================
-- PRODUCTOS EN VENTA (los que pidió el cliente)
-- ============================================================================
INSERT INTO productos (nombre, categoria, precio, stock, descripcion, activo) VALUES
('Surtido / Cosas',         'surtido',     5.00,  NULL, 'Productos varios surtidos del hotel', TRUE),
('Alquiler de toalla',      'alquiler',    3.00,  20,   'Toalla extra (alquiler por estancia)', TRUE),
('Calefacción',             'servicio',    10.00, NULL, 'Servicio adicional de calefacción', TRUE);

-- ============================================================================
-- RESERVAS DE EJEMPLO (algunas activas para probar el flujo)
-- ============================================================================
-- IDs de habitación según orden de inserción:
--   Piso 2: 201=1, 202=2, 203=3, 204=4, 205=5, 206=6, 207=7, 208=8
--   Piso 3: 301=9, 302=10, 303=11, 304=12, 305=13, 306=14, 307=15, 308=16, 309=17
--   Piso 4: 401=18, 402=19, 403=20, 404=21, 405=22, 406=23, 407=24, 408=25

INSERT INTO reservas (codigo, cliente_id, habitacion_id, recepcionista_id, fecha_check_in, fecha_check_out, noches, tipo_estancia, precio_total, monto_pagado, estado_pago, metodo_pago, estado, origen) VALUES
('RES-2026-00001', 1, 3,  2, '2026-04-26 12:00:00', '2026-05-03 11:00:00', 7, 'por_noche',     441.00, 441.00, 'pagado',   'tarjeta',     'activa', 'presencial'),  -- Hab 203 → ID 3
('RES-2026-00002', 5, 6,  2, '2026-04-28 12:00:00', NULL,                  NULL, 'fecha_abierta', 0.00, 0.00,  'pendiente','efectivo',    'fecha_abierta', 'presencial'),   -- Hab 206 → ID 6
('RES-2026-00003', 3, 11, 3, '2026-04-29 12:00:00', '2026-05-04 11:00:00', 5, 'por_noche',     250.00, 100.00, 'parcial',  'online',      'activa', 'web'),         -- Hab 303 → ID 11
('RES-2026-00004', 4, 14, 2, '2026-04-30 12:00:00', '2026-05-02 11:00:00', 2, 'por_noche',     100.00, 0.00,   'pendiente','efectivo',    'activa', 'telefono'),    -- Hab 306 → ID 14
('RES-2026-00005', 5, 20, 3, '2026-05-01 12:00:00', '2026-05-06 11:00:00', 5, 'por_noche',     212.50, 212.50, 'pagado',   'transferencia','activa','presencial');  -- Hab 403 → ID 20 (con 15% descuento)

-- ============================================================================
-- INSUMOS ENTREGADOS (toalla, jabón, papel higiénico - los del cliente)
-- ============================================================================
-- Reserva 1: Juan recibió todos los insumos
INSERT INTO insumos_entregados (reserva_id, tipo_insumo, cantidad, entregado_por_usuario_id) VALUES
(1, 'toalla',          2, 5),
(1, 'jabon',           2, 5),
(1, 'papel_higienico', 1, 5);

-- Reserva 5: Carlos (cliente VIP) recibió insumos premium
INSERT INTO insumos_entregados (reserva_id, tipo_insumo, cantidad, entregado_por_usuario_id) VALUES
(5, 'toalla',          4, 6),
(5, 'jabon',           3, 6),
(5, 'papel_higienico', 2, 6);

-- ============================================================================
-- VENTAS DE PRODUCTOS (ejemplo: alquiler de toalla a la hab 203)
-- ============================================================================
INSERT INTO ventas_productos (reserva_id, producto_id, cantidad, precio_unitario, vendido_por_usuario_id) VALUES
(1, 2, 1, 3.00, 2);  -- Juan alquiló 1 toalla extra

-- ============================================================================
-- LIMPIEZA - registros para mostrar el flujo
-- ============================================================================
-- Hab 305 (Doble TV cable, piso 3) - en limpieza activa por Juanita
INSERT INTO limpieza_registros (habitacion_id, empleado_limpieza_id, turno, estado, fecha_inicio_limpieza) VALUES
(13, 5, 'mañana', 'en_progreso', '2026-05-01 09:30:00');

-- Hab 206 (Doble TV cable, piso 2) - sucia, esperando que limpiadora la tome
INSERT INTO limpieza_registros (habitacion_id, turno, estado) VALUES
(6, 'mañana', 'pendiente');

-- ============================================================================
-- TURNOS DE LIMPIEZA (resumen diario - lo del cliente)
-- ============================================================================
-- Las habitaciones rastreadas según el cliente: 102, 201–208, 301–309, 401–408
-- son 26 en total (en este sistema serían las 25 actuales + posible 102)

INSERT INTO turnos_limpieza (fecha, turno, encargado_id, hora_inicio, total_habitaciones_asignadas, total_habitaciones_limpiadas, notas) VALUES
('2026-05-01', 'mañana', 5, '2026-05-01 07:00:00', 25, 0,  'Turno mañana iniciado'),
('2026-04-30', 'tarde',  6, '2026-04-30 15:00:00', 25, 12, 'Turno tarde completado, 12/25 habitaciones limpiadas'),
('2026-04-30', 'mañana', 5, '2026-04-30 07:00:00', 25, 14, 'Turno mañana completado, 14/25 habitaciones limpiadas');

-- ============================================================================
-- OBJETOS PERDIDOS
-- ============================================================================
INSERT INTO objetos_perdidos (reserva_id, habitacion_id, descripcion, ubicacion, fecha_encontrado, reportado_por_usuario_id, estado) VALUES
(4, 14, 'Gafas de sol Ray-Ban', 'Mesa de noche - Hab 306', '2026-05-01', 5, 'en_custodia');

-- ============================================================================
-- CONFIGURACIÓN DEL HOTEL (datos reales del HTML)
-- ============================================================================
INSERT INTO configuracion_hotel (clave, valor, tipo, descripcion) VALUES
('hotel_nombre',                'Hotel',                            'string',  'Nombre comercial del hotel'),
('hotel_subtitulo',             'Sistema de gestión operativa',     'string',  'Subtítulo'),
('hotel_direccion',             'Lima, Perú',                       'string',  'Dirección del hotel'),
('hotel_telefono',              '+51 999 999 999',                  'string',  'Teléfono principal'),
('hotel_email',                 'contacto@hotel.local',             'string',  'Email de contacto'),
('hotel_ruc',                   '20123456789',                      'string',  'RUC del hotel'),
('moneda',                      'PEN',                              'string',  'Moneda (PEN/USD/EUR)'),
('moneda_simbolo',              'S/',                               'string',  'Símbolo de la moneda'),
('hora_check_in_default',       '12:00',                            'string',  'Hora estándar de check-in'),
('hora_check_out_default',      '11:00',                            'string',  'Hora estándar de check-out'),
('descuento_frecuente_default', '10',                               'number',  'Descuento % por defecto para clientes frecuentes'),
('estancias_para_frecuente',    '5',                                'number',  'Cantidad de estancias para auto-promoción a frecuente'),
('total_pisos',                 '3',                                'number',  'Cantidad de pisos del hotel'),
('total_habitaciones',          '25',                               'number',  'Cantidad total de habitaciones');

-- ============================================================================
-- FIN DEL SEED v2
-- ============================================================================
SELECT
  '✅ Seed v2 ejecutado correctamente.' AS estado,
  '⚠️ Recuerda: ejecutar `npm run seed:passwords` desde el backend (Fase 2) para activar los logins.' AS importante;
