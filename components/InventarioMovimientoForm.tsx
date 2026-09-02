import type { InventarioMovimiento, MotivoMovimiento } from "@/lib/types";

const TIPO_BADGE: Record<string, string> = { alta: "b-green", baja: "b-red" };
const TIPO_LABEL: Record<string, string> = { alta: "Alta", baja: "Baja" };

function fmtFecha(iso: string) {
  const d = new Date(iso);
  if (isNaN(d.getTime())) return "-";
  return d.toLocaleString("es-AR", { day: "2-digit", month: "2-digit", year: "numeric", hour: "2-digit", minute: "2-digit" });
}

export default function InventarioMovimientoForm({
  action,
  motivos,
  cantidadActual,
  historial,
}: {
  action: (formData: FormData) => void;
  motivos: MotivoMovimiento[];
  cantidadActual: number;
  historial: InventarioMovimiento[];
}) {
  const motivosAlta = motivos.filter((m) => m.tipo === "alta" || m.tipo === "ambos");
  const motivosBaja = motivos.filter((m) => m.tipo === "baja" || m.tipo === "ambos");

  return (
    <div>
      <div className="info-box accent mb16">
        Cantidad actual en stock: <strong className="text-mono">{cantidadActual}</strong>
      </div>

      <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 16 }}>
        <form action={action} className="card">
          <div className="card-title">Reportar alta</div>
          <input type="hidden" name="tipo" value="alta" />
          <div className="fg mb16">
            <label>Cantidad</label>
            <input type="number" name="cantidad" min="1" step="1" required />
          </div>
          <div className="fg mb16">
            <label>Motivo</label>
            <select name="motivo_id" required>
              <option value="">Elegir motivo...</option>
              {motivosAlta.map((m) => (
                <option key={m.id} value={m.id}>
                  {m.nombre}
                </option>
              ))}
            </select>
          </div>
          <div className="fg">
            <label>Detalle</label>
            <textarea name="detalle" rows={3} placeholder="Que ocurrio (opcional)" />
          </div>
          <div className="flex-between mt16" style={{ justifyContent: "flex-end" }}>
            <button type="submit" className="btn btn-success">
              Registrar alta
            </button>
          </div>
        </form>

        <form action={action} className="card">
          <div className="card-title">Reportar baja</div>
          <input type="hidden" name="tipo" value="baja" />
          <div className="fg mb16">
            <label>Cantidad</label>
            <input type="number" name="cantidad" min="1" step="1" required />
          </div>
          <div className="fg mb16">
            <label>Motivo</label>
            <select name="motivo_id" required>
              <option value="">Elegir motivo...</option>
              {motivosBaja.map((m) => (
                <option key={m.id} value={m.id}>
                  {m.nombre}
                </option>
              ))}
            </select>
          </div>
          <div className="fg">
            <label>Detalle</label>
            <textarea name="detalle" rows={3} placeholder="Que ocurrio (obligatorio si es perdida o rotura)" />
          </div>
          <div className="flex-between mt16" style={{ justifyContent: "flex-end" }}>
            <button type="submit" className="btn btn-danger">
              Registrar baja
            </button>
          </div>
        </form>
      </div>

      <div className="card mt16">
        <div className="card-title">Historial de movimientos</div>
        {historial.length === 0 ? (
          <div className="empty-state">Todavia no hay movimientos registrados para este item.</div>
        ) : (
          <div className="table-wrap">
            <table>
              <thead>
                <tr>
                  <th>Fecha</th>
                  <th>Tipo</th>
                  <th>Cantidad</th>
                  <th>Motivo</th>
                  <th>Detalle</th>
                  <th>Usuario</th>
                </tr>
              </thead>
              <tbody>
                {historial.map((m) => (
                  <tr key={m.id}>
                    <td className="text-mono">{fmtFecha(m.created_at)}</td>
                    <td>
                      <span className={`badge ${TIPO_BADGE[m.tipo]}`}>{TIPO_LABEL[m.tipo]}</span>
                    </td>
                    <td className="text-mono">{m.cantidad}</td>
                    <td>{m.motivos_movimiento?.nombre ?? "-"}</td>
                    <td className="text-muted">{m.detalle ?? "-"}</td>
                    <td className="text-muted">{m.usuario_email ?? "-"}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>
    </div>
  );
}
