import { useEffect, useState } from 'react';
import { toast } from 'sonner';
import {
  DollarSign,
  Wallet,
  CreditCard,
  Smartphone,
  TrendingUp,
  Download,
  Loader2,
  Receipt,
  ShoppingCart,
  Calendar,
  Filter,
} from 'lucide-react';
import { api, ApiError } from '../services/api';
import { Header } from '../components/layout/Header';
import { Card, CardContent } from '../components/ui/Card';
import { Button } from '../components/ui/Button';
import { Input } from '../components/ui/Input';
import { Label } from '../components/ui/Label';
import { cn } from '../lib/cn';

type Periodo = 'hoy' | 'ayer' | 'semana' | 'mes' | 'custom';

interface Movimiento {
  id: string;
  tipo: 'cobro' | 'venta' | 'reserva';
  fecha: string;
  codigo: string | null;
  descripcion: string;
  monto: number;
  metodo_pago: string | null;
  numero_operacion: string | null;
  cliente: string | null;
  habitacion: string | null;
  recepcionista: string | null;
}

interface Resumen {
  total_general: number;
  total_movimientos: number;
  por_metodo: Array<{ metodo: string; num: number; total: number }>;
  por_tipo: {
    cobros: number;
    ventas: number;
    reservas: number;
  };
}

const METODO_ICON: Record<string, typeof Wallet> = {
  efectivo: Wallet,
  tarjeta: CreditCard,
  yape: Smartphone,
  plin: Smartphone,
  transferencia: TrendingUp,
  online: TrendingUp,
};

const METODO_COLOR: Record<string, string> = {
  efectivo: 'bg-success/10 text-success border-success/30',
  tarjeta: 'bg-info/10 text-info border-info/30',
  yape: 'bg-purple-500/10 text-purple-400 border-purple-500/30',
  plin: 'bg-cyan-500/10 text-cyan-400 border-cyan-500/30',
  transferencia: 'bg-accent/10 text-accent border-accent/30',
  online: 'bg-accent/10 text-accent border-accent/30',
};

const TIPO_LABEL: Record<string, string> = {
  cobro: 'Cobro directo',
  venta: 'Venta producto',
  reserva: 'Pago reserva',
};

const TIPO_COLOR: Record<string, string> = {
  cobro: 'bg-accent/15 text-accent',
  venta: 'bg-info/15 text-info',
  reserva: 'bg-success/15 text-success',
};

export default function CajaPage() {
  const [periodo, setPeriodo] = useState<Periodo>('hoy');
  const [desde, setDesde] = useState('');
  const [hasta, setHasta] = useState('');
  const [filtroTipo, setFiltroTipo] = useState<string>('todos');
  const [filtroMetodo, setFiltroMetodo] = useState<string>('todos');

  const [movimientos, setMovimientos] = useState<Movimiento[]>([]);
  const [resumen, setResumen] = useState<Resumen | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // Calcular rango de fechas según período
  useEffect(() => {
    const today = new Date();
    const fmt = (d: Date) => d.toISOString().slice(0, 10);
    if (periodo === 'hoy') {
      setDesde(fmt(today));
      setHasta(fmt(today));
    } else if (periodo === 'ayer') {
      const ayer = new Date(today);
      ayer.setDate(today.getDate() - 1);
      setDesde(fmt(ayer));
      setHasta(fmt(ayer));
    } else if (periodo === 'semana') {
      const start = new Date(today);
      start.setDate(today.getDate() - 7);
      setDesde(fmt(start));
      setHasta(fmt(today));
    } else if (periodo === 'mes') {
      const start = new Date(today);
      start.setDate(today.getDate() - 30);
      setDesde(fmt(start));
      setHasta(fmt(today));
    }
  }, [periodo]);

  useEffect(() => {
    cargar();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [desde, hasta]);

  async function cargar() {
    setLoading(true);
    setError(null);
    try {
      const params = new URLSearchParams();
      if (desde) params.set('desde', desde);
      if (hasta) params.set('hasta', hasta);
      const q = params.toString() ? '?' + params.toString() : '';

      const [movs, res] = await Promise.all([
        api.get<Movimiento[]>('/caja/movimientos' + q),
        api.get<Resumen>('/caja/resumen' + q),
      ]);
      setMovimientos(movs);
      setResumen(res);
    } catch (e) {
      setError(e instanceof ApiError ? e.message : 'Error');
    } finally {
      setLoading(false);
    }
  }

  // Filtros aplicados
  const movsFiltrados = movimientos.filter((m) => {
    if (filtroTipo !== 'todos' && m.tipo !== filtroTipo) return false;
    if (filtroMetodo !== 'todos' && m.metodo_pago !== filtroMetodo) return false;
    return true;
  });

  // Exportar a CSV
  function exportarCSV() {
    if (movsFiltrados.length === 0) {
      toast.error('No hay movimientos para exportar');
      return;
    }
    const headers = [
      'Fecha',
      'Hora',
      'Tipo',
      'Código',
      'Descripción',
      'Cliente',
      'Habitación',
      'Método Pago',
      'N° Operación',
      'Recepcionista',
      'Monto (S/)',
    ];
    const rows = movsFiltrados.map((m) => [
      m.fecha.slice(0, 10),
      m.fecha.slice(11, 16),
      TIPO_LABEL[m.tipo] ?? m.tipo,
      m.codigo ?? '',
      m.descripcion,
      m.cliente ?? '',
      m.habitacion ?? '',
      m.metodo_pago ?? '',
      m.numero_operacion ?? '',
      m.recepcionista ?? '',
      m.monto.toFixed(2),
    ]);
    const csv = [headers, ...rows]
      .map((row) =>
        row.map((c) => `"${String(c).replace(/"/g, '""')}"`).join(',')
      )
      .join('\n');

    const bom = '\uFEFF'; // BOM para que Excel reconozca UTF-8
    const blob = new Blob([bom + csv], { type: 'text/csv;charset=utf-8' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `caja_${desde || 'todo'}_${hasta || 'todo'}.csv`;
    a.click();
    URL.revokeObjectURL(url);
    toast.success(`${movsFiltrados.length} movimientos exportados`);
  }

  return (
    <>
      <Header
        title="Caja Contable"
        description="Vista contable solo para administración"
        actions={
          <Button onClick={exportarCSV} disabled={movsFiltrados.length === 0}>
            <Download className="size-4" />
            Exportar CSV
          </Button>
        }
      />

      <div className="flex-1 p-8 space-y-4">
        {/* Selector de período */}
        <Card>
          <CardContent className="p-4 space-y-3">
            <Label>Período</Label>
            <div className="flex gap-2 flex-wrap">
              {(['hoy', 'ayer', 'semana', 'mes', 'custom'] as Periodo[]).map((p) => (
                <button
                  key={p}
                  type="button"
                  onClick={() => setPeriodo(p)}
                  className={cn(
                    'px-3 py-1.5 rounded-md text-sm font-medium border transition',
                    periodo === p
                      ? 'bg-accent/15 text-accent border-accent/50'
                      : 'bg-bg-elevated text-text-secondary border-border-color hover:text-text-primary'
                  )}
                >
                  {p === 'hoy' && 'Hoy'}
                  {p === 'ayer' && 'Ayer'}
                  {p === 'semana' && 'Última semana'}
                  {p === 'mes' && 'Último mes'}
                  {p === 'custom' && 'Personalizado'}
                </button>
              ))}
            </div>
            {periodo === 'custom' && (
              <div className="grid grid-cols-2 gap-3 pt-2">
                <div>
                  <Label htmlFor="desde">Desde</Label>
                  <Input
                    id="desde"
                    type="date"
                    value={desde}
                    onChange={(e) => setDesde(e.target.value)}
                    className="mt-1"
                  />
                </div>
                <div>
                  <Label htmlFor="hasta">Hasta</Label>
                  <Input
                    id="hasta"
                    type="date"
                    value={hasta}
                    onChange={(e) => setHasta(e.target.value)}
                    className="mt-1"
                  />
                </div>
              </div>
            )}
          </CardContent>
        </Card>

        {loading && (
          <div className="flex justify-center py-12">
            <Loader2 className="size-6 text-accent animate-spin" />
          </div>
        )}
        {error && (
          <div className="p-4 rounded-md bg-danger/10 border border-danger/30 text-danger text-sm">
            Error: {error}
          </div>
        )}

        {!loading && !error && resumen && (
          <>
            {/* Total general destacado */}
            <Card className="border-accent/30 bg-gradient-to-br from-accent/5 to-transparent">
              <CardContent className="p-6">
                <div className="flex items-center justify-between flex-wrap gap-4">
                  <div>
                    <p className="text-xs text-text-muted uppercase tracking-wide mb-1">
                      Total en caja
                    </p>
                    <p className="text-4xl font-bold text-accent tabular-nums">
                      S/ {resumen.total_general.toFixed(2)}
                    </p>
                    <p className="text-sm text-text-secondary mt-1">
                      {resumen.total_movimientos} movimiento
                      {resumen.total_movimientos !== 1 ? 's' : ''}
                    </p>
                  </div>
                  <div className="size-16 rounded-2xl bg-accent/15 border border-accent/40 flex items-center justify-center">
                    <DollarSign className="size-8 text-accent" />
                  </div>
                </div>
              </CardContent>
            </Card>

            {/* Desglose por método de pago */}
            <Card>
              <CardContent className="p-5">
                <h3 className="text-sm font-semibold text-text-primary mb-3 flex items-center gap-2">
                  <Wallet className="size-4 text-accent" />
                  Desglose por método de pago
                </h3>
                <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-5 gap-3">
                  {resumen.por_metodo.length === 0 ? (
                    <p className="text-text-muted text-sm col-span-full">
                      No hay movimientos en el período
                    </p>
                  ) : (
                    resumen.por_metodo.map((m) => {
                      const Icon = METODO_ICON[m.metodo] ?? Wallet;
                      const color =
                        METODO_COLOR[m.metodo] ??
                        'bg-bg-elevated text-text-secondary border-border-color';
                      return (
                        <div
                          key={m.metodo}
                          className={cn('rounded-md p-3 border', color)}
                        >
                          <div className="flex items-center justify-between mb-2">
                            <Icon className="size-4" />
                            <span className="text-xs uppercase tracking-wide">
                              {m.metodo}
                            </span>
                          </div>
                          <p className="text-xl font-semibold tabular-nums">
                            S/ {m.total.toFixed(2)}
                          </p>
                          <p className="text-[11px] opacity-70">
                            {m.num} mov.
                          </p>
                        </div>
                      );
                    })
                  )}
                </div>
              </CardContent>
            </Card>

            {/* Desglose por tipo */}
            <div className="grid sm:grid-cols-3 gap-3">
              <CardTipo
                tipo="cobros"
                label="Cobros directos"
                total={resumen.por_tipo.cobros}
                icon={Receipt}
              />
              <CardTipo
                tipo="ventas"
                label="Ventas productos"
                total={resumen.por_tipo.ventas}
                icon={ShoppingCart}
              />
              <CardTipo
                tipo="reservas"
                label="Pagos reservas"
                total={resumen.por_tipo.reservas}
                icon={Calendar}
              />
            </div>

            {/* Filtros + tabla */}
            <Card>
              <CardContent className="p-0">
                {/* Filtros */}
                <div className="p-4 border-b border-border-color flex items-center gap-3 flex-wrap">
                  <Filter className="size-4 text-text-muted" />
                  <select
                    value={filtroTipo}
                    onChange={(e) => setFiltroTipo(e.target.value)}
                    className="h-9 px-3 rounded-md bg-bg-elevated border border-border-color text-text-primary text-sm"
                  >
                    <option value="todos">Todos los tipos</option>
                    <option value="cobro">Solo cobros directos</option>
                    <option value="venta">Solo ventas productos</option>
                    <option value="reserva">Solo pagos reservas</option>
                  </select>
                  <select
                    value={filtroMetodo}
                    onChange={(e) => setFiltroMetodo(e.target.value)}
                    className="h-9 px-3 rounded-md bg-bg-elevated border border-border-color text-text-primary text-sm"
                  >
                    <option value="todos">Todos los métodos</option>
                    <option value="efectivo">Solo efectivo</option>
                    <option value="tarjeta">Solo tarjeta</option>
                    <option value="yape">Solo Yape</option>
                    <option value="plin">Solo Plin</option>
                    <option value="transferencia">Solo transferencia</option>
                  </select>
                  <span className="text-xs text-text-secondary ml-auto">
                    Mostrando {movsFiltrados.length} de {movimientos.length}
                  </span>
                </div>

                {/* Tabla */}
                <div className="overflow-x-auto">
                  <table className="w-full">
                    <thead>
                      <tr className="border-b border-border-color text-xs text-text-muted uppercase">
                        <th className="text-left py-2 px-3">Fecha/Hora</th>
                        <th className="text-left py-2 px-3">Tipo</th>
                        <th className="text-left py-2 px-3">Descripción</th>
                        <th className="text-left py-2 px-3">Cliente / Hab.</th>
                        <th className="text-left py-2 px-3">Método</th>
                        <th className="text-left py-2 px-3">Por</th>
                        <th className="text-right py-2 px-3">Monto</th>
                      </tr>
                    </thead>
                    <tbody>
                      {movsFiltrados.length === 0 ? (
                        <tr>
                          <td
                            colSpan={7}
                            className="py-12 text-center text-text-muted text-sm"
                          >
                            No hay movimientos en este período/filtros
                          </td>
                        </tr>
                      ) : (
                        movsFiltrados.map((m) => (
                          <tr
                            key={m.id}
                            className="border-b border-border-color/30 text-sm hover:bg-bg-elevated/40"
                          >
                            <td className="py-2 px-3 text-text-secondary text-xs">
                              <p className="tabular-nums">
                                {m.fecha.slice(0, 10)}
                              </p>
                              <p className="text-text-muted tabular-nums">
                                {m.fecha.slice(11, 16)}
                              </p>
                            </td>
                            <td className="py-2 px-3">
                              <span
                                className={cn(
                                  'inline-block px-2 py-0.5 rounded text-[10px] font-medium',
                                  TIPO_COLOR[m.tipo]
                                )}
                              >
                                {TIPO_LABEL[m.tipo]}
                              </span>
                            </td>
                            <td className="py-2 px-3">
                              <p className="text-text-primary">{m.descripcion}</p>
                              {m.codigo && (
                                <p className="text-[11px] text-text-muted font-mono">
                                  {m.codigo}
                                </p>
                              )}
                            </td>
                            <td className="py-2 px-3 text-text-secondary text-xs">
                              {m.cliente && <p>{m.cliente}</p>}
                              {m.habitacion && (
                                <p className="text-text-muted">
                                  Hab. {m.habitacion}
                                </p>
                              )}
                              {!m.cliente && !m.habitacion && '—'}
                            </td>
                            <td className="py-2 px-3 text-xs text-text-secondary">
                              <div className="flex items-center gap-1">
                                {(m.metodo_pago === 'yape' ||
                                  m.metodo_pago === 'plin') && (
                                  <Smartphone className="size-3 text-info" />
                                )}
                                {m.metodo_pago ?? '—'}
                              </div>
                              {m.numero_operacion && (
                                <p className="text-[10px] text-text-muted">
                                  #{m.numero_operacion.slice(-6)}
                                </p>
                              )}
                            </td>
                            <td className="py-2 px-3 text-text-secondary text-xs truncate max-w-[120px]">
                              {m.recepcionista ?? '—'}
                            </td>
                            <td className="py-2 px-3 text-right text-accent font-medium tabular-nums">
                              S/ {m.monto.toFixed(2)}
                            </td>
                          </tr>
                        ))
                      )}
                    </tbody>
                    {movsFiltrados.length > 0 && (
                      <tfoot>
                        <tr className="border-t-2 border-accent/30 bg-accent/5">
                          <td colSpan={6} className="py-3 px-3 text-right text-text-secondary font-medium">
                            TOTAL FILTRADO
                          </td>
                          <td className="py-3 px-3 text-right text-accent font-bold tabular-nums text-base">
                            S/{' '}
                            {movsFiltrados
                              .reduce((s, m) => s + m.monto, 0)
                              .toFixed(2)}
                          </td>
                        </tr>
                      </tfoot>
                    )}
                  </table>
                </div>
              </CardContent>
            </Card>
          </>
        )}
      </div>
    </>
  );
}

function CardTipo({
  label,
  total,
  icon: Icon,
}: {
  tipo: string;
  label: string;
  total: number;
  icon: typeof Receipt;
}) {
  return (
    <Card>
      <CardContent className="p-4 flex items-center gap-3">
        <div className="size-10 rounded-lg bg-bg-elevated flex items-center justify-center">
          <Icon className="size-5 text-accent" />
        </div>
        <div>
          <p className="text-xs text-text-muted uppercase tracking-wide">{label}</p>
          <p className="text-lg font-semibold text-text-primary tabular-nums">
            S/ {total.toFixed(2)}
          </p>
        </div>
      </CardContent>
    </Card>
  );
}
