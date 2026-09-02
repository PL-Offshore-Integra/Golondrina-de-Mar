-- Modulo de inventario: maquinas.
-- Las cantidades solo se modifican a traves de inventario_movimientos (alta/baja
-- con motivo y detalle); el resto de los campos del item se edita directamente.

create table golondrina_de_mar.ubicaciones (
  id uuid primary key default gen_random_uuid(),
  nombre text not null unique,
  descripcion text,
  activo boolean not null default true,
  created_at timestamptz not null default now()
);

create table golondrina_de_mar.motivos_movimiento (
  id uuid primary key default gen_random_uuid(),
  nombre text not null unique,
  tipo text not null check (tipo in ('alta', 'baja', 'ambos')),
  activo boolean not null default true,
  orden int not null default 0
);

create table golondrina_de_mar.inventario_items (
  id uuid primary key default gen_random_uuid(),
  categoria text not null,
  grupo text,
  nombre text not null,
  codigo text,
  marca text,
  cantidad numeric not null default 0 check (cantidad >= 0),
  ubicacion_id uuid references golondrina_de_mar.ubicaciones(id) on delete set null,
  wll_mbl text,
  fecha_referencia date,
  estado text not null default 'activo' check (estado in ('activo', 'cuarentena', 'baja')),
  comentarios text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table golondrina_de_mar.inventario_movimientos (
  id uuid primary key default gen_random_uuid(),
  item_id uuid not null references golondrina_de_mar.inventario_items(id) on delete cascade,
  tipo text not null check (tipo in ('alta', 'baja')),
  cantidad numeric not null check (cantidad > 0),
  motivo_id uuid references golondrina_de_mar.motivos_movimiento(id),
  detalle text,
  usuario_email text,
  created_at timestamptz not null default now()
);

create index inventario_items_categoria_idx on golondrina_de_mar.inventario_items(categoria);
create index inventario_items_ubicacion_idx on golondrina_de_mar.inventario_items(ubicacion_id);
create index inventario_movimientos_item_idx on golondrina_de_mar.inventario_movimientos(item_id);

alter table golondrina_de_mar.ubicaciones enable row level security;
alter table golondrina_de_mar.motivos_movimiento enable row level security;
alter table golondrina_de_mar.inventario_items enable row level security;
alter table golondrina_de_mar.inventario_movimientos enable row level security;

create policy "authenticated_all_ubicaciones" on golondrina_de_mar.ubicaciones
  for all to authenticated using (true) with check (true);

create policy "authenticated_all_motivos_movimiento" on golondrina_de_mar.motivos_movimiento
  for all to authenticated using (true) with check (true);

create policy "authenticated_all_inventario_items" on golondrina_de_mar.inventario_items
  for all to authenticated using (true) with check (true);

-- Los movimientos son un registro de auditoria: se pueden crear y leer, pero no
-- editar ni borrar (evita reescribir el historial de altas/bajas).
create policy "authenticated_select_inventario_movimientos" on golondrina_de_mar.inventario_movimientos
  for select to authenticated using (true);

create policy "authenticated_insert_inventario_movimientos" on golondrina_de_mar.inventario_movimientos
  for insert to authenticated with check (true);

create or replace function golondrina_de_mar.set_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

create trigger inventario_items_set_updated_at
  before update on golondrina_de_mar.inventario_items
  for each row execute function golondrina_de_mar.set_updated_at();

-- Cada movimiento ajusta el stock del item automaticamente: alta suma,
-- baja resta (sin bajar de cero).
create or replace function golondrina_de_mar.aplicar_movimiento_inventario()
returns trigger as $$
begin
  if new.tipo = 'alta' then
    update golondrina_de_mar.inventario_items
      set cantidad = cantidad + new.cantidad
      where id = new.item_id;
  else
    update golondrina_de_mar.inventario_items
      set cantidad = greatest(cantidad - new.cantidad, 0)
      where id = new.item_id;
  end if;
  return new;
end;
$$ language plpgsql;

create trigger inventario_movimientos_aplicar
  after insert on golondrina_de_mar.inventario_movimientos
  for each row execute function golondrina_de_mar.aplicar_movimiento_inventario();

insert into golondrina_de_mar.motivos_movimiento (nombre, tipo, orden) values
  ('Compra', 'alta', 1),
  ('Devolucion', 'alta', 2),
  ('Instalacion', 'baja', 3),
  ('Utilizacion / Consumo', 'baja', 4),
  ('Rotura', 'baja', 5),
  ('Perdida', 'baja', 6),
  ('Ajuste de inventario', 'ambos', 7);
