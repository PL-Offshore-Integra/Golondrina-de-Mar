import type { InventarioItem, Ubicacion } from "@/lib/types";

export default function InventarioItemForm({
  action,
  item,
  ubicaciones,
  columnasTowing,
  esNuevo,
}: {
  action: (formData: FormData) => void;
  item?: InventarioItem;
  ubicaciones: Ubicacion[];
  columnasTowing?: boolean;
  esNuevo?: boolean;
}) {
  return (
    <form action={action} className="card" style={{ maxWidth: 760 }}>
      <div className="form-grid">
        <div className="fg">
          <label>Item</label>
          <input name="nombre" defaultValue={item?.nombre} required />
        </div>
        <div className="fg">
          <label>{columnasTowing ? "Cert. / Nro de serie" : "P/N"}</label>
          <input name="codigo" defaultValue={item?.codigo ?? ""} />
        </div>
        <div className="fg">
          <label>{columnasTowing ? "Fabricante" : "Marca"}</label>
          <input name="marca" defaultValue={item?.marca ?? ""} />
        </div>
        <div className="fg">
          <label>Ubicacion</label>
          <select name="ubicacion_id" defaultValue={item?.ubicacion_id ?? ""}>
            <option value="">Sin asignar</option>
            {ubicaciones.map((u) => (
              <option key={u.id} value={u.id}>
                {u.nombre}
              </option>
            ))}
          </select>
        </div>
        {columnasTowing && (
          <div className="fg">
            <label>WLL / MBL</label>
            <input name="wll_mbl" defaultValue={item?.wll_mbl ?? ""} placeholder="Ej. MBL 350T" />
          </div>
        )}
        {columnasTowing && (
          <div className="fg">
            <label>Fecha (fabricacion / certificado)</label>
            <input type="date" name="fecha_referencia" defaultValue={item?.fecha_referencia ?? ""} />
          </div>
        )}
        {columnasTowing && (
          <div className="fg">
            <label>Estado</label>
            <select name="estado" defaultValue={item?.estado ?? "activo"}>
              <option value="activo">Activo</option>
              <option value="cuarentena">Cuarentena</option>
              <option value="baja">Baja</option>
            </select>
          </div>
        )}
        {!columnasTowing && (
          <div className="fg">
            <label>Grupo / Sistema</label>
            <input name="grupo" defaultValue={item?.grupo ?? ""} placeholder="Ej. MMPP MAK 8 M" />
          </div>
        )}
        {esNuevo && (
          <div className="fg">
            <label>Cantidad inicial</label>
            <input type="number" step="1" min="0" name="cantidad_inicial" defaultValue={0} />
          </div>
        )}
      </div>

      <div className="fg">
        <label>Comentarios</label>
        <textarea name="comentarios" defaultValue={item?.comentarios ?? ""} rows={3} />
      </div>

      {!esNuevo && (
        <div className="info-box mt16">
          Cantidad actual: <strong className="text-mono">{item?.cantidad ?? 0}</strong>. Para
          modificarla usa &quot;Reportar cambio de inventario&quot; desde la lista, asi queda
          registrado el motivo.
        </div>
      )}

      <div className="flex-between mt16" style={{ justifyContent: "flex-end" }}>
        <button type="submit" className="btn btn-primary">
          Guardar
        </button>
      </div>
    </form>
  );
}
