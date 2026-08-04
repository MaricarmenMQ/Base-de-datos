import {
  BedDouble,
  CheckCircle2,
  Calendar,
  Sparkles,
  Users,
  AlertTriangle,
  Bookmark,
  Wrench,
} from 'lucide-react';
import { useApi } from '../../hooks/useApi';
import { api } from '../../services/api';
import { StatCard } from './StatCard';
import { RoomsByFloor } from './RoomsByFloor';
import { RoomLegend } from './RoomTile';
import { CobroRapidoCard } from './CobroRapidoCard';
import { Card, CardContent, CardHeader, CardTitle } from '../ui/Card';
import type { Habitacion, DashboardStats } from '../../types';

export function AdminDashboard() {
  const stats = useApi<DashboardStats>(() => api.get('/habitaciones/dashboard'));
  const habs = useApi<Habitacion[]>(() => api.get('/habitaciones'));

  return (
    <div className="space-y-6">
      {/* Cards de stats */}
      <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-4">
        <StatCard
          label="Disponibles"
          value={stats.data?.hab_disponibles ?? 0}
          icon={CheckCircle2}
          tone="success"
          loading={stats.loading}
        />
        <StatCard
          label="Ocupadas"
          value={stats.data?.hab_ocupadas ?? 0}
          icon={BedDouble}
          tone="info"
          loading={stats.loading}
        />
        <StatCard
          label="Reservadas"
          value={stats.data?.hab_reservadas ?? 0}
          icon={Bookmark}
          tone="accent"
          loading={stats.loading}
        />
        <StatCard
          label="Por limpiar"
          value={stats.data?.hab_por_limpiar ?? 0}
          icon={Sparkles}
          tone="warning"
          loading={stats.loading}
        />
        <StatCard
          label="En limpieza"
          value={stats.data?.hab_en_limpieza ?? 0}
          icon={Wrench}
          tone="info"
          loading={stats.loading}
        />
        <StatCard
          label="Por validar"
          value={stats.data?.hab_pendiente_validacion ?? 0}
          icon={AlertTriangle}
          tone="warning"
          loading={stats.loading}
          hint="Limpieza terminada, esperando validación"
        />
        <StatCard
          label="Reservas activas"
          value={stats.data?.reservas_activas ?? 0}
          icon={Calendar}
          tone="accent"
          loading={stats.loading}
        />
        <StatCard
          label="Clientes frecuentes"
          value={stats.data?.clientes_frecuentes ?? 0}
          icon={Users}
          tone="default"
          loading={stats.loading}
        />
      </div>

      {/* ⭐ NUEVO: Card de Cobro Rápido */}
      <CobroRapidoCard />

      {/* Mapa de habitaciones */}
      <Card>
        <CardHeader>
          <div className="flex items-start justify-between gap-4 flex-wrap">
            <div>
              <CardTitle>Mapa de habitaciones</CardTitle>
              <p className="text-sm text-text-secondary mt-1">
                Vista general de las {habs.data?.length ?? 25} habitaciones del hotel
              </p>
            </div>
            <RoomLegend />
          </div>
        </CardHeader>
        <CardContent>
          {habs.loading && (
            <div className="grid grid-cols-2 sm:grid-cols-4 md:grid-cols-6 gap-3">
              {Array.from({ length: 25 }).map((_, i) => (
                <div
                  key={i}
                  className="h-22 rounded-lg bg-bg-elevated animate-pulse"
                />
              ))}
            </div>
          )}
          {habs.error && (
            <div className="p-4 rounded-md bg-danger/10 border border-danger/30 text-danger text-sm">
              Error cargando habitaciones: {habs.error}
            </div>
          )}
          {habs.data && habs.data.length > 0 && (
            <RoomsByFloor habitaciones={habs.data} />
          )}
        </CardContent>
      </Card>
    </div>
  );
}
