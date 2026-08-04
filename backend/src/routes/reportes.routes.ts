import { Router } from 'express';
import { db } from '../config/db.js';
import type { RowDataPacket } from 'mysql2';
import { asyncHandler } from '../utils/asyncHandler.js';
import { requireAuth, requireRole } from '../middleware/auth.js';

export const reportesRouter = Router();

reportesRouter.use(requireAuth, requireRole('admin', 'recepcionista'));

// ----------------------------------------------------------------------------
// GET /api/reportes/ocupacion
// ----------------------------------------------------------------------------
reportesRouter.get(
  '/ocupacion',
  asyncHandler(async (req, res) => {
    const desde =
      typeof req.query.desde === 'string' && req.query.desde
        ? req.query.desde
        : null;
    const hasta =
      typeof req.query.hasta === 'string' && req.query.hasta
        ? req.query.hasta
        : null;

    const where: string[] = [];
    const params: unknown[] = [];
    if (desde) {
      where.push('DATE(r.fecha_check_in) >= ?');
      params.push(desde);
    }
    if (hasta) {
      where.push('DATE(r.fecha_check_in) <= ?');
      params.push(hasta);
    }
    const whereClause = where.length > 0 ? 'WHERE ' + where.join(' AND ') : '';

    const [totalRows] = await db.query<RowDataPacket[]>(
      'SELECT COUNT(*) AS total FROM habitaciones'
    );
    const totalHabs = Number(totalRows[0]?.total) || 25;

    const [porDia] = await db.query<RowDataPacket[]>(
      `SELECT
         DATE(r.fecha_check_in) AS fecha,
         COUNT(DISTINCT r.habitacion_id) AS habs_ocupadas,
         COUNT(r.id) AS num_reservas,
         COALESCE(SUM(r.precio_total), 0) AS ingresos
       FROM reservas r
       ${whereClause}
       GROUP BY DATE(r.fecha_check_in)
       ORDER BY fecha DESC
       LIMIT 60`,
      params
    );

    const enriched = porDia.map((d) => ({
      fecha: d.fecha,
      habs_ocupadas: Number(d.habs_ocupadas) || 0,
      num_reservas: Number(d.num_reservas) || 0,
      ingresos: Number(d.ingresos) || 0,
      total_habs: totalHabs,
      tasa_ocupacion:
        totalHabs > 0
          ? Math.round((Number(d.habs_ocupadas) / totalHabs) * 100)
          : 0,
    }));

    res.json(enriched);
  })
);

// ----------------------------------------------------------------------------
// GET /api/reportes/ingresos
// ----------------------------------------------------------------------------
reportesRouter.get(
  '/ingresos',
  asyncHandler(async (req, res) => {
    const desde =
      typeof req.query.desde === 'string' && req.query.desde
        ? req.query.desde
        : null;
    const hasta =
      typeof req.query.hasta === 'string' && req.query.hasta
        ? req.query.hasta
        : null;

    const buildReservasWhere = (): { sql: string; params: unknown[] } => {
      const w: string[] = [];
      const p: unknown[] = [];
      if (desde) {
        w.push('DATE(fecha_check_in) >= ?');
        p.push(desde);
      }
      if (hasta) {
        w.push('DATE(fecha_check_in) <= ?');
        p.push(hasta);
      }
      return { sql: w.length > 0 ? 'WHERE ' + w.join(' AND ') : '', params: p };
    };

    // FIX: fecha_venta (no fecha)
    const buildVentasWhere = (): { sql: string; params: unknown[] } => {
      const w: string[] = [];
      const p: unknown[] = [];
      if (desde) {
        w.push('DATE(fecha_venta) >= ?');
        p.push(desde);
      }
      if (hasta) {
        w.push('DATE(fecha_venta) <= ?');
        p.push(hasta);
      }
      return { sql: w.length > 0 ? 'WHERE ' + w.join(' AND ') : '', params: p };
    };

    const wR1 = buildReservasWhere();
    const [reservas] = await db.query<RowDataPacket[]>(
      `SELECT
         COUNT(*) AS num_reservas,
         COALESCE(SUM(precio_total), 0) AS ingresos_reservas,
         COALESCE(SUM(monto_pagado), 0) AS pagado_reservas
       FROM reservas ${wR1.sql}`,
      wR1.params
    );

    const wV = buildVentasWhere();
    const [ventas] = await db.query<RowDataPacket[]>(
      `SELECT
         COUNT(*) AS num_ventas,
         COALESCE(SUM(subtotal), 0) AS ingresos_ventas
       FROM ventas_productos ${wV.sql}`,
      wV.params
    );

    const wR2 = buildReservasWhere();
    const extraWhere = wR2.sql
      ? `${wR2.sql} AND metodo_pago IS NOT NULL`
      : 'WHERE metodo_pago IS NOT NULL';

    const [porMetodo] = await db.query<RowDataPacket[]>(
      `SELECT
         metodo_pago,
         COUNT(*) AS num,
         COALESCE(SUM(monto_pagado), 0) AS total
       FROM reservas ${extraWhere}
       GROUP BY metodo_pago
       ORDER BY total DESC`,
      wR2.params
    );

    const totalGeneral =
      Number(reservas[0]?.pagado_reservas || 0) +
      Number(ventas[0]?.ingresos_ventas || 0);

    res.json({
      reservas: {
        num_reservas: Number(reservas[0]?.num_reservas) || 0,
        ingresos_reservas: Number(reservas[0]?.ingresos_reservas) || 0,
        pagado_reservas: Number(reservas[0]?.pagado_reservas) || 0,
      },
      ventas: {
        num_ventas: Number(ventas[0]?.num_ventas) || 0,
        ingresos_ventas: Number(ventas[0]?.ingresos_ventas) || 0,
      },
      por_metodo: porMetodo.map((m) => ({
        metodo_pago: m.metodo_pago,
        num: Number(m.num) || 0,
        total: Number(m.total) || 0,
      })),
      total_general: totalGeneral,
    });
  })
);

// ----------------------------------------------------------------------------
// GET /api/reportes/clientes-top
// ----------------------------------------------------------------------------
reportesRouter.get(
  '/clientes-top',
  asyncHandler(async (_req, res) => {
    const [rows] = await db.query<RowDataPacket[]>(
      `SELECT id, nombres, apellidos, tipo_documento, numero_documento,
              tipo_cliente, total_estancias, monto_total_gastado, fecha_ultima_estancia
       FROM clientes
       WHERE activo = TRUE
       ORDER BY monto_total_gastado DESC
       LIMIT 20`
    );
    res.json(rows);
  })
);
