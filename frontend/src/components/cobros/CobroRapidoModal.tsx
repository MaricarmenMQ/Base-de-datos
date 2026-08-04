import { useEffect, useState, type FormEvent } from 'react';
import { toast } from 'sonner';
import { Search, Receipt, CheckCircle } from 'lucide-react';
import { Modal } from '../dialogs/Modal';
import { Input } from '../ui/Input';
import { Label } from '../ui/Label';
import { Button } from '../ui/Button';
import { useDebounce } from '../../hooks/useDebounce';
import { api, ApiError } from '../../services/api';
import {
  MetodoPagoFields,
  validarMetodoPago,
  type MetodoPagoExt,
} from './MetodoPagoFields';
import type { Cliente, Habitacion } from '../../types';

interface CobroRapidoModalProps {
  open: boolean;
  habitaciones?: Habitacion[];
  /** Pre-cargar cliente */
  clienteInicial?: Cliente | null;
  /** Pre-cargar habitación */
  habitacionInicial?: Habitacion | null;
  onClose: () => void;
  onSaved: () => void;
}

type TipoCobro =
  | 'venta_directa'
  | 'servicio_extra'
  | 'anticipo_reserva'
  | 'saldo_reserva'
  | 'lavanderia'
  | 'consumo_minibar'
  | 'otro';

const TIPO_LABEL: Record<TipoCobro, string> = {
  venta_directa: 'Venta directa',
  servicio_extra: 'Servicio extra',
  anticipo_reserva: 'Anticipo de reserva',
  saldo_reserva: 'Saldo de reserva',
  lavanderia: 'Lavandería',
  consumo_minibar: 'Consumo minibar',
  otro: 'Otro',
};

const SUGERENCIAS_CONCEPTO = [
  'Botella de agua',
  'Cepillo de dientes',
  'Servicio de lavandería',
  'Toalla extra',
  'Calefacción adicional',
  'Pago saldo de reserva',
  'Anticipo de reserva',
];

export function CobroRapidoModal({
  open,
  habitaciones,
  clienteInicial,
  habitacionInicial,
  onClose,
  onSaved,
}: CobroRapidoModalProps) {
  // Cliente
  const [cliente, setCliente] = useState<Cliente | null>(null);
  const [nombreLibre, setNombreLibre] = useState('');
  const [busquedaCliente, setBusquedaCliente] = useState('');
  const debouncedCliente = useDebounce(busquedaCliente, 300);
  const [resultadosCliente, setResultadosCliente] = useState<Cliente[]>([]);

  // Datos del cobro
  const [habitacion, setHabitacion] = useState<Habitacion | null>(null);
  const [concepto, setConcepto] = useState('');
  const [tipoCobro, setTipoCobro] = useState<TipoCobro>('venta_directa');
  const [monto, setMonto] = useState<number>(0);
  const [metodoPago, setMetodoPago] = useState<MetodoPagoExt>('efectivo');
  const [numeroOperacion, setNumeroOperacion] = useState('');
  const [telefonoPago, setTelefonoPago] = useState('');
  const [notas, setNotas] = useState('');
  const [busy, setBusy] = useState(false);

  useEffect(() => {
    if (open) {
      setCliente(clienteInicial ?? null);
      setNombreLibre('');
      setBusquedaCliente('');
      setHabitacion(habitacionInicial ?? null);
      setConcepto('');
      setTipoCobro('venta_directa');
      setMonto(0);
      setMetodoPago('efectivo');
      setNumeroOperacion('');
      setTelefonoPago('');
      setNotas('');
    }
  }, [open, clienteInicial, habitacionInicial]);

  // Buscar clientes
  useEffect(() => {
    if (!debouncedCliente.trim()) {
      setResultadosCliente([]);
      return;
    }
    api
      .get<Cliente[]>(`/clientes/buscar?q=${encodeURIComponent(debouncedCliente)}`)
      .then((data) => setResultadosCliente(data.slice(0, 5)))
      .catch(() => setResultadosCliente([]));
  }, [debouncedCliente]);

  async function handleSubmit(e: FormEvent) {
    e.preventDefault();

    if (!concepto.trim()) {
      toast.error('Indica el concepto del cobro');
      return;
    }
    if (monto <= 0) {
      toast.error('El monto debe ser mayor a 0');
      return;
    }

    const errorMP = validarMetodoPago(metodoPago, numeroOperacion);
    if (errorMP) {
      toast.error(errorMP);
      return;
    }

    setBusy(true);
    try {
      const payload: Record<string, unknown> = {
        concepto: concepto.trim(),
        tipo_cobro: tipoCobro,
        monto,
        metodo_pago: metodoPago,
        numero_operacion: numeroOperacion.trim() || null,
        telefono_pago: telefonoPago.trim() || null,
        cliente_id: cliente?.id ?? null,
        nombre_cliente: !cliente && nombreLibre.trim() ? nombreLibre.trim() : null,
        habitacion_id: habitacion?.id ?? null,
        notas: notas.trim() || null,
      };

      const resp = await api.post<{ codigo: string; monto: number }>(
        '/cobros',
        payload
      );

      toast.success(
        `✓ Cobro ${resp.codigo} registrado · S/ ${Number(resp.monto).toFixed(2)}`
      );
      onSaved();
    } catch (err) {
      toast.error(err instanceof ApiError ? err.message : 'Error');
    } finally {
      setBusy(false);
    }
  }

  return (
    <Modal
      open={open}
      onClose={onClose}
      title="Cobro rápido"
      description="Registra un cobro a un cliente (no requiere reserva)"
      size="lg"
    >
      <form onSubmit={handleSubmit} className="space-y-4">
        {/* Cliente */}
        <div>
          <Label>Cliente</Label>
          {cliente ? (
            <div className="mt-1 p-3 bg-bg-elevated rounded-md border border-border-color flex items-center justify-between">
              <div className="flex items-center gap-2">
                <CheckCircle className="size-4 text-success" />
                <span className="text-text-primary text-sm">
                  {cliente.nombres} {cliente.apellidos}
                </span>
                <span className="text-text-muted text-xs">
                  · {cliente.tipo_documento}: {cliente.numero_documento}
                </span>
              </div>
              <Button
                type="button"
                variant="ghost"
                size="sm"
                onClick={() => setCliente(null)}
              >
                Cambiar
              </Button>
            </div>
          ) : (
            <>
              <div className="relative mt-1">
                <Search className="size-4 text-text-muted absolute left-3 top-1/2 -translate-y-1/2" />
                <Input
                  value={busquedaCliente}
                  onChange={(e) => setBusquedaCliente(e.target.value)}
                  placeholder="Buscar por nombre o documento..."
                  className="pl-9"
                />
              </div>
              {resultadosCliente.length > 0 && (
                <div className="mt-1 bg-bg-surface border border-border-color rounded-md max-h-40 overflow-y-auto">
                  {resultadosCliente.map((c) => (
                    <button
                      key={c.id}
                      type="button"
                      onClick={() => {
                        setCliente(c);
                        setBusquedaCliente('');
                        setResultadosCliente([]);
                      }}
                      className="w-full text-left px-3 py-2 hover:bg-bg-elevated text-sm border-b border-border-color/40 last:border-0"
                    >
                      <span className="text-text-primary">
                        {c.nombres} {c.apellidos}
                      </span>
                      <span className="text-text-muted text-xs ml-2">
                        {c.tipo_documento} {c.numero_documento}
                      </span>
                    </button>
                  ))}
                </div>
              )}
              <Input
                value={nombreLibre}
                onChange={(e) => setNombreLibre(e.target.value)}
                placeholder="O escribe nombre libre (cliente sin registrar)..."
                className="mt-2"
              />
            </>
          )}
        </div>

        {/* Habitación (opcional) */}
        {habitaciones && habitaciones.length > 0 && (
          <div>
            <Label htmlFor="hab">Habitación (opcional)</Label>
            <select
              id="hab"
              value={habitacion?.id ?? ''}
              onChange={(e) => {
                const id = e.target.value === '' ? null : Number(e.target.value);
                setHabitacion(habitaciones.find((h) => h.id === id) ?? null);
              }}
              className="w-full h-10 px-3 rounded-md bg-bg-elevated border border-border-color text-text-primary mt-1"
            >
              <option value="">— Sin habitación —</option>
              {habitaciones
                .filter((h) => h.estado_ocupacion === 'ocupada')
                .map((h) => (
                  <option key={h.id} value={h.id}>
                    Hab. {h.numero} (Piso {h.piso})
                  </option>
                ))}
            </select>
          </div>
        )}

        {/* Concepto y tipo */}
        <div className="grid grid-cols-2 gap-3">
          <div className="col-span-2">
            <Label htmlFor="concepto">Concepto *</Label>
            <Input
              id="concepto"
              value={concepto}
              onChange={(e) => setConcepto(e.target.value)}
              placeholder="¿Por qué se cobra?"
              required
              className="mt-1"
            />
            <div className="flex flex-wrap gap-1.5 mt-2">
              {SUGERENCIAS_CONCEPTO.map((s) => (
                <button
                  key={s}
                  type="button"
                  onClick={() => setConcepto(s)}
                  className="px-2 py-0.5 text-xs rounded-full bg-bg-elevated border border-border-color text-text-secondary hover:border-accent/50 hover:text-text-primary transition"
                >
                  {s}
                </button>
              ))}
            </div>
          </div>
          <div>
            <Label htmlFor="tipo">Tipo</Label>
            <select
              id="tipo"
              value={tipoCobro}
              onChange={(e) => setTipoCobro(e.target.value as TipoCobro)}
              className="w-full h-10 px-3 rounded-md bg-bg-elevated border border-border-color text-text-primary mt-1"
            >
              {(Object.keys(TIPO_LABEL) as TipoCobro[]).map((t) => (
                <option key={t} value={t}>
                  {TIPO_LABEL[t]}
                </option>
              ))}
            </select>
          </div>
          <div>
            <Label htmlFor="monto">Monto (S/) *</Label>
            <Input
              id="monto"
              type="number"
              min={0}
              step="0.01"
              value={monto}
              onChange={(e) => setMonto(Number(e.target.value))}
              required
              className="mt-1"
            />
          </div>
        </div>

        {/* Método de pago */}
        <MetodoPagoFields
          metodo={metodoPago}
          onMetodoChange={setMetodoPago}
          numeroOperacion={numeroOperacion}
          onNumeroOperacionChange={setNumeroOperacion}
          telefonoPago={telefonoPago}
          onTelefonoPagoChange={setTelefonoPago}
          idPrefix="cobro"
        />

        {/* Notas */}
        <div>
          <Label htmlFor="notas">Notas (opcional)</Label>
          <textarea
            id="notas"
            value={notas}
            onChange={(e) => setNotas(e.target.value)}
            rows={2}
            className="w-full mt-1 px-3 py-2 rounded-md bg-bg-elevated border border-border-color text-text-primary placeholder:text-text-muted focus:outline-none focus:border-accent focus:ring-1 focus:ring-accent resize-none"
          />
        </div>

        {/* Total destacado */}
        {monto > 0 && (
          <div className="bg-accent/5 border border-accent/30 rounded-md p-3 flex justify-between items-center">
            <span className="text-sm text-text-secondary">Total a cobrar</span>
            <span className="text-2xl font-semibold text-accent tabular-nums">
              S/ {monto.toFixed(2)}
            </span>
          </div>
        )}

        {/* Botones */}
        <div className="flex justify-end gap-2 pt-2 border-t border-border-color">
          <Button type="button" variant="outline" onClick={onClose} disabled={busy}>
            Cancelar
          </Button>
          <Button type="submit" isLoading={busy}>
            <Receipt className="size-4" />
            Registrar cobro
          </Button>
        </div>
      </form>
    </Modal>
  );
}
