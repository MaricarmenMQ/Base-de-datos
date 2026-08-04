import { Router } from 'express';
import { z } from 'zod';
import { UsuarioModel } from '../models/usuario.model.js';
import {
  signAccessToken,
  signRefreshToken,
  verifyPassword,
  verifyRefreshToken,
} from '../utils/auth.js';
import { asyncHandler } from '../utils/asyncHandler.js';
import { UnauthorizedError } from '../utils/errors.js';
import { requireAuth } from '../middleware/auth.js';

export const authRouter = Router();

// ----------------------------------------------------------------------------
// POST /api/auth/login
// ----------------------------------------------------------------------------
const loginSchema = z.object({
  username: z.string().min(1, 'Username requerido'),
  password: z.string().min(1, 'Contraseña requerida'),
});

authRouter.post(
  '/login',
  asyncHandler(async (req, res) => {
    const { username, password } = loginSchema.parse(req.body);

    const usuario = await UsuarioModel.findByUsername(username);
    if (!usuario) {
      throw new UnauthorizedError('Usuario o contraseña incorrectos');
    }

    const valid = await verifyPassword(password, usuario.password_hash);
    if (!valid) {
      throw new UnauthorizedError('Usuario o contraseña incorrectos');
    }

    // Token payload (lo mínimo necesario)
    const payload = {
      userId: usuario.id,
      username: usuario.username,
      rol: usuario.rol,
    };

    const accessToken = signAccessToken(payload);
    const refreshToken = signRefreshToken(payload);

    // Última sesión (no bloqueante)
    UsuarioModel.updateLastLogin(usuario.id).catch(() => {
      /* logging mínimo, no falla el login */
    });

    res.json({
      accessToken,
      refreshToken,
      user: {
        id: usuario.id,
        username: usuario.username,
        nombres: usuario.nombres,
        apellidos: usuario.apellidos,
        rol: usuario.rol,
        email: usuario.email,
      },
    });
  })
);

// ----------------------------------------------------------------------------
// POST /api/auth/refresh
// ----------------------------------------------------------------------------
const refreshSchema = z.object({
  refreshToken: z.string().min(1),
});

authRouter.post(
  '/refresh',
  asyncHandler(async (req, res) => {
    const { refreshToken } = refreshSchema.parse(req.body);

    let payload;
    try {
      payload = verifyRefreshToken(refreshToken);
    } catch {
      throw new UnauthorizedError('Refresh token inválido o expirado');
    }

    // Verificar que el usuario siga activo
    const usuario = await UsuarioModel.findById(payload.userId);
    if (!usuario) {
      throw new UnauthorizedError('Usuario no encontrado o inactivo');
    }

    const newPayload = {
      userId: usuario.id,
      username: usuario.username,
      rol: usuario.rol,
    };

    res.json({
      accessToken: signAccessToken(newPayload),
      refreshToken: signRefreshToken(newPayload),
    });
  })
);

// ----------------------------------------------------------------------------
// GET /api/auth/me - Devuelve los datos del usuario autenticado
// ----------------------------------------------------------------------------
authRouter.get(
  '/me',
  requireAuth,
  asyncHandler(async (req, res) => {
    const usuario = await UsuarioModel.findById(req.user!.userId);
    if (!usuario) {
      throw new UnauthorizedError();
    }
    res.json({
      id: usuario.id,
      username: usuario.username,
      nombres: usuario.nombres,
      apellidos: usuario.apellidos,
      rol: usuario.rol,
      email: usuario.email,
    });
  })
);
