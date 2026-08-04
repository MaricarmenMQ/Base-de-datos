import { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { toast } from 'sonner';
import {
  User,
  Calendar,
  DollarSign,
  Receipt,
  LogOut,
  Loader2,
  Phone,
  Globe,
  FileText,
  AlertCircle,
  XCircle,
} from 'lucide-react';
import { Modal } from '../dialogs/Modal';
import { Button } from '../ui/Button';
import { Label } from '../ui/Label';
import { api, ApiError } from '../../services/api';
import { TIPO_HABITACION_LABEL, ESTADO_PAGO_LABEL } from '../../types';
import type { Habitacion, EstadoPago } from '../../types';
import {
  MetodoPagoFields,
  validarMetodoPago,
  type MetodoPagoExt,
} from '../cobros/MetodoPagoFields';

interface OcupanteInfo {
  reserva_id: number;
  codigo: string;
  fecha_check_in: string;
  fecha_check_out: string | null;
  precio_total: string;
  monto_pagado: string;
  estado_pago: EstadoPago;
  tipo_estancia: string;
  metodo_pago: string | null;
  cliente_id: number;
  nombres: string;
  apellidos: string;
  tipo_documento: string;
  numero_documento: string;
  telefono: string | null;
  nacionalidad: string;
  recepcionista_nombre: string | null;
}

interface HabOcupadaModalProps {
  open: boolean;
  habitacion: Habitacion | null;
  onClose: () => void;
  onCheckedOut?: () => void;
  onCobroRapido?: (h: Habitacion, ocupante: OcupanteInfo) => void;
}

export function HabOcupadaModal({
  open,
  habitacion,
  onClose,
  onCheckedOut,
  onCobroRapido,
}: HabOcupadaModalProps) {
  const navigate = useNavigate();
  const [ocupante, setOcupante] = useState<OcupanteInfo | null>(null);
  const [loading, setLoading] = useState(false);
  const [busyCheckout, setBusyCheckout] = useState(false);

  // Estado para cobro de saldo pendiente
  const [mostrarCobro, setMostrarCobro] = useState(false);
  const [metodoPago, setMetodoPago] = useState<MetodoPagoExt>('efectivo');
  const [numeroOperacion, setNumeroOperacion] = useState('');
  const [telefonoPago, setTelefonoPago] = useState('');
  const [pagoConfirmado, setPagoConfirmado] = useState(false);
  const [busyCobro, setBusyCobro] = useState(false);

  // Estado para cancelar reserva
  const [mostrarCancelar, setMostrarCancelar] = useState(false);
  const [motivoCancelacion, setMotivoCancelacion] = useState('');
  const [busyCancelar, setBusyCancelar] = useState(false);

  useEffect(() => {
    if (!open || !habitacion) {
      setOcupante(null);
      setMostrarCobro(false);
      setMostrarCancelar(false);
      return;
    }
    setLoading(true);
    api
      .get<OcupanteInfo | null>(`/habitaciones/${habitacion.id}/ocupante`)
      .then((data) => setOcupante(data))
      .catch((err) => toast.error(err instanceof ApiError ? err.message : 'Error'))
      .finally(() => setLoading(false));
  }, [open, habitacion]);

  function resetCobro() {
    setMostrarCobro(false);
    setMetodoPago('efectivo');
    setNumeroOperacion('');
    setTelefonoPago('');
    setPagoConfirmado(false);
  }

  function resetCancelar() {
    setMostrarCancelar(false);
    setMotivoCancelacion('');
  }

  if (!habitacion) return null;

  const saldoPendiente = ocupante
    ? Number(ocupante.precio_total) - Number(ocupante.monto_pagado)
    : 0;

  const handleCheckout = async () => {
    if (!ocupante) return;
    if (
      !confirm(
        `¿Hacer check-out de ${ocupante.nombres} ${ocupante.apellidos}?\n\n` +
        `Reserva: ${ocupante.codigo}\n` +
        `Monto pagado: S/ ${Number(ocupante.monto_pagado).toFixed(2)}\n` +
        `Total: S/ ${Number(ocupante.precio_total).toFixed(2)}\n\n` +
        `La habitación quedará marcada como "pendiente de limpieza".`
      )
    ) return;

    setBusyCheckout(true);
    try {
      await api.post(`/reservas/${ocupante.reserva_id}/check-out`);
      toast.success(`Check-out completado · Hab. ${habitacion.numero}`);
      onCheckedOut?.();
      onClose();
    } catch (err) {
      toast.error(err instanceof ApiError ? err.message : 'Error');
    } finally {
      setBusyCheckout(false);
    }
  };

  const handleVerReserva = () => {
    if (!ocupante) return;
    onClose();
    navigate(`/reservas?id=${ocupante.reserva_id}`);
  };

  const handleCobrarSaldo = async () => {
    if (!ocupante || saldoPendiente <= 0) return;

    const errorMP = validarMetodoPago(metodoPago, numeroOperacion, {
      confirmado: pagoConfirmado,
      montoTotal: saldoPendiente,
    });
    if (errorMP) { toast.error(errorMP); return; }

    setBusyCobro(true);
    try {
      await api.post(`/reservas/${ocupante.reserva_id}/cobrar-saldo`, {
        monto: saldoPendiente,
        metodo_pago: metodoPago,
        numero_operacion: numeroOperacion.trim() || null,
        telefono_pago: telefonoPago.trim() || null,
      });
      toast.success(`✓ S/ ${saldoPendiente.toFixed(2)} cobrado · Reserva ${ocupante.codigo}`);
      const data = await api.get<OcupanteInfo | null>(`/habitaciones/${habitacion.id}/ocupante`);
      setOcupante(data);
      resetCobro();
    } catch (err) {
      toast.error(err instanceof ApiError ? err.message : 'Error al registrar cobro');
    } finally {
      setBusyCobro(false);
    }
  };

  const handleCancelarReserva = async () => {
    if (!ocupante) return;
    if (motivoCancelacion.trim().length < 3) {
      toast.error('El motivo debe tener al menos 3 caracteres');
      return;
    }
    setBusyCancelar(true);
    try {
      await api.post(`/reservas/${ocupante.reserva_id}/cancelar`, {
        motivo: motivoCancelacion.trim(),
      });
      toast.success(`Reserva ${ocupante.codigo} cancelada`);
      onCheckedOut?.();
      onClose();
    } catch (err) {
      toast.error(err instanceof ApiError ? err.message : 'Error al cancelar');
    } finally {
      setBusyCancelar(false);
    }
  };

  return (
    <Modal
      open={open}
      onClose={onClose}
      title={`Habitación ${habitacion.numero} ocupada`}
      description={`Piso ${habitacion.piso} · ${TIPO_HABITACION_LABEL[habitacion.tipo]}`}
      size="md"
    >
      <div className="space-y-4">
        {loading && (
          <div className="flex justify-center py-12">
            <Loader2 className="size-6 text-accent animate-spin" />
          </div>
        )}

        {!loading && !ocupante && (
          <div className="bg-warning/10 border border-warning/40 rounded-md p-4 text-warning text-sm">
            La habitación está marcada como ocupada pero no se encontró una
            reserva activa. Revisa el módulo de Reservas.
          </div>
        )}

        {!loading && ocupante && (
          <>
            {/* Cliente */}
            <div className="bg-bg-elevated rounded-md p-4 space-y-3">
              <div className="flex items-center gap-2">
                <User className="size-5 text-accent" />
                <p className="font-semibold text-text-primary">
                  {ocupante.nombres} {ocupante.apellidos}
                </p>
              </div>
              <div className="grid grid-cols-2 gap-3 text-sm">
                <div className="flex items-center gap-2">
                  <FileText className="size-3.5 text-text-muted" />
                  <span className="text-text-secondary">
                    {ocupante.tipo_documento}: {ocupante.numero_documento}
                  </span>
                </div>
                {ocupante.telefono && (
                  <div className="flex items-center gap-2">
                    <Phone className="size-3.5 text-text-muted" />
                    <span className="text-text-secondary">{ocupante.telefono}</span>
                  </div>
                )}
                <div className="flex items-center gap-2">
                  <Globe className="size-3.5 text-text-muted" />
                  <span className="text-text-secondary">{ocupante.nacionalidad}</span>
                </div>
              </div>
            </div>

            {/* Reserva */}
            <div className="bg-bg-elevated rounded-md p-4 space-y-2">
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-2">
                  <Calendar className="size-4 text-accent" />
                  <p className="text-sm font-medium text-text-primary">
                    Reserva {ocupante.codigo}
                  </p>
                </div>
                <span className="text-xs text-text-secondary">
                  {ocupante.tipo_estancia.replace(/_/g, ' ')}
                </span>
              </div>
              <div className="grid grid-cols-2 gap-2 text-xs text-text-secondary">
                <div>
                  <p className="text-text-muted">Check-in</p>
                  <p className="text-text-primary tabular-nums">{formatDate(ocupante.fecha_check_in)}</p>
                </div>
                {ocupante.fecha_check_out && (
                  <div>
                    <p className="text-text-muted">Check-out previsto</p>
                    <p className="text-text-primary tabular-nums">{formatDate(ocupante.fecha_check_out)}</p>
                  </div>
                )}
              </div>
              {ocupante.recepcionista_nombre && (
                <p className="text-xs text-text-muted pt-2 border-t border-border-color">
                  Registrada por: {ocupante.recepcionista_nombre}
                </p>
              )}
            </div>

            {/* Estado de pago */}
            <div className="bg-accent/5 border border-accent/30 rounded-md p-4 space-y-2">
              <div className="flex items-center gap-2 mb-2">
                <DollarSign className="size-4 text-accent" />
                <p className="text-sm font-semibold text-text-primary">Estado de pago</p>
              </div>
              <div className="space-y-1 text-sm">
                <div className="flex justify-between">
                  <span className="text-text-secondary">Total</span>
                  <span className="text-text-primary font-medium tabular-nums">
                    S/ {Number(ocupante.precio_total).toFixed(2)}
                  </span>
                </div>
                <div className="flex justify-between">
                  <span className="text-text-secondary">Pagado</span>
                  <span className="text-success font-medium tabular-nums">
                    S/ {Number(ocupante.monto_pagado).toFixed(2)}
                  </span>
                </div>
                {saldoPendiente > 0 && (
                  <div className="flex justify-between pt-1 border-t border-accent/30">
                    <span className="text-text-secondary">Saldo pendiente</span>
                    <span className="text-warning font-semibold tabular-nums">
                      S/ {saldoPendiente.toFixed(2)}
                    </span>
                  </div>
                )}
              </div>
              <p className="text-xs text-text-secondary pt-1">
                Estado: {ESTADO_PAGO_LABEL[ocupante.estado_pago]}
                {ocupante.metodo_pago && ` · vía ${ocupante.metodo_pago}`}
              </p>
            </div>

            {/* Panel cobrar saldo pendiente */}
            {saldoPendiente > 0 && (
              <div className="border border-warning/40 rounded-md overflow-hidden">
                <button
                  type="button"
                  onClick={() => { setMostrarCobro(!mostrarCobro); setMostrarCancelar(false); }}
                  className="w-full flex items-center justify-between px-4 py-3 bg-warning/10 hover:bg-warning/15 transition text-left"
                >
                  <div className="flex items-center gap-2">
                    <AlertCircle className="size-4 text-warning" />
                    <span className="text-sm font-semibold text-warning">Cobrar saldo pendiente</span>
                  </div>
                  <span className="text-sm font-bold text-warning tabular-nums">
                    S/ {saldoPendiente.toFixed(2)}
                  </span>
                </button>

                {mostrarCobro && (
                  <div className="p-4 space-y-4 bg-bg-elevated border-t border-warning/30">
                    <p className="text-xs text-text-secondary">
                      Registra el cobro de S/ {saldoPendiente.toFixed(2)} pendiente de la reserva {ocupante.codigo}.
                    </p>
                    <MetodoPagoFields
                      metodo={metodoPago}
                      onMetodoChange={setMetodoPago}
                      numeroOperacion={numeroOperacion}
                      onNumeroOperacionChange={setNumeroOperacion}
                      telefonoPago={telefonoPago}
                      onTelefonoPagoChange={setTelefonoPago}
                      montoTotal={saldoPendiente}
                      onConfirmadoChange={setPagoConfirmado}
                      incluirOnline={false}
                      idPrefix="saldo"
                    />
                    <div className="flex gap-2 pt-2">
                      <Button variant="outline" size="sm" onClick={resetCobro} disabled={busyCobro} className="flex-1">
                        Cancelar
                      </Button>
                      <Button size="sm" onClick={handleCobrarSaldo} isLoading={busyCobro} className="flex-1">
                        <Receipt className="size-4" />
                        Confirmar cobro S/ {saldoPendiente.toFixed(2)}
                      </Button>
                    </div>
                  </div>
                )}
              </div>
            )}

            {/* Panel cancelar reserva */}
            <div className="border border-danger/40 rounded-md overflow-hidden">
              <button
                type="button"
                onClick={() => { setMostrarCancelar(!mostrarCancelar); setMostrarCobro(false); }}
                className="w-full flex items-center justify-between px-4 py-3 bg-danger/10 hover:bg-danger/15 transition text-left"
              >
                <div className="flex items-center gap-2">
                  <XCircle className="size-4 text-danger" />
                  <span className="text-sm font-semibold text-danger">Cancelar reserva</span>
                </div>
                <span className="text-xs text-danger">No se puede deshacer</span>
              </button>

              {mostrarCancelar && (
                <div className="p-4 space-y-3 bg-bg-elevated border-t border-danger/30">
                  <p className="text-xs text-text-secondary">
                    La reserva {ocupante.codigo} será cancelada y la habitación quedará disponible.
                  </p>
                  <div>
                    <Label htmlFor="motivo-cancelar">Motivo de cancelación *</Label>
                    <textarea
                      id="motivo-cancelar"
                      value={motivoCancelacion}
                      onChange={(e) => setMotivoCancelacion(e.target.value)}
                      placeholder="Ej: Cliente no se presentó, solicitó cancelación, etc."
                      rows={3}
                      className="w-full mt-1 px-3 py-2 rounded-md bg-bg-elevated border border-border-color text-text-primary placeholder:text-text-muted focus:outline-none focus:border-danger focus:ring-1 focus:ring-danger resize-none text-sm"
                    />
                  </div>
                  <div className="flex gap-2">
                    <Button variant="outline" size="sm" onClick={resetCancelar} disabled={busyCancelar} className="flex-1">
                      Cancelar
                    </Button>
                    <Button variant="danger" size="sm" onClick={handleCancelarReserva} isLoading={busyCancelar} className="flex-1">
                      <XCircle className="size-4" />
                      Confirmar cancelación
                    </Button>
                  </div>
                </div>
              )}
            </div>

            {/* Acciones */}
            <div className="flex flex-col gap-2 pt-2 border-t border-border-color">
              {onCobroRapido && (
                <Button variant="outline" onClick={() => onCobroRapido(habitacion, ocupante)} className="w-full">
                  <Receipt className="size-4" />
                  Registrar cobro extra
                </Button>
              )}
              <Button variant="outline" onClick={handleVerReserva} className="w-full">
                <FileText className="size-4" />
                Ver detalles en módulo Reservas
              </Button>
              <Button onClick={handleCheckout} isLoading={busyCheckout} className="w-full">
                <LogOut className="size-4" />
                Hacer check-out
              </Button>
              <Button variant="ghost" onClick={onClose}>Cerrar</Button>
            </div>
          </>
        )}
      </div>
    </Modal>
  );
}

function formatDate(s: string): string {
  return new Date(s).toLocaleDateString('es-PE', {
    day: '2-digit', month: 'short', year: 'numeric',
    hour: '2-digit', minute: '2-digit',
  });
}
