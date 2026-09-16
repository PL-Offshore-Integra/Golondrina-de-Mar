import { createClient } from "@/lib/supabase/server";
import InventarioItemForm from "@/components/InventarioItemForm";
import type { Ubicacion } from "@/lib/types";
import { createItem } from "../../actions";

export default async function NuevoItemTowingGearPage() {
  const supabase = await createClient();
  const { data: ubicaciones } = await supabase
    .from("ubicaciones")
    .select("*")
    .eq("activo", true)
    .order("nombre");

  const crear = createItem.bind(null, "towing_gear");

  return (
    <InventarioItemForm
      action={crear}
      ubicaciones={(ubicaciones ?? []) as Ubicacion[]}
      columnasTowing
      esNuevo
    />
  );
}
