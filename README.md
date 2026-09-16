# Golondrina de Mar

Portal de gestion del buque Golondrina de Mar, dentro de la organizacion PL Offshore.

Stack: Next.js (App Router) + TypeScript + Supabase (datos y Auth). Estetica
y layout tomados del sistema de marca "INTEGRA Brand Book v1.0" (IBM Plex
Sans/Mono, navy `#002247` para la instancia PL Offshore), mismo shell (barra
superior + sidebar) y misma pantalla de login que el resto de los modulos
PL Offshore.

- GitHub: https://github.com/PL-Offshore-Integra/Golondrina-de-Mar
- Supabase (proyecto compartido, esquema propio `golondrina_de_mar`):
  https://supabase.com/dashboard/project/mwrhonkvcyyueixbdrat
- Vercel: https://vercel.com/terracompras-projects

## Setup local

```bash
npm install
cp .env.local.example .env.local
# completar NEXT_PUBLIC_SUPABASE_ANON_KEY
# desde https://supabase.com/dashboard/project/mwrhonkvcyyueixbdrat/settings/api
npm run dev
```

## Base de datos

Las tablas de este buque viven en el esquema `golondrina_de_mar` (no en
`public`), para no chocar con tablas de otros modulos en el mismo proyecto
Supabase compartido (ej. `comercial`, `proveedores`).

1. Abrir el SQL Editor del proyecto Supabase.
2. Correr en orden `0001_init.sql`, `0002_inventario.sql` y
   `0003_seed_inventario.sql` (el ultimo carga los datos migrados desde el
   Excel de inventario de maquinas — se puede omitir si se prefiere
   arrancar vacio).
3. En **Project Settings > API > Exposed schemas**, agregar
   `golondrina_de_mar` a la lista de esquemas expuestos (por defecto solo
   `public` esta expuesto), o el cliente de Supabase no va a poder
   leer/escribir estas tablas.

## Modulo de inventario

Tres categorias de items, en la misma tabla (`inventario_items.categoria`):
`maquinas` (herramientas y repuestos), `towing_gear` (elementos de
remolque, con WLL/MBL, fabricante y fecha de certificado) y `cubierta`
(pañol y elementos de cubierta: amarre, LSA, pintura, ferreteria y
consumibles). `cubierta` reutiliza el layout simple de `maquinas` (sin
WLL/MBL ni certificado), con el campo de agrupacion rotulado "Grupo /
Rubro". La `categoria` es texto libre en la base (sin CHECK), asi que
sumar categorias no requiere migracion de esquema.

- **Ubicaciones** y **motivos de movimiento** son catalogos editables desde
  `/catalogos` (sin tocar la base a mano).
- La **cantidad** de un item nunca se edita directamente: se ajusta
  solamente a traves de "Reportar cambio de inventario" (alta o baja, con
  motivo y detalle libre), que queda registrado en
  `inventario_movimientos` y actualiza el stock por trigger. El resto de
  los campos del item (nombre, ubicacion, comentarios, etc.) se edita
  directo desde la ficha del item.

## Usuarios (login)

No hay alta de usuarios publica: el acceso es por invitacion. Para crear el
primer usuario, en el dashboard de Supabase ir a **Authentication > Users >
Add user**, cargar email y contrasena, y compartirle esos datos a la
persona. Cualquier usuario de Supabase Auth del proyecto puede loguearse
(el aislamiento de datos lo da el esquema, no el login).

## Deploy

1. `git push` a `main` en GitHub.
2. En Vercel (team `terracompras-projects`), importar el repo
   `PL-Offshore-Integra/Golondrina-de-Mar`.
3. Configurar las mismas variables de entorno que en `.env.local` en el
   proyecto de Vercel.

## Estructura

- `app/login` — pantalla de acceso (Supabase Auth, email + contrasena).
- `app/(app)/layout.tsx` — exige sesion activa y arma el shell (barra
  superior + sidebar + encabezado de pantalla).
- `app/(app)/page.tsx` — pantalla de inicio, con accesos rapidos a los modulos.
- `app/(app)/inventario/maquinas`, `app/(app)/inventario/towing-gear` y
  `app/(app)/inventario/cubierta` — listado por ubicacion, alta/edicion de
  items y reporte de movimientos.
- `app/(app)/catalogos` — administracion de ubicaciones y motivos.
- `components/InventarioLista.tsx`, `InventarioItemForm.tsx`,
  `InventarioMovimientoForm.tsx` — UI del modulo de inventario.
- `components/Shell.tsx` — navegacion y encabezado, estilo PL Offshore.
- `proxy.ts` — refresca la sesion de Supabase en cada request (antes
  `middleware.ts`; Next.js 16 renombro la convencion a "Proxy").
- `supabase/migrations` — esquema SQL.
