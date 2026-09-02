import { notFound } from "next/navigation";
import Link from "next/link";
import { createClient } from "@/lib/supabase/server";
import InventarioItemForm from "@/components/InventarioItemForm";
import type { InventarioItem, Ubicacion } from "@/lib/types";
import { deleteItem, updateItem } from "../../actions";

export default async function EditarItemMaquinasPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  const supabase = await createClient();

  const [{ data: item }, { data: ubicaciones }] = await Promise.all([
    supabase.from("inventario_items").select("*, ubicaciones(nombre)").eq("id", id).single(),
    supabase.from("ubicaciones").select("*").eq("activo", true).order("nombre"),
  ]);

  if (!item) notFound();

  const update = updateItem.bind(null, "maquinas", id);
  const remove = deleteItem.bind(null, "maquinas", id);

  return (
    <div>
      <div className="flex-between mb16">
        <span className="tag">{(item as InventarioItem).nombre}</span>
        <div className="flex-gap">
          <Link href={`/inventario/maquinas/${id}/movimiento`} className="btn btn-ghost btn-sm">
            Reportar cambio
          </Link>
          <form action={remove}>
            <button type="submit" className="btn btn-danger btn-sm">
              Eliminar
            </button>
          </form>
        </div>
      </div>
      <InventarioItemForm
        action={update}
        item={item as InventarioItem}
        ubicaciones={(ubicaciones ?? []) as Ubicacion[]}
      />
    </div>
  );
}
