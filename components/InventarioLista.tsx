import Link from "next/link";
import type { InventarioItem, Ubicacion } from "@/lib/types";

const ESTADO_BADGE: Record<string, string> = {
  activo: "b-green",
  cuarentena: "b-amber",
  baja: "b-gray",
};

const ESTADO_LABEL: Record<string, string> = {
  activo: "Activo",
  cuarentena: "Cuarentena",
  baja: "Baja",
};

export default function InventarioLista({
  basePath,
  items,
  ubicaciones,
  q,
  ubicacionFiltro,
  columnasTowing,
}: {
  basePath: string;
  items: InventarioItem[];
  ubicaciones: Ubicacion[];
  q?: string;
  ubicacionFiltro?: string;
  columnasTowing?: boolean;
}) {
  const sinUbicacion = "sin-ubicacion";
  const grupos = new Map<string, { nombre: string; items: InventarioItem[] }>();

  for (const item of items) {
    const key = item.ubicacion_id ?? sinUbicacion;
    const nombre = item.ubicaciones?.nombre ?? "Sin ubicacion asignada";
    if (!grupos.has(key)) grupos.set(key, { nombre, items: [] });
    grupos.get(key)!.items.push(item);
  }

  const gruposOrdenados = Array.from(grupos.values()).sort((a, b) => a.nombre.localeCompare(b.nombre));

  return (
    <div>
      <div className="card">
        <form className="filter-row">
          <input
            type="search"
            name="q"
            placeholder="Buscar por nombre o codigo"
            defaultValue={q ?? ""}
            className="filter-input"
          />
          <select name="ubicacion" defaultValue={ubicacionFiltro ?? ""} className="filter-select">
            <option value="">Todas las ubicaciones</option>
            {ubicaciones.map((u) => (
              <option key={u.id} value={u.id}>
                {u.nombre}
              </option>
            ))}
          </select>
          <button type="submit" className="btn btn-ghost btn-sm">
            Filtrar
          </button>
          {(q || ubicacionFiltro) && (
            <Link href={basePath} className="btn btn-ghost btn-sm">
              Limpiar
            </Link>
          )}
          <Link href={`${basePath}/nueva`} className="btn btn-primary btn-sm" style={{ marginLeft: "auto" }}>
            + Nuevo item
          </Link>
        </form>
      </div>

      {items.length === 0 && <div className="empty-state">No hay items para los filtros aplicados.</div>}

      {gruposOrdenados.map((grupo) => (
        <div key={grupo.nombre} className="card">
          <div className="card-title">
            <span>
              {grupo.nombre} <span className="text-muted">({grupo.items.length})</span>
            </span>
          </div>
          <div className="table-wrap">
            <table>
              <thead>
                <tr>
                  <th>Item</th>
                  <th>Codigo</th>
                  <th>Marca</th>
                  {columnasTowing && <th>WLL / MBL</th>}
                  <th>Cantidad</th>
                  {columnasTowing && <th>Estado</th>}
                  <th>Comentarios</th>
                  <th />
                </tr>
              </thead>
              <tbody>
                {grupo.items.map((item) => (
                  <tr key={item.id} className="click">
                    <td>{item.nombre}</td>
                    <td className="text-mono">{item.codigo ?? "-"}</td>
                    <td>{item.marca ?? "-"}</td>
                    {columnasTowing && <td className="text-mono">{item.wll_mbl ?? "-"}</td>}
                    <td className="text-mono">{item.cantidad}</td>
                    {columnasTowing && (
                      <td>
                        <span className={`badge ${ESTADO_BADGE[item.estado] ?? "b-gray"}`}>
                          {ESTADO_LABEL[item.estado] ?? item.estado}
                        </span>
                      </td>
                    )}
                    <td className="text-muted">{item.comentarios ?? "-"}</td>
                    <td style={{ textAlign: "right", whiteSpace: "nowrap" }}>
                      <Link href={`${basePath}/${item.id}`} className="btn btn-ghost btn-sm">
                        Ver / Editar
                      </Link>{" "}
                      <Link href={`${basePath}/${item.id}/movimiento`} className="btn btn-ghost btn-sm">
                        Reportar cambio
                      </Link>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      ))}
    </div>
  );
}
