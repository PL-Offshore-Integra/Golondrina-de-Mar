export type Categoria = "maquinas" | "towing_gear" | "cubierta";

export type EstadoItem = "activo" | "cuarentena" | "baja";

export type TipoMovimiento = "alta" | "baja";

export type TipoMotivo = "alta" | "baja" | "ambos";

export interface Ubicacion {
  id: string;
  nombre: string;
  descripcion: string | null;
  activo: boolean;
  created_at: string;
}

export interface MotivoMovimiento {
  id: string;
  nombre: string;
  tipo: TipoMotivo;
  activo: boolean;
  orden: number;
}

export interface InventarioItem {
  id: string;
  categoria: Categoria;
  grupo: string | null;
  nombre: string;
  codigo: string | null;
  marca: string | null;
  cantidad: number;
  ubicacion_id: string | null;
  wll_mbl: string | null;
  fecha_referencia: string | null;
  estado: EstadoItem;
  comentarios: string | null;
  created_at: string;
  updated_at: string;
  ubicaciones?: { nombre: string } | null;
}

export interface InventarioMovimiento {
  id: string;
  item_id: string;
  tipo: TipoMovimiento;
  cantidad: number;
  motivo_id: string | null;
  detalle: string | null;
  usuario_email: string | null;
  created_at: string;
  motivos_movimiento?: { nombre: string } | null;
}
