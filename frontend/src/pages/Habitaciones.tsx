import { useState } from 'react';
import { toast } from 'sonner';
import {
  BedDouble,
  Plus,
  Pencil,
  PowerOff,
  Power,
  Loader2,
  Bath,
  Tv,
  Wifi,
  Flame,
  Wind,
  AlertTriangle,
} from 'lucide-react';
import { useApi } from '../hooks/useApi';
import { api, ApiError } from '../services/api';
import { useAuth } from '../context/AuthContext';
import { Header } from '../components/layout/Header';
import { Card, CardContent } from '../components/ui/Card';
import { Button } from '../components/ui/Button';
import { HabitacionFormModal } from '../components/habitaciones/HabitacionFormModal';
import { TIPO_HABITACION_LABEL } from '../types';
import { cn } from '../lib/cn';
import type { Habitacion } from '../types';

export default function HabitacionesPage() {
  const { user } = useAuth();
  const esAdmin = user?.rol === 'admin';

  const habs = useApi<Habitacion[]>(() => api.get('/habitaciones'));

  const [creando, setCreando] = useState(false);
  const [editando, setEditando] = useState<Habitacion | null>(null);
  const [mostrarInactivas, setMostrarInactivas] = useState(false);

  async function handleDesactivar(h: Habitacion) {
    if (
      !confirm(
        `¿Desactivar la habitación ${h.numero}?\n\n` +
          `Quedará marcada como "fuera de servicio" y no se podrá alquilar.\n` +
          `Puedes reactivarla después si la quieres usar de nuevo.`
      )
    )
      return;
    try {
      await api.patch(`/habitaciones/${h.id}/desactivar`);
      toast.success(`Habitación ${h.numero} desactivada`);
      habs.refetch();
    } catch (e) {
      toast.error(e instanceof ApiError ? e.message : 'Error');
    }
  }

  async function handleActivar(h: Habitacion) {
    try {
      await api.patch(`/habitaciones/${h.id}/activar`);
      toast.success(`Habitación ${h.numero} reactivada`);
      habs.refetch();
    } catch (e) {
      toast.error(e instanceof ApiError ? e.message : 'Error');
    }
  }

  const habsFiltradas = (habs.data ?? []).filter((h) =>
    mostrarInactivas ? true : !!h.activo
  );

  // Agrupar por piso
  const porPiso = habsFiltradas.reduce<Record<number, Habitacion[]>>((acc, h) => {
    if (!acc[h.piso]) acc[h.piso] = [];
    acc[h.piso].push(h);
    return acc;
  }, {});

  return (
    <>
      <Header
        title="Habitaciones"
        description={`${habsFiltradas.length} habitación${habsFiltradas.length !== 1 ? 'es' : ''} ${mostrarInactivas ? '(incluyendo inactivas)' : 'activas'}`}
        actions={
          esAdmin && (
            <Button onClick={() => setCreando(true)}>
              <Plus className="size-4" />
              Nueva habitación
            </Button>
          )
        }
      />

      <div className="flex-1 p-8 space-y-4">
        {esAdmin && (
          <div className="flex items-center gap-2">
            <input
              type="checkbox"
              id="mostrar-inactivas"
              checked={mostrarInactivas}
              onChange={(e) => setMostrarInactivas(e.target.checked)}
              className="size-4 rounded border-border-color bg-bg-elevated text-accent focus:ring-1 focus:ring-accent"
            />
            <label
              htmlFor="mostrar-inactivas"
              className="text-sm text-text-secondary cursor-pointer"
            >
              Mostrar habitaciones inactivas/fuera de servicio
            </label>
          </div>
        )}

        {habs.loading && (
          <div className="flex justify-center py-12">
            <Loader2 className="size-6 text-accent animate-spin" />
          </div>
        )}

        {habs.error && (
          <div className="p-4 rounded-md bg-danger/10 border border-danger/30 text-danger text-sm">
            Error: {habs.error}
          </div>
        )}

        {!habs.loading &&
          !habs.error &&
          Object.entries(porPiso)
            .sort(([a], [b]) => Number(a) - Number(b))
            .map(([piso, items]) => (
              <div key={piso}>
                <h2 className="text-sm font-semibold text-text-primary mb-3">
                  Piso {piso} · {items.length} habitación{items.length !== 1 ? 'es' : ''}
                </h2>
                <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4">
                  {items.map((h) => (
                    <HabCard
                      key={h.id}
                      hab={h}
                      esAdmin={esAdmin}
                      onEdit={() => setEditando(h)}
                      onDesactivar={() => handleDesactivar(h)}
                      onActivar={() => handleActivar(h)}
                    />
                  ))}
                </div>
              </div>
            ))}
      </div>

      <HabitacionFormModal
        open={creando || !!editando}
        habitacion={editando}
        onClose={() => {
          setCreando(false);
          setEditando(null);
        }}
        onSaved={() => {
          setCreando(false);
          setEditando(null);
          habs.refetch();
        }}
      />
    </>
  );
}

function HabCard({
  hab,
  esAdmin,
  onEdit,
  onDesactivar,
  onActivar,
}: {
  hab: Habitacion;
  esAdmin: boolean;
  onEdit: () => void;
  onDesactivar: () => void;
  onActivar: () => void;
}) {
  const activa = !!hab.activo;
  const fueraServicio = hab.estado_ocupacion === 'fuera_de_servicio';

  return (
    <Card
      className={cn(
        'transition',
        !activa && 'opacity-60 border-danger/30',
        fueraServicio && activa && 'border-warning/40'
      )}
    >
      <CardContent className="p-4 space-y-3">
        <div className="flex items-start justify-between gap-2">
          <div>
            <div className="flex items-center gap-2">
              <BedDouble className="size-5 text-accent" />
              <p className="text-lg font-semibold text-text-primary">
                Hab. {hab.numero}
              </p>
              {fueraServicio && (
                <span className="px-1.5 py-0.5 rounded text-[10px] bg-warning/15 text-warning border border-warning/30">
                  Fuera de servicio
                </span>
              )}
              {!activa && (
                <span className="px-1.5 py-0.5 rounded text-[10px] bg-danger/15 text-danger border border-danger/30">
                  Inactiva
                </span>
              )}
            </div>
            <p className="text-xs text-text-secondary mt-0.5">
              {TIPO_HABITACION_LABEL[hab.tipo]} · cap. {hab.capacidad}
            </p>
          </div>
          {esAdmin && (
            <div className="flex gap-1">
              <Button variant="ghost" size="sm" onClick={onEdit} title="Editar">
                <Pencil className="size-3.5" />
              </Button>
              {activa ? (
                <Button
                  variant="ghost"
                  size="sm"
                  onClick={onDesactivar}
                  className="text-danger hover:bg-danger/10"
                  title="Desactivar"
                >
                  <PowerOff className="size-3.5" />
                </Button>
              ) : (
                <Button
                  variant="ghost"
                  size="sm"
                  onClick={onActivar}
                  className="text-success hover:bg-success/10"
                  title="Reactivar"
                >
                  <Power className="size-3.5" />
                </Button>
              )}
            </div>
          )}
        </div>

        {/* Amenities */}
        <div className="flex flex-wrap gap-1.5">
          {hab.bano_privado && (
            <Amenity icon={Bath} label="Baño privado" />
          )}
          {hab.bano_con_jacuzzi && <Amenity icon={Bath} label="Jacuzzi" />}
          {hab.tiene_tv && <Amenity icon={Tv} label="TV" />}
          {hab.tiene_cable_tv && <Amenity icon={Tv} label="Cable" />}
          {hab.tiene_wifi && <Amenity icon={Wifi} label="WiFi" />}
          {hab.tiene_calefaccion && <Amenity icon={Flame} label="Calefacción" />}
          {hab.tiene_balcon && <Amenity icon={Wind} label="Balcón" />}
        </div>

        {/* Camas */}
        {hab.camas && hab.camas.length > 0 && (
          <div className="text-xs text-text-secondary">
            {hab.camas
              .map((c) => `${c.cantidad}× ${c.tipo_cama.replace(/_/g, ' ')}`)
              .join(', ')}
          </div>
        )}

        {/* Precio */}
        <div className="pt-2 border-t border-border-color flex justify-between items-center">
          <span className="text-xs text-text-muted">Precio base/noche</span>
          <span className="text-sm font-semibold text-accent tabular-nums">
            S/ {Number(hab.precio_base_noche).toFixed(2)}
          </span>
        </div>
      </CardContent>
    </Card>
  );
}

function Amenity({
  icon: Icon,
  label,
}: {
  icon: typeof Bath;
  label: string;
}) {
  return (
    <span className="inline-flex items-center gap-1 px-1.5 py-0.5 rounded text-[10px] bg-bg-elevated border border-border-color text-text-secondary">
      <Icon className="size-2.5" />
      {label}
    </span>
  );
}
