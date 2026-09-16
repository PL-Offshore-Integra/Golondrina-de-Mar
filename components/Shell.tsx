"use client";

import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import { createClient } from "@/lib/supabase/client";

type NavItem = { href: string; label: string; icon: keyof typeof ICONS };
type NavGroup = { titulo: string; items: NavItem[] };

const Ico = ({ d, size = 18 }: { d: React.ReactNode; size?: number }) => (
  <svg
    width={size}
    height={size}
    viewBox="0 0 24 24"
    fill="none"
    stroke="currentColor"
    strokeWidth="1.6"
    strokeLinecap="round"
    strokeLinejoin="round"
    aria-hidden="true"
  >
    {d}
  </svg>
);

const ICONS = {
  home: (
    <>
      <path d="M3 10.5 12 3l9 7.5" />
      <path d="M5 9.5V21h14V9.5" />
    </>
  ),
  gear: (
    <>
      <circle cx="12" cy="12" r="3" />
      <path d="M4 12h2M18 12h2M12 4v2M12 18v2M6.3 6.3l1.4 1.4M16.3 16.3l1.4 1.4M6.3 17.7l1.4-1.4M16.3 7.7l1.4-1.4" />
    </>
  ),
  catalog: (
    <>
      <rect x="4" y="4" width="16" height="16" rx="2" />
      <path d="M8 9h8M8 13h8M8 17h5" />
    </>
  ),
  towing: (
    <>
      <circle cx="7" cy="17" r="2.5" />
      <circle cx="17" cy="7" r="2.5" />
      <path d="M9 15.5 15 8.5" />
    </>
  ),
  deck: (
    <>
      <circle cx="12" cy="5" r="1.5" />
      <path d="M12 6.5V21" />
      <path d="M8 9h8" />
      <path d="M5 12a7 7 0 0 0 14 0" />
      <path d="M5 12H3M19 12h2" />
    </>
  ),
};

const NAV: NavGroup[] = [
  { titulo: "General", items: [{ href: "/", label: "Inicio", icon: "home" }] },
  {
    titulo: "Inventario",
    items: [
      { href: "/inventario/maquinas", label: "Inventario Maquinas", icon: "gear" },
      { href: "/inventario/towing-gear", label: "Inventario Towing Gear", icon: "towing" },
      { href: "/inventario/cubierta", label: "Inventario Cubierta", icon: "deck" },
    ],
  },
  { titulo: "Catalogos", items: [{ href: "/catalogos", label: "Ubicaciones y motivos", icon: "catalog" }] },
];

const SECCIONES: Record<string, { grupo: string; titulo: string; sub: string }> = {
  "/": { grupo: "General", titulo: "Inicio", sub: "" },
  "/inventario/maquinas": {
    grupo: "Inventario",
    titulo: "Inventario Maquinas",
    sub: "Herramientas y repuestos del buque, por ubicacion.",
  },
  "/inventario/towing-gear": {
    grupo: "Inventario",
    titulo: "Inventario Towing Gear",
    sub: "Elementos de remolque: cables, grilletes, placas, con certificacion y WLL/MBL.",
  },
  "/inventario/cubierta": {
    grupo: "Inventario",
    titulo: "Inventario Cubierta",
    sub: "Elementos y pañol de cubierta: amarre, LSA, pintura, ferreteria y consumibles, por ubicacion.",
  },
  "/catalogos": {
    grupo: "Catalogos",
    titulo: "Ubicaciones y motivos",
    sub: "Catalogos editables de ubicaciones a bordo y motivos de alta/baja de stock.",
  },
};

function seccionFor(pathname: string) {
  if (SECCIONES[pathname]) return SECCIONES[pathname];
  if (pathname.startsWith("/inventario/maquinas/")) {
    if (pathname.endsWith("/nueva")) {
      return { grupo: "Inventario", titulo: "Nuevo item - Maquinas", sub: "" };
    }
    if (pathname.endsWith("/movimiento")) {
      return { grupo: "Inventario", titulo: "Reportar cambio de inventario", sub: "" };
    }
    return { grupo: "Inventario", titulo: "Editar item - Maquinas", sub: "" };
  }
  if (pathname.startsWith("/inventario/towing-gear/")) {
    if (pathname.endsWith("/nueva")) {
      return { grupo: "Inventario", titulo: "Nuevo item - Towing Gear", sub: "" };
    }
    if (pathname.endsWith("/movimiento")) {
      return { grupo: "Inventario", titulo: "Reportar cambio de inventario", sub: "" };
    }
    return { grupo: "Inventario", titulo: "Editar item - Towing Gear", sub: "" };
  }
  if (pathname.startsWith("/inventario/cubierta/")) {
    if (pathname.endsWith("/nueva")) {
      return { grupo: "Inventario", titulo: "Nuevo item - Cubierta", sub: "" };
    }
    if (pathname.endsWith("/movimiento")) {
      return { grupo: "Inventario", titulo: "Reportar cambio de inventario", sub: "" };
    }
    return { grupo: "Inventario", titulo: "Editar item - Cubierta", sub: "" };
  }
  return { grupo: "Golondrina de Mar", titulo: "Golondrina de Mar", sub: "" };
}

export default function Shell({
  userEmail,
  children,
}: {
  userEmail: string;
  children: React.ReactNode;
}) {
  const pathname = usePathname();
  const router = useRouter();
  const seccion = seccionFor(pathname);
  const inicial = (userEmail || "G").replace(/@.*$/, "").slice(0, 2).toUpperCase();

  const handleLogout = async () => {
    const supabase = createClient();
    await supabase.auth.signOut();
    router.push("/login");
    router.refresh();
  };

  return (
    <>
      <header className="appbar">
        <img src="/integra-isotipo-white.svg" alt="INTEGRA" className="appbar-iso" />
        <span className="appbar-div" />
        <span className="appbar-instance">PL Offshore</span>
        <div className="appbar-tools">
          <span className="appbar-avatar">{inicial}</span>
          <span className="appbar-user">{userEmail}</span>
          <button className="appbar-link" onClick={handleLogout}>
            Cerrar sesion
          </button>
        </div>
      </header>

      <div className="shell">
        <nav className="sidebar">
          <div className="sidebar-header">
            <img src="/PL.png" alt="PL Offshore" className="sidebar-logo-img" />
            <div>
              <div className="sidebar-logo-main">Golondrina de Mar</div>
              <div className="sidebar-logo-sub">PL Offshore</div>
            </div>
          </div>

          <div className="sidebar-nav">
            {NAV.map((grupo) => (
              <div key={grupo.titulo} style={{ marginBottom: 8 }}>
                <div className="nav-section">{grupo.titulo}</div>
                {grupo.items.map((item) => {
                  const active =
                    item.href === "/" ? pathname === "/" : pathname.startsWith(item.href);
                  return (
                    <Link key={item.href} href={item.href} className={`ni ${active ? "active" : ""}`}>
                      <span className="ni-ico">
                        <Ico d={ICONS[item.icon]} />
                      </span>
                      <span className="ni-label">{item.label}</span>
                    </Link>
                  );
                })}
              </div>
            ))}
          </div>

          <div className="sidebar-foot">
            <div className="sidebar-foot-meta">
              <div>GOLONDRINA DE MAR v0.2</div>
              <div>POWERED BY INTEGRA</div>
            </div>
          </div>
        </nav>

        <div className="main">
          <div className="pagehead">
            <div className="crumb">
              <span>{seccion.grupo}</span>
              <span>/</span>
              <span className="crumb-current">{seccion.titulo}</span>
            </div>
            <div className="pagehead-row">
              <div>
                <h1>{seccion.titulo}</h1>
                {seccion.sub && <p>{seccion.sub}</p>}
              </div>
            </div>
          </div>

          <div className="content">{children}</div>
        </div>
      </div>
    </>
  );
}
