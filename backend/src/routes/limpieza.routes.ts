import { Router } from 'express';
import { z } from 'zod';
import { LimpiezaModel } from '../models/limpieza.model.js';
import { asyncHandler } from '../utils/asyncHandler.js';
import { requireAuth, requireRole } from '../middleware/auth.js';
import { NotFoundError, ConflictError, ForbiddenError } from '../utils/errors.js';
import { getSocketServer, emitToRoom } from '../sockets/index.js';

export const limpiezaRouter = Router();
limpiezaRouter.use(requireAuth);

// ----------------------------------------------------------------------------
// GET /api/limpieza/pendientes - lista de habitaciones por limpiar / en limpieza
// ----------------------------------------------------------------------------
limpiezaRouter.get(
  '/pendientes',
  asyncHandler(async (_req, res) => {
    const lista = await LimpiezaModel.listPendientes();
    res.json(lista);
  })
);

// ----------------------------------------------------------------------------
// POST /api/limpieza/:id/tomar - limpiadora toma la habitación
// ----------------------------------------------------------------------------
const tomarSchema = z.object({
  turno: z.enum(['mañana', 'tarde', 'noche']).default('mañana'),
});

limpiezaRouter.post(
  '/:id/tomar',
  requireRole('limpieza', 'admin'),
  asyncHandler(async (req, res) => {
    const id = Number(req.params.id);
    const { turno } = tomarSchema.parse(req.body);

    const registro = await LimpiezaModel.findById(id);
    if (!registro) throw new NotFoundError('Registro de limpieza no encontrado');
    if (registro.estado !== 'pendiente') {
      throw new ConflictError('Esta habitación ya fue tomada por otra persona');
    }

    await LimpiezaModel.tomar(id, req.user!.userId, turno);
    const updated = await LimpiezaModel.findById(id);

    // Notificar a recepción y admin
    emitToRoom('admin', 'limpieza:cambio', updated);
    emitToRoom('recepcion', 'limpieza:cambio', updated);
    emitToRoom('limpieza', 'limpieza:cambio', updated);

    res.json(updated);
  })
);

// ----------------------------------------------------------------------------
// POST /api/limpieza/:id/completar - limpiadora marca como limpia
// ----------------------------------------------------------------------------
const completarSchema = z.object({
  notas: z.string().max(1000).optional(),
});

limpiezaRouter.post(
  '/:id/completar',
  requireRole('limpieza', 'admin'),
  asyncHandler(async (req, res) => {
    const id = Number(req.params.id);
    const { notas } = completarSchema.parse(req.body);

    const registro = await LimpiezaModel.findById(id);
    if (!registro) throw new NotFoundError('Registro no encontrado');
    if (registro.estado !== 'en_progreso') {
      throw new ConflictError('Solo se pueden completar limpiezas en progreso');
    }
    if (registro.empleado_limpieza_id !== req.user!.userId && req.user!.rol !== 'admin') {
      throw new ForbiddenError('Solo quien tomó la habitación puede marcarla como limpia');
    }

    await LimpiezaModel.marcarCompletada(id, req.user!.userId, notas);
    const updated = await LimpiezaModel.findById(id);

    // 🔔 Notificación clave: avisar a recepción que hay una habitación lista para validar
    emitToRoom('recepcion', 'limpieza:lista_para_validar', updated);
    emitToRoom('admin', 'limpieza:lista_para_validar', updated);
    emitToRoom('limpieza', 'limpieza:cambio', updated);
    emitToRoom('admin', 'limpieza:cambio', updated);

    res.json(updated);
  })
);

// ----------------------------------------------------------------------------
// POST /api/limpieza/:id/validar - recepción valida (habitación queda disponible)
// ----------------------------------------------------------------------------
const validarSchema = z.object({
  notas: z.string().max(1000).optional(),
});

limpiezaRouter.post(
  '/:id/validar',
  requireRole('admin', 'recepcionista'),
  asyncHandler(async (req, res) => {
    const id = Number(req.params.id);
    const { notas } = validarSchema.parse(req.body);

    const registro = await LimpiezaModel.findById(id);
    if (!registro) throw new NotFoundError('Registro no encontrado');
    if (registro.estado !== 'completada_por_limpieza') {
      throw new ConflictError('Esta limpieza no está esperando validación');
    }

    await LimpiezaModel.validar(id, req.user!.userId, notas);
    const updated = await LimpiezaModel.findById(id);

    // Notificar a todos
    const io = getSocketServer();
    io.emit('habitacion:disponible', { habitacion_id: registro.habitacion_id });
    emitToRoom('limpieza', 'limpieza:validada', updated);
    emitToRoom('recepcion', 'limpieza:validada', updated);
    emitToRoom('admin', 'limpieza:validada', updated);

    res.json(updated);
  })
);

// ----------------------------------------------------------------------------
// POST /api/limpieza/:id/rechazar - recepción rechaza limpieza
// ----------------------------------------------------------------------------
const rechazarSchema = z.object({
  motivo: z.string().min(3).max(1000),
});

limpiezaRouter.post(
  '/:id/rechazar',
  requireRole('admin', 'recepcionista'),
  asyncHandler(async (req, res) => {
    const id = Number(req.params.id);
    const { motivo } = rechazarSchema.parse(req.body);

    const registro = await LimpiezaModel.findById(id);
    if (!registro) throw new NotFoundError('Registro no encontrado');
    if (registro.estado !== 'completada_por_limpieza') {
      throw new ConflictError('Solo se puede rechazar limpiezas pendientes de validación');
    }

    await LimpiezaModel.rechazar(id, req.user!.userId, motivo);
    const updated = await LimpiezaModel.findById(id);

    emitToRoom('limpieza', 'limpieza:rechazada', { ...updated, motivo });
    emitToRoom('recepcion', 'limpieza:rechazada', updated);
    emitToRoom('admin', 'limpieza:rechazada', updated);

    res.json(updated);
  })
);

// ----------------------------------------------------------------------------
// GET /api/limpieza/stats - estadísticas por empleado
// ----------------------------------------------------------------------------
limpiezaRouter.get(
  '/stats',
  requireRole('admin', 'recepcionista'),
  asyncHandler(async (req, res) => {
    const desde = typeof req.query.desde === 'string' ? req.query.desde : undefined;
    const hasta = typeof req.query.hasta === 'string' ? req.query.hasta : undefined;
    const stats = await LimpiezaModel.statsPorEmpleado(desde, hasta);
    res.json(stats);
  })
);
