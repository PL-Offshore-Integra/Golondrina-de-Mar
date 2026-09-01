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
# completar NEXT_PUBLIC_SUPABASE_ANON_KEY y SUPABASE_SERVICE_ROLE_KEY
# desde https://supabase.com/dashboard/project/mwrhonkvcyyueixbdrat/settings/api
npm run dev
```

## Base de datos

Las tablas de este buque viven en el esquema `golondrina_de_mar` (no en
`public`), para no chocar con tablas de otros modulos en el mismo proyecto
Supabase compartido (ej. `comercial`, `proveedores`).

1. Abrir el SQL Editor del proyecto Supabase.
2. Correr `supabase/migrations/0001_init.sql` (crea el esquema; agregar ahi
   las tablas propias de este buque a medida que se definan).
3. En **Project Settings > API > Exposed schemas**, agregar
   `golondrina_de_mar` a la lista de esquemas expuestos (por defecto solo
   `public` esta expuesto), o el cliente de Supabase no va a poder
   leer/escribir estas tablas.

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
- `app/(app)/page.tsx` — pantalla de inicio (placeholder, a completar).
- `components/Shell.tsx` — navegacion y encabezado, estilo PL Offshore.
- `proxy.ts` — refresca la sesion de Supabase en cada request (antes
  `middleware.ts`; Next.js 16 renombro la convencion a "Proxy").
- `supabase/migrations` — esquema SQL.
