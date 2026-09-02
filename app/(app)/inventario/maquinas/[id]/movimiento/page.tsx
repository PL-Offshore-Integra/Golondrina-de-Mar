import { notFound } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import InventarioMovimientoForm from "@/components/InventarioMovimientoForm";
import type { InventarioItem, InventarioMovimiento, MotivoMovimiento } from "@/lib/types";
import { crearMovimiento } from "../../../actions";

export default async function MovimientoItemMaquinasPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;
  const supabase = await createClient();

  const [{ data: item }, { data: motivos }, { data: historial }] = await Promise.all([
    supabase.from("inventario_items").select("*").eq("id", id).single(),
    supabase.from("motivos_movimiento").select("*").eq("activo", true).order("orden"),
    supabase
      .from("inventario_movimientos")
      .select("*, motivos_movimiento(nombre)")
      .eq("item_id", id)
      .order("created_at", { ascending: false }),
  ]);

  if (!item) notFound();

  const registrar = crearMovimiento.bind(null, "maquinas", id);

  return (
    <div>
      <div className="mb16">
        <span className="tag">{(item as InventarioItem).nombre}</span>
      </div>
      <InventarioMovimientoForm
        action={registrar}
        motivos={(motivos ?? []) as MotivoMovimiento[]}
        cantidadActual={(item as InventarioItem).cantidad}
        historial={(historial ?? []) as InventarioMovimiento[]}
      />
    </div>
  );
}
