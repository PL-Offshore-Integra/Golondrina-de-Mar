"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import type { Categoria } from "@/lib/types";

function str(formData: FormData, key: string): string | null {
  const value = formData.get(key);
  if (typeof value !== "string" || value.trim() === "") return null;
  return value.trim();
}

function num(formData: FormData, key: string, fallback = 0): number {
  const value = formData.get(key);
  const parsed = typeof value === "string" ? Number(value) : NaN;
  return Number.isFinite(parsed) ? parsed : fallback;
}

function listPath(_categoria: Categoria) {
  return "/inventario/maquinas";
}

function itemFields(formData: FormData) {
  // "estado" no aparece en el formulario de maquinas (unico usado aca): si
  // no vino en el form, no se incluye, para no pisar el valor actual.
  const estado = str(formData, "estado");
  return {
    nombre: str(formData, "nombre") ?? "",
    grupo: str(formData, "grupo"),
    codigo: str(formData, "codigo"),
    marca: str(formData, "marca"),
    ubicacion_id: str(formData, "ubicacion_id"),
    wll_mbl: str(formData, "wll_mbl"),
    fecha_referencia: str(formData, "fecha_referencia"),
    comentarios: str(formData, "comentarios"),
    ...(estado ? { estado } : {}),
  };
}

export async function createItem(categoria: Categoria, formData: FormData) {
  const supabase = await createClient();
  const cantidadInicial = num(formData, "cantidad_inicial", 0);
  const { data, error } = await supabase
    .from("inventario_items")
    .insert({ categoria, ...itemFields(formData), cantidad: 0 })
    .select("id")
    .single();
  if (error) throw new Error(error.message);

  if (cantidadInicial > 0 && data) {
    const { error: movError } = await supabase.from("inventario_movimientos").insert({
      item_id: data.id,
      tipo: "alta",
      cantidad: cantidadInicial,
      detalle: "Carga inicial del item",
    });
    if (movError) throw new Error(movError.message);
  }

  revalidatePath(listPath(categoria));
  redirect(listPath(categoria));
}

export async function updateItem(categoria: Categoria, id: string, formData: FormData) {
  const supabase = await createClient();
  const { error } = await supabase.from("inventario_items").update(itemFields(formData)).eq("id", id);
  if (error) throw new Error(error.message);
  revalidatePath(listPath(categoria));
  redirect(listPath(categoria));
}

export async function deleteItem(categoria: Categoria, id: string) {
  const supabase = await createClient();
  const { error } = await supabase.from("inventario_items").delete().eq("id", id);
  if (error) throw new Error(error.message);
  revalidatePath(listPath(categoria));
  redirect(listPath(categoria));
}

export async function crearMovimiento(categoria: Categoria, itemId: string, formData: FormData) {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  const tipo = str(formData, "tipo");
  const cantidad = num(formData, "cantidad", 0);
  if (tipo !== "alta" && tipo !== "baja") throw new Error("Tipo de movimiento invalido");
  if (cantidad <= 0) throw new Error("La cantidad tiene que ser mayor a 0");

  const { error } = await supabase.from("inventario_movimientos").insert({
    item_id: itemId,
    tipo,
    cantidad,
    motivo_id: str(formData, "motivo_id"),
    detalle: str(formData, "detalle"),
    usuario_email: user?.email ?? null,
  });
  if (error) throw new Error(error.message);

  revalidatePath(listPath(categoria));
  revalidatePath(`${listPath(categoria)}/${itemId}`);
  redirect(`${listPath(categoria)}/${itemId}`);
}
