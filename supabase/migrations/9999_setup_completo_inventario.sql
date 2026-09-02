-- COPIA COMBINADA PARA PEGAR DE UNA SOLA VEZ EN EL SQL EDITOR DE SUPABASE.
-- Es la union, en orden, de 0002_inventario.sql + 0003_seed_inventario.sql.
-- Correr una sola vez; no volver a correr este archivo (ni los dos
-- originales) despues de haberlo corrido, porque "create table" fallaria
-- al encontrar las tablas ya creadas.
--
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
-- Datos migrados desde "Inventario Maquinas Golo (2).xlsx".
insert into golondrina_de_mar.ubicaciones (nombre) values
  ('Camarote JDM'),
  ('Pañol'),
  ('Taller de máquinas'),
  ('Máquinas entre motores');

insert into golondrina_de_mar.inventario_items
  (categoria, nombre, codigo, marca, cantidad, ubicacion_id, comentarios)
select * from (values
  ('maquinas', 'Fusibles Ficha', null, null, 15, (select id from golondrina_de_mar.ubicaciones where nombre = 'Camarote JDM'), null),
  ('maquinas', 'RELEVO TERMICO 10A', 'TR1-T0-10A', 'MONTERO', 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Camarote JDM'), null),
  ('maquinas', 'RELEVO TERMICO 80A', 'TR1-T0-80A', 'MONTERO', 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Camarote JDM'), null),
  ('maquinas', 'FILTRO ORGANICO', null, null, 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Camarote JDM'), null),
  ('maquinas', 'EPOXI', null, null, 2, (select id from golondrina_de_mar.ubicaciones where nombre = 'Camarote JDM'), null),
  ('maquinas', 'TOBERA', 'H140T43F529', null, 22, (select id from golondrina_de_mar.ubicaciones where nombre = 'Camarote JDM'), null),
  ('maquinas', 'ALAMBRE PARA FUSIBLE 6A', null, null, 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Camarote JDM'), null),
  ('maquinas', 'BUJIA', 'B7H5-10', 'YAMAHA', 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Camarote JDM'), null),
  ('maquinas', 'TOBERA', '313510', 'SCANIA', 4, (select id from golondrina_de_mar.ubicaciones where nombre = 'Camarote JDM'), null),
  ('maquinas', 'FUSIBLE 5A', null, null, 3, (select id from golondrina_de_mar.ubicaciones where nombre = 'Camarote JDM'), null),
  ('maquinas', 'FUSIBLE 20A', 'F831-20', null, 5, (select id from golondrina_de_mar.ubicaciones where nombre = 'Camarote JDM'), null),
  ('maquinas', 'FUSIBLE 30A', null, null, 15, (select id from golondrina_de_mar.ubicaciones where nombre = 'Camarote JDM'), null),
  ('maquinas', 'FUSIBLE 6A', 'F831-06', null, 2, (select id from golondrina_de_mar.ubicaciones where nombre = 'Camarote JDM'), null),
  ('maquinas', 'FUSIBLE 10A', 'F831-10', null, 6, (select id from golondrina_de_mar.ubicaciones where nombre = 'Camarote JDM'), null),
  ('maquinas', 'FUSIBLE 16A', 'F831-16', null, 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Camarote JDM'), null),
  ('maquinas', 'FUSIBLE 1A', null, null, 3, (select id from golondrina_de_mar.ubicaciones where nombre = 'Camarote JDM'), null),
  ('maquinas', 'FUSIBLE 4A', null, null, 3, (select id from golondrina_de_mar.ubicaciones where nombre = 'Camarote JDM'), null),
  ('maquinas', 'CINTA AISLANTE 18mm-20m', null, null, 3, (select id from golondrina_de_mar.ubicaciones where nombre = 'Camarote JDM'), null),
  ('maquinas', 'ALICATE PARA ANILLO DE RETENCION', null, 'STANLEY', 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Camarote JDM'), null),
  ('maquinas', 'MULTIMETRO', null, 'RUHLMAN', 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Camarote JDM'), null),
  ('maquinas', 'PACK ELECTRODOS', null, null, 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Camarote JDM'), null),
  ('maquinas', 'DISCOS AMOLADORA METAL', null, null, 5, (select id from golondrina_de_mar.ubicaciones where nombre = 'Camarote JDM'), null),
  ('maquinas', 'DISCOS AMOLADORA FLAP', null, null, 3, (select id from golondrina_de_mar.ubicaciones where nombre = 'Camarote JDM'), null),
  ('maquinas', 'EMBOLO SISTEMA AUTOMATICO CLUTCH', null, null, 4, (select id from golondrina_de_mar.ubicaciones where nombre = 'Camarote JDM'), null),
  ('maquinas', 'ORING SISTEMA AUTOMATICO CLUTCH', null, null, 31, (select id from golondrina_de_mar.ubicaciones where nombre = 'Camarote JDM'), null),
  ('maquinas', 'SOLDADORA ESTAÑO Y SOPORTE', null, null, 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Camarote JDM'), null),
  ('maquinas', 'VALVULA ESFERA 1/2''''', null, null, 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Camarote JDM'), null),
  ('maquinas', 'MANOMETRO', 'MM2-45', 'BEYCA', 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Camarote JDM'), null),
  ('maquinas', 'VALVULA EXPANSIÓN TERMOSTATICA', 'HFES10HC', 'EMERSON', 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Camarote JDM'), null),
  ('maquinas', 'LLAVE COMBINADA 41mm', null, null, 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Camarote JDM'), null),
  ('maquinas', 'RELEVO TERMICO 18-25A', null, 'SIEMENS', 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Camarote JDM'), null),
  ('maquinas', 'PLAQUETA REGULADORA DE TENSION', null, null, 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Camarote JDM'), null),
  ('maquinas', 'VALVULA DE BOTADOR', '30018', 'SCANIA', 12, (select id from golondrina_de_mar.ubicaciones where nombre = 'Camarote JDM'), null),
  ('maquinas', 'LLAVE DE TUBO', null, null, 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Camarote JDM'), null),
  ('maquinas', 'PISTOLA DE AIRE PARA SOPLETE', null, null, 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Camarote JDM'), null),
  ('maquinas', 'VARILLA DE BOTADOR', null, null, 2, (select id from golondrina_de_mar.ubicaciones where nombre = 'Camarote JDM'), null),
  ('maquinas', 'VALVULA SOLENOIDE 0,1-10BAR', null, 'JEFFERSON', 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Camarote JDM'), null),
  ('maquinas', 'PINZA PORTA ELECTRODO', null, null, 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Camarote JDM'), null),
  ('maquinas', 'ARCO DE SIERRA ALTA TENSION', null, null, 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Camarote JDM'), null),
  ('maquinas', 'ORINGS 2-116', '2-116', null, 10, (select id from golondrina_de_mar.ubicaciones where nombre = 'Camarote JDM'), null),
  ('maquinas', 'ORINGS 2-011', '2-011', null, 7, (select id from golondrina_de_mar.ubicaciones where nombre = 'Camarote JDM'), null),
  ('maquinas', 'ORINGS 2-113', '2-113', null, 10, (select id from golondrina_de_mar.ubicaciones where nombre = 'Camarote JDM'), null),
  ('maquinas', 'ORINGS 2-115', '2-115', null, 10, (select id from golondrina_de_mar.ubicaciones where nombre = 'Camarote JDM'), null),
  ('maquinas', 'RODAMIENTO', '3307B2RSR', 'BSK', 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Camarote JDM'), null),
  ('maquinas', 'JUNTA', '392204', null, 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Camarote JDM'), null),
  ('maquinas', 'PLATILLO DE VALVULA', '30097', null, 6, (select id from golondrina_de_mar.ubicaciones where nombre = 'Camarote JDM'), null),
  ('maquinas', 'ARANDELA GRILLON', '337875', null, 2, (select id from golondrina_de_mar.ubicaciones where nombre = 'Camarote JDM'), null),
  ('maquinas', 'AROS RASCA ACEITE', null, null, 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Camarote JDM'), null),
  ('maquinas', 'AROS COMPRESION', null, null, 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Camarote JDM'), null),
  ('maquinas', 'VALVULA REGULADORA DE PRESION 0,5-8,5BAR', null, null, 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Camarote JDM'), null),
  ('maquinas', 'VALVULA REGULADORA DE PRESION 0,15-3,5MPA', null, null, 2, (select id from golondrina_de_mar.ubicaciones where nombre = 'Camarote JDM'), null),
  ('maquinas', 'VALVULA ARRANQUE MOTOR PPAL', null, null, 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Camarote JDM'), null),
  ('maquinas', 'ESPARRAGO DE PUENTE DE BALANCIN', null, null, 4, (select id from golondrina_de_mar.ubicaciones where nombre = 'Camarote JDM'), null),
  ('maquinas', 'JUNTA DRESSER 72-85', null, null, 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Camarote JDM'), null),
  ('maquinas', 'JUNTA DRESSER 48-58', null, null, 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Camarote JDM'), null),
  ('maquinas', 'LAMPARA REFLECTOR DE ALCANZE 400W', 'HPI-TPLUS400', null, 3, (select id from golondrina_de_mar.ubicaciones where nombre = 'Camarote JDM'), null),
  ('maquinas', 'MASCARA DE SOLDAR', null, null, 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Camarote JDM'), null),
  ('maquinas', 'CARGADOR DE BATERIAS', null, 'BLACK&DECKER', 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Camarote JDM'), null),
  ('maquinas', 'ELECTROVALVULA', null, null, 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Camarote JDM'), null),
  ('maquinas', 'JUEGO DE MECHAS', null, null, 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Camarote JDM'), 'INCOMPLETO'),
  ('maquinas', 'CAJA ORINGS VERDES', null, null, 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Camarote JDM'), null),
  ('maquinas', 'CINTA METRICA 5M', null, null, 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Camarote JDM'), null),
  ('maquinas', 'CUTTER', null, null, 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Camarote JDM'), null),
  ('maquinas', 'JUEGO LETRAS', null, null, 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Camarote JDM'), null),
  ('maquinas', 'CORTA FRIOS HEXAGONAL 18/21', null, null, 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Camarote JDM'), null),
  ('maquinas', 'JUEGO COLA DE CHANCHO', null, null, 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Camarote JDM'), null),
  ('maquinas', 'LLAVE COMBINADA 5/8', null, null, 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Camarote JDM'), null),
  ('maquinas', 'LLAVE COMBINADA 3/4', null, null, 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Camarote JDM'), null),
  ('maquinas', 'LLAVE COMBINADA 3/8', null, null, 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Camarote JDM'), null),
  ('maquinas', 'LLAVE COMBINADA 19', null, null, 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Camarote JDM'), null),
  ('maquinas', 'LLAVE COMBINADA 17', null, null, 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Camarote JDM'), null),
  ('maquinas', 'LLAVE COMBINADA 13', null, null, 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Camarote JDM'), null),
  ('maquinas', 'LLAVE COMBINADA 10', null, null, 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Camarote JDM'), null),
  ('maquinas', 'LLAVE COMBINADA 8', null, null, 3, (select id from golondrina_de_mar.ubicaciones where nombre = 'Camarote JDM'), null),
  ('maquinas', 'LLAVE COMBINADA 7', null, null, 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Camarote JDM'), null),
  ('maquinas', 'LLAVE COMBINADA 6', null, null, 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Camarote JDM'), null),
  ('maquinas', 'LLAVE ALLEN HEX 1/16', null, 'STANLEY', 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Camarote JDM'), null),
  ('maquinas', 'LLAVE ALLEN HEX 5/64', null, 'STANLEY', 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Camarote JDM'), null),
  ('maquinas', 'LLAVE ALLEN HEX 3/32', null, 'STANLEY', 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Camarote JDM'), null),
  ('maquinas', 'LLAVE ALLEN HEX 7/64', null, 'STANLEY', 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Camarote JDM'), null),
  ('maquinas', 'LLAVE ALLEN HEX 1/8', null, 'STANLEY', 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Camarote JDM'), null),
  ('maquinas', 'LLAVE ALLEN HEX 9/64', null, 'STANLEY', 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Camarote JDM'), null),
  ('maquinas', 'LLAVE ALLEN HEX 5/32', null, 'STANLEY', 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Camarote JDM'), null),
  ('maquinas', 'LLAVE ALLEN HEX 3/16', null, 'STANLEY', 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Camarote JDM'), null),
  ('maquinas', 'LLAVE ALLEN HEX 7/32', null, 'STANLEY', 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Camarote JDM'), null),
  ('maquinas', 'LLAVE ALLEN HEX 1/4', null, 'STANLEY', 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Camarote JDM'), null),
  ('maquinas', 'LLAVE ALLEN HEX 5/16', null, 'STANLEY', 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Camarote JDM'), null),
  ('maquinas', 'LLAVE ALLEN HEX 3/8', null, 'STANLEY', 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Camarote JDM'), null),
  ('maquinas', 'LLAVE TUBOS 1-11/16', null, 'STANLEY', 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Camarote JDM'), null),
  ('maquinas', 'LLAVE TUBOS 7/8', null, 'STANLEY', 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Camarote JDM'), null),
  ('maquinas', 'LLAVE TUBOS 7/16', null, 'STANLEY', 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Camarote JDM'), null),
  ('maquinas', 'LLAVE TUBOS 3/4', null, 'STANLEY', 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Camarote JDM'), null),
  ('maquinas', 'LLAVE TUBOS 30', null, 'STANLEY', 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Camarote JDM'), null),
  ('maquinas', 'LLAVE TUBOS 11', null, 'STANLEY', 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Camarote JDM'), null),
  ('maquinas', 'TIJERA MULTIUSOS', null, null, 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Camarote JDM'), null),
  ('maquinas', 'ALICATE', null, 'CROSSMAN', 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Camarote JDM'), null),
  ('maquinas', 'DESTORNILLADOR PLANO', null, null, 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Camarote JDM'), null),
  ('maquinas', 'DESTORNILLADOR PHILIPS', null, null, 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Camarote JDM'), null),
  ('maquinas', 'LLAVR ALLEN 1/2', null, null, 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Camarote JDM'), null),
  ('maquinas', 'HIDROMETRO DE BATERIA', null, 'RUHLMAN', 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Pañol'), null),
  ('maquinas', 'AMOLADORA GRANDE', null, 'MAKITA', 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Pañol'), null),
  ('maquinas', 'TERRAJAS', null, null, 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Pañol'), null),
  ('maquinas', 'CEPILLO CIRCULAR 150', null, null, 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Pañol'), null),
  ('maquinas', 'VALVULA ESFERICA 3/4', null, null, 3, (select id from golondrina_de_mar.ubicaciones where nombre = 'Pañol'), null),
  ('maquinas', 'SILICONA ACETICA 280ml', null, null, 4, (select id from golondrina_de_mar.ubicaciones where nombre = 'Pañol'), null),
  ('maquinas', 'VALVULA ESFERICA 1/2', null, null, 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Pañol'), null),
  ('maquinas', 'DISCO AMOLADORA 180', null, null, 6, (select id from golondrina_de_mar.ubicaciones where nombre = 'Pañol'), null),
  ('maquinas', 'DISCO AMOLADORA 115', null, null, 5, (select id from golondrina_de_mar.ubicaciones where nombre = 'Pañol'), null),
  ('maquinas', 'DISCO AMOLADORA ABRASIVO 115', null, null, 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Pañol'), null),
  ('maquinas', 'DISCO AMOLADORA ABRASIVO 178', null, null, 4, (select id from golondrina_de_mar.ubicaciones where nombre = 'Pañol'), null),
  ('maquinas', 'BORNERA', null, null, 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Pañol'), null),
  ('maquinas', 'MANGUERA HIDRAULICA', null, null, 3, (select id from golondrina_de_mar.ubicaciones where nombre = 'Pañol'), null),
  ('maquinas', 'ASIENTOS DE VALVULA', null, null, 8, (select id from golondrina_de_mar.ubicaciones where nombre = 'Pañol'), null),
  ('maquinas', 'CORREAS DE GENERADORES', null, null, 2, (select id from golondrina_de_mar.ubicaciones where nombre = 'Pañol'), null),
  ('maquinas', 'PAQUETE ELECTRODOS', null, null, 3, (select id from golondrina_de_mar.ubicaciones where nombre = 'Pañol'), null),
  ('maquinas', 'LLAVE COMBINADA 32', null, 'BAHCO', 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Taller de máquinas'), null),
  ('maquinas', 'LLAVE COMBINADA 30', null, 'BAHCO', 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Taller de máquinas'), null),
  ('maquinas', 'LLAVE COMBINADA 29', null, 'BAHCO', 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Taller de máquinas'), null),
  ('maquinas', 'LLAVE COMBINADA 28', null, 'BAHCO', 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Taller de máquinas'), null),
  ('maquinas', 'LLAVE COMBINADA 27', null, 'BAHCO', 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Taller de máquinas'), null),
  ('maquinas', 'LLAVE COMBINADA 26', null, 'BAHCO', 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Taller de máquinas'), null),
  ('maquinas', 'LLAVE COMBINADA 25', null, 'BAHCO', 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Taller de máquinas'), null),
  ('maquinas', 'LLAVE COMBINADA 24', null, 'BAHCO', 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Taller de máquinas'), null),
  ('maquinas', 'LLAVE COMBINADA 23', null, 'BAHCO', 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Taller de máquinas'), null),
  ('maquinas', 'LLAVE COMBINADA 22', null, 'BAHCO', 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Taller de máquinas'), null),
  ('maquinas', 'LLAVE COMBINADA 21', null, 'BAHCO', 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Taller de máquinas'), null),
  ('maquinas', 'LLAVE COMBINADA 20', null, 'BAHCO', 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Taller de máquinas'), null),
  ('maquinas', 'LLAVE COMBINADA 19', null, 'BAHCO', 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Taller de máquinas'), null),
  ('maquinas', 'LLAVE COMBINADA 18', null, 'BAHCO', 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Taller de máquinas'), null),
  ('maquinas', 'LLAVE COMBINADA 17', null, 'BAHCO', 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Taller de máquinas'), null),
  ('maquinas', 'LLAVE COMBINADA 16', null, 'BAHCO', 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Taller de máquinas'), null),
  ('maquinas', 'LLAVE COMBINADA 15', null, 'BAHCO', 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Taller de máquinas'), null),
  ('maquinas', 'LLAVE COMBINADA 14', null, 'BAHCO', 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Taller de máquinas'), null),
  ('maquinas', 'LLAVE COMBINADA 13', null, 'BAHCO', 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Taller de máquinas'), null),
  ('maquinas', 'LLAVE COMBINADA 12', null, 'BAHCO', 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Taller de máquinas'), null),
  ('maquinas', 'LLAVE COMBINADA 11', null, 'BAHCO', 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Taller de máquinas'), null),
  ('maquinas', 'LLAVE COMBINADA 10', null, 'BAHCO', 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Taller de máquinas'), null),
  ('maquinas', 'LLAVE COMBINADA 9', null, 'BAHCO', 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Taller de máquinas'), null),
  ('maquinas', 'LLAVE COMBINADA 8', null, 'BAHCO', 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Taller de máquinas'), null),
  ('maquinas', 'LLAVE COMBINADA 7', null, 'BAHCO', 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Taller de máquinas'), null),
  ('maquinas', 'LLAVE COMBINADA 6', null, 'BAHCO', 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Taller de máquinas'), null),
  ('maquinas', 'LLAVE COMBINADA 1''''', null, 'BAHCO', 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Taller de máquinas'), null),
  ('maquinas', 'LLAVE COMBINADA 15/16', null, 'BAHCO', 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Taller de máquinas'), null),
  ('maquinas', 'LLAVE COMBINADA 13/16', null, 'BAHCO', 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Taller de máquinas'), null),
  ('maquinas', 'LLAVE COMBINADA 7/8', null, 'BAHCO', 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Taller de máquinas'), null),
  ('maquinas', 'LLAVE COMBINADA 3/4', null, 'BAHCO', 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Taller de máquinas'), null),
  ('maquinas', 'LLAVE COMBINADA 11/16', null, 'BAHCO', 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Taller de máquinas'), null),
  ('maquinas', 'LLAVE COMBINADA 5/8', null, 'BAHCO', 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Taller de máquinas'), null),
  ('maquinas', 'LLAVE COMBINADA 9/16', null, 'BAHCO', 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Taller de máquinas'), null),
  ('maquinas', 'LLAVE COMBINADA 1/2', null, 'BAHCO', 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Taller de máquinas'), null),
  ('maquinas', 'LLAVE COMBINADA 7/16', null, 'BAHCO', 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Taller de máquinas'), null),
  ('maquinas', 'LLAVE COMBINADA 5/16', null, 'BAHCO', 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Taller de máquinas'), null),
  ('maquinas', 'LLAVE COMBINADA 3/8', null, 'BAHCO', 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Taller de máquinas'), null),
  ('maquinas', 'LLAVE DOBLE BOCA 5/8 - 11/16', null, 'BAHCO', 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Taller de máquinas'), null),
  ('maquinas', 'LLAVE DOBLE BOCA 1/2 - 9/16', null, 'BAHCO', 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Taller de máquinas'), null),
  ('maquinas', 'PISTOLA DE AIRE PARA SOPLETE', null, 'MICROGAS', 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Taller de máquinas'), null),
  ('maquinas', 'PISTOLA PARA ENGRASE', null, null, 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Taller de máquinas'), null),
  ('maquinas', 'DESTORNILLADOR PLANO', null, null, 2, (select id from golondrina_de_mar.ubicaciones where nombre = 'Taller de máquinas'), null),
  ('maquinas', 'DESTORNILLADOR PHILIPS', null, null, 3, (select id from golondrina_de_mar.ubicaciones where nombre = 'Taller de máquinas'), null),
  ('maquinas', 'LLAVE INGLESA 250mm', null, 'STANLEY', 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Taller de máquinas'), null),
  ('maquinas', 'PINZA PLANA', null, 'CROSSMASTER', 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Taller de máquinas'), null),
  ('maquinas', 'TENAZA', null, null, 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Taller de máquinas'), null),
  ('maquinas', 'ARCO DE CIERRA', null, null, 2, (select id from golondrina_de_mar.ubicaciones where nombre = 'Taller de máquinas'), null),
  ('maquinas', 'LLAVE T 7', null, null, 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Taller de máquinas'), null),
  ('maquinas', 'LLAVE T 8', null, null, 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Taller de máquinas'), null),
  ('maquinas', 'LLAVE T 10', null, null, 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Taller de máquinas'), null),
  ('maquinas', 'LLAVE T 1/2', null, null, 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Taller de máquinas'), null),
  ('maquinas', 'TUBO 15/16', null, 'STANLEY', 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Taller de máquinas'), null),
  ('maquinas', 'TUBO 7/8', null, 'STANLEY', 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Taller de máquinas'), null),
  ('maquinas', 'TUBO 13/16', null, 'STANLEY', 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Taller de máquinas'), null),
  ('maquinas', 'TUBO 3/4', null, 'STANLEY', 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Taller de máquinas'), null),
  ('maquinas', 'TUBO 11/16', null, 'STANLEY', 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Taller de máquinas'), null),
  ('maquinas', 'TUBO 9/16', null, 'STANLEY', 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Taller de máquinas'), null),
  ('maquinas', 'TUBO 7/16', null, 'STANLEY', 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Taller de máquinas'), null),
  ('maquinas', 'TUBO 3/8', null, 'STANLEY', 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Taller de máquinas'), null),
  ('maquinas', 'ESCUADRA', null, null, 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Taller de máquinas'), null),
  ('maquinas', 'LLAVE PARA FILTRO', null, null, 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Taller de máquinas'), null),
  ('maquinas', 'SOPLETE BUTANO', null, 'RUHLMAN', 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Taller de máquinas'), null),
  ('maquinas', 'AMOLADORA', null, 'UMI', 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Taller de máquinas'), null),
  ('maquinas', 'TALADRO DE MANO', null, null, 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Taller de máquinas'), null),
  ('maquinas', 'MULTIMETRO DIGITAL', null, null, 2, (select id from golondrina_de_mar.ubicaciones where nombre = 'Taller de máquinas'), '1 NO PRENDE'),
  ('maquinas', 'LLAVE INGLESA 52mm', null, null, 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Taller de máquinas'), null),
  ('maquinas', 'LLAVE INGLESA 143mm', null, null, 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Taller de máquinas'), null),
  ('maquinas', 'LLAVE INGLESA 18', null, 'GEDORE', 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Taller de máquinas'), null),
  ('maquinas', 'MARTILLO DE BOLA', null, null, 2, (select id from golondrina_de_mar.ubicaciones where nombre = 'Taller de máquinas'), null),
  ('maquinas', 'MAZO', null, null, 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Taller de máquinas'), null),
  ('maquinas', 'CALIBRE', null, null, 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Taller de máquinas'), null),
  ('maquinas', 'CEPILLO DE ACERO', null, null, 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Taller de máquinas'), null),
  ('maquinas', 'ACEITERA', null, null, 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Taller de máquinas'), null),
  ('maquinas', 'CAJA DE ORINGS VARIOS', null, null, 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Taller de máquinas'), null),
  ('maquinas', 'REMACHADORA POP', null, null, 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Taller de máquinas'), null),
  ('maquinas', 'SOPLETE PARA CALENTAR', null, null, 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Taller de máquinas'), null),
  ('maquinas', 'DESTORNILLADOR PHILIPS', null, null, 2, (select id from golondrina_de_mar.ubicaciones where nombre = 'Taller de máquinas'), null),
  ('maquinas', 'DESTORNILLADOR PLANO', null, null, 3, (select id from golondrina_de_mar.ubicaciones where nombre = 'Taller de máquinas'), null),
  ('maquinas', 'CUTTER', null, null, 3, (select id from golondrina_de_mar.ubicaciones where nombre = 'Taller de máquinas'), null),
  ('maquinas', 'ALICATE', null, 'PROSKIT', 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Taller de máquinas'), null),
  ('maquinas', 'LLAVE COMBINADA 9/16', null, null, 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Taller de máquinas'), null),
  ('maquinas', 'SOLDADORA DE ESTAÑO', null, null, 2, (select id from golondrina_de_mar.ubicaciones where nombre = 'Taller de máquinas'), null),
  ('maquinas', 'MASCARA DE SOLDAR', null, null, 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Taller de máquinas'), null),
  ('maquinas', 'LLAVE ALLEN HEX 4', null, null, 4, (select id from golondrina_de_mar.ubicaciones where nombre = 'Taller de máquinas'), null),
  ('maquinas', 'LLAVE ALLEN HEX 9', null, null, 2, (select id from golondrina_de_mar.ubicaciones where nombre = 'Taller de máquinas'), null),
  ('maquinas', 'LLAVE ALLEN HEX 3', null, null, 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Taller de máquinas'), null),
  ('maquinas', 'LLAVE ALLEN HEX 8', null, null, 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Taller de máquinas'), null),
  ('maquinas', 'LLAVE ALLEN HEX 10', null, null, 2, (select id from golondrina_de_mar.ubicaciones where nombre = 'Taller de máquinas'), null),
  ('maquinas', 'LLAVE ALLEN HEX 5', null, null, 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Taller de máquinas'), null),
  ('maquinas', 'LLAVE ALLEN HEX 2', null, null, 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Taller de máquinas'), null),
  ('maquinas', 'LLAVE ALLEN HEX 11', null, null, 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Taller de máquinas'), null),
  ('maquinas', 'LLAVE ALLEN HEX 13', null, null, 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Taller de máquinas'), null),
  ('maquinas', 'LLAVE ALLEN HEX  14', null, null, 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Taller de máquinas'), null),
  ('maquinas', 'TERMOMETRO INFRAROJO', null, null, 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Taller de máquinas'), null),
  ('maquinas', 'EXTRACTOR DE FILTRO', null, null, 2, (select id from golondrina_de_mar.ubicaciones where nombre = 'Taller de máquinas'), null),
  ('maquinas', 'LLAVE DISCO AMOLADORA', null, null, 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Taller de máquinas'), null),
  ('maquinas', 'CINTA PARA SUNCHADORA', null, null, 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Taller de máquinas'), null),
  ('maquinas', 'LLAVE COMBINADA 34', null, null, 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Máquinas entre motores'), null),
  ('maquinas', 'CRICKET', null, 'RUHLMAN', 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Máquinas entre motores'), null),
  ('maquinas', 'PISTOLA SILICONA', null, null, 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Máquinas entre motores'), null),
  ('maquinas', 'TUBO 16', null, 'STANLEY', 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Máquinas entre motores'), null),
  ('maquinas', 'TUBO 17', null, 'STANLEY', 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Máquinas entre motores'), null),
  ('maquinas', 'TUBO 18', null, 'STANLEY', 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Máquinas entre motores'), null),
  ('maquinas', 'TUBO 19', null, 'STANLEY', 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Máquinas entre motores'), null),
  ('maquinas', 'TUBO 20', null, 'STANLEY', 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Máquinas entre motores'), null),
  ('maquinas', 'TUBO 22', null, 'STANLEY', 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Máquinas entre motores'), null),
  ('maquinas', 'TUBO 23', null, 'STANLEY', 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Máquinas entre motores'), null),
  ('maquinas', 'TUBO 25', null, 'STANLEY', 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Máquinas entre motores'), null),
  ('maquinas', 'TUBO 26', null, 'STANLEY', 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Máquinas entre motores'), null),
  ('maquinas', 'TUBO 27', null, 'STANLEY', 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Máquinas entre motores'), null),
  ('maquinas', 'TUBO 28', null, 'STANLEY', 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Máquinas entre motores'), null),
  ('maquinas', 'TUBO 30', null, 'STANLEY', 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Máquinas entre motores'), null),
  ('maquinas', 'TUBO 29', null, 'STANLEY', 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Máquinas entre motores'), null),
  ('maquinas', 'TUBO 11', null, 'STANLEY', 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Máquinas entre motores'), null),
  ('maquinas', 'TUBO 38', null, 'STANLEY', 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Máquinas entre motores'), null),
  ('maquinas', 'TUBO 1/2', null, 'STANLEY', 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Máquinas entre motores'), null),
  ('maquinas', 'TUBO 1-5/8', null, 'STANLEY', 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Máquinas entre motores'), null),
  ('maquinas', 'TUBO 2''''', null, 'BAHCO', 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Máquinas entre motores'), null),
  ('maquinas', 'ESPEJO', null, null, 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Máquinas entre motores'), null),
  ('maquinas', 'LLAVE INGLESA 300mm', null, 'STANLEY', 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Máquinas entre motores'), null),
  ('maquinas', 'EXTENSOR CRICKET', null, 'STANLEY', 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Máquinas entre motores'), null),
  ('maquinas', 'CARDAN CRICKET', null, 'STANLEY', 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Máquinas entre motores'), null),
  ('maquinas', 'LLAVE EXTRACTORA PARA INYECTORES', null, null, 1, (select id from golondrina_de_mar.ubicaciones where nombre = 'Máquinas entre motores'), null)
) as t (categoria, nombre, codigo, marca, cantidad, ubicacion_id, comentarios);
