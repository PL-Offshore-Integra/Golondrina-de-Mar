import { createClient } from "@/lib/supabase/server";
import type { MotivoMovimiento, Ubicacion } from "@/lib/types";
import {
  alternarMotivo,
  alternarUbicacion,
  crearMotivo,
  crearUbicacion,
  renombrarUbicacion,
} from "./actions";

const TIPO_LABEL: Record<string, string> = {
  alta: "Alta",
  baja: "Baja",
  ambos: "Alta y baja",
};

export default async function CatalogosPage() {
  const supabase = await createClient();

  const [{ data: ubicaciones }, { data: motivos }] = await Promise.all([
    supabase.from("ubicaciones").select("*").order("nombre"),
    supabase.from("motivos_movimiento").select("*").order("orden"),
  ]);

  const listaUbicaciones = (ubicaciones ?? []) as Ubicacion[];
  const listaMotivos = (motivos ?? []) as MotivoMovimiento[];

  return (
    <div>
      <div className="card">
        <div className="card-title">Ubicaciones a bordo</div>
        <p className="text-muted mb16">
          Catalogo de lugares del buque donde se guardan los items del inventario. Se usan al
          cargar o editar un item.
        </p>

        <div className="table-wrap">
          <table>
            <thead>
              <tr>
                <th>Nombre</th>
                <th>Descripcion</th>
                <th>Estado</th>
                <th />
              </tr>
            </thead>
            <tbody>
              {listaUbicaciones.map((u) => {
                const renombrar = renombrarUbicacion.bind(null, u.id);
                const activar = alternarUbicacion.bind(null, u.id, !u.activo);
                return (
                  <tr key={u.id}>
                    <td style={{ minWidth: 200 }}>
                      <form action={renombrar} className="flex-gap">
                        <input name="nombre" defaultValue={u.nombre} className="filter-input" required />
                        <input
                          name="descripcion"
                          defaultValue={u.descripcion ?? ""}
                          placeholder="Descripcion (opcional)"
                          className="filter-input"
                        />
                        <button type="submit" className="btn btn-ghost btn-sm">
                          Guardar
                        </button>
                      </form>
                    </td>
                    <td className="text-muted">{u.descripcion ?? "-"}</td>
                    <td>
                      <span className={`badge ${u.activo ? "b-green" : "b-gray"}`}>
                        {u.activo ? "Activa" : "Inactiva"}
                      </span>
                    </td>
                    <td style={{ textAlign: "right" }}>
                      <form action={activar}>
                        <button type="submit" className="btn btn-ghost btn-sm">
                          {u.activo ? "Desactivar" : "Activar"}
                        </button>
                      </form>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>

        <div className="form-section">Nueva ubicacion</div>
        <form action={crearUbicacion} className="filter-row">
          <input name="nombre" placeholder="Nombre de la ubicacion" required className="filter-input" />
          <input name="descripcion" placeholder="Descripcion (opcional)" className="filter-input" />
          <button type="submit" className="btn btn-primary btn-sm">
            Agregar
          </button>
        </form>
      </div>

      <div className="card">
        <div className="card-title">Motivos de cambio de inventario</div>
        <p className="text-muted mb16">
          Catalogo de razones para reportar una alta o baja de stock (compra, perdida, rotura,
          instalacion, etc.).
        </p>

        <div className="table-wrap">
          <table>
            <thead>
              <tr>
                <th>Motivo</th>
                <th>Aplica a</th>
                <th>Estado</th>
                <th />
              </tr>
            </thead>
            <tbody>
              {listaMotivos.map((m) => {
                const activar = alternarMotivo.bind(null, m.id, !m.activo);
                return (
                  <tr key={m.id}>
                    <td>{m.nombre}</td>
                    <td>
                      <span className="tag">{TIPO_LABEL[m.tipo] ?? m.tipo}</span>
                    </td>
                    <td>
                      <span className={`badge ${m.activo ? "b-green" : "b-gray"}`}>
                        {m.activo ? "Activo" : "Inactivo"}
                      </span>
                    </td>
                    <td style={{ textAlign: "right" }}>
                      <form action={activar}>
                        <button type="submit" className="btn btn-ghost btn-sm">
                          {m.activo ? "Desactivar" : "Activar"}
                        </button>
                      </form>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>

        <div className="form-section">Nuevo motivo</div>
        <form action={crearMotivo} className="filter-row">
          <input name="nombre" placeholder="Nombre del motivo" required className="filter-input" />
          <select name="tipo" defaultValue="ambos" className="filter-select">
            <option value="alta">Solo alta</option>
            <option value="baja">Solo baja</option>
            <option value="ambos">Alta y baja</option>
          </select>
          <button type="submit" className="btn btn-primary btn-sm">
            Agregar
          </button>
        </form>
      </div>
    </div>
  );
}
