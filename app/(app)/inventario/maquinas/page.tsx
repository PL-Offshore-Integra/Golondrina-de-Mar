import { createClient } from "@/lib/supabase/server";
import InventarioLista from "@/components/InventarioLista";
import type { InventarioItem, Ubicacion } from "@/lib/types";

export default async function InventarioMaquinasPage({
  searchParams,
}: {
  searchParams: Promise<{ q?: string; ubicacion?: string }>;
}) {
  const { q, ubicacion } = await searchParams;
  const supabase = await createClient();

  let query = supabase
    .from("inventario_items")
    .select("*, ubicaciones(nombre)")
    .eq("categoria", "maquinas")
    .order("nombre");

  if (q) query = query.or(`nombre.ilike.%${q}%,codigo.ilike.%${q}%`);
  if (ubicacion) query = query.eq("ubicacion_id", ubicacion);

  const [{ data: items, error }, { data: ubicaciones }] = await Promise.all([
    query,
    supabase.from("ubicaciones").select("*").eq("activo", true).order("nombre"),
  ]);

  if (error) {
    return (
      <div className="info-box danger">
        No se pudo cargar Supabase todavia: {error.message}. Configura .env.local y corre las
        migraciones en supabase/migrations.
      </div>
    );
  }

  return (
    <InventarioLista
      basePath="/inventario/maquinas"
      items={(items ?? []) as InventarioItem[]}
      ubicaciones={(ubicaciones ?? []) as Ubicacion[]}
      q={q}
      ubicacionFiltro={ubicacion}
    />
  );
}
