"use server";

import { revalidatePath } from "next/cache";
import { createClient } from "@/lib/supabase/server";

function str(formData: FormData, key: string): string | null {
  const value = formData.get(key);
  if (typeof value !== "string" || value.trim() === "") return null;
  return value.trim();
}

export async function crearUbicacion(formData: FormData) {
  const supabase = await createClient();
  const nombre = str(formData, "nombre");
  if (!nombre) return;
  const { error } = await supabase
    .from("ubicaciones")
    .insert({ nombre, descripcion: str(formData, "descripcion") });
  if (error) throw new Error(error.message);
  revalidatePath("/catalogos");
}

export async function renombrarUbicacion(id: string, formData: FormData) {
  const supabase = await createClient();
  const nombre = str(formData, "nombre");
  if (!nombre) return;
  const { error } = await supabase
    .from("ubicaciones")
    .update({ nombre, descripcion: str(formData, "descripcion") })
    .eq("id", id);
  if (error) throw new Error(error.message);
  revalidatePath("/catalogos");
}

export async function alternarUbicacion(id: string, activo: boolean) {
  const supabase = await createClient();
  const { error } = await supabase.from("ubicaciones").update({ activo }).eq("id", id);
  if (error) throw new Error(error.message);
  revalidatePath("/catalogos");
}

export async function crearMotivo(formData: FormData) {
  const supabase = await createClient();
  const nombre = str(formData, "nombre");
  const tipo = str(formData, "tipo") ?? "ambos";
  if (!nombre) return;
  const { error } = await supabase.from("motivos_movimiento").insert({ nombre, tipo });
  if (error) throw new Error(error.message);
  revalidatePath("/catalogos");
}

export async function alternarMotivo(id: string, activo: boolean) {
  const supabase = await createClient();
  const { error } = await supabase.from("motivos_movimiento").update({ activo }).eq("id", id);
  if (error) throw new Error(error.message);
  revalidatePath("/catalogos");
}
