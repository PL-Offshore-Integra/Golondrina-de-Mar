-- Exponer el schema en Data API no alcanza: Postgres tambien exige permisos
-- explicitos de USAGE (schema) y SELECT/INSERT/UPDATE/DELETE (tablas) para
-- el rol "authenticated", ademas de las RLS policies ya creadas.
grant usage on schema golondrina_de_mar to authenticated, service_role;
grant all on all tables in schema golondrina_de_mar to authenticated, service_role;
grant all on all sequences in schema golondrina_de_mar to authenticated, service_role;
grant all on all functions in schema golondrina_de_mar to authenticated, service_role;

-- Para que las tablas que se creen mas adelante en este schema hereden
-- los mismos permisos automaticamente.
alter default privileges in schema golondrina_de_mar
  grant all on tables to authenticated, service_role;
alter default privileges in schema golondrina_de_mar
  grant all on sequences to authenticated, service_role;
alter default privileges in schema golondrina_de_mar
  grant all on functions to authenticated, service_role;

notify pgrst, 'reload schema';
