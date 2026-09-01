-- Esquema dedicado para no interferir con otras tablas del proyecto compartido
create schema if not exists golondrina_de_mar;

-- Las tablas de este buque se agregan aca, todas dentro del esquema golondrina_de_mar.
-- Ejemplo de patron a seguir (RLS + policy de solo autenticados), ver
-- PL-Offshore-Comerical/supabase/migrations/0001_init.sql para referencia completa:
--
-- create table golondrina_de_mar.<tabla> (
--   id uuid primary key default gen_random_uuid(),
--   ...
--   created_at timestamptz not null default now()
-- );
-- alter table golondrina_de_mar.<tabla> enable row level security;
-- create policy "authenticated_all_<tabla>" on golondrina_de_mar.<tabla>
--   for all to authenticated using (true) with check (true);
