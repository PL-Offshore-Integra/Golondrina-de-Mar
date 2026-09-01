"use client";

import { usePathname, useRouter } from "next/navigation";
import { createClient } from "@/lib/supabase/client";

export default function Shell({
  userEmail,
  children,
}: {
  userEmail: string;
  children: React.ReactNode;
}) {
  const pathname = usePathname();
  const router = useRouter();
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
            <div className="nav-section">General</div>
            <div className={`ni ${pathname === "/" ? "active" : ""}`}>
              <span className="ni-label">Inicio</span>
            </div>
          </div>

          <div className="sidebar-foot">
            <div className="sidebar-foot-meta">
              <div>GOLONDRINA DE MAR v0.1</div>
              <div>POWERED BY INTEGRA</div>
            </div>
          </div>
        </nav>

        <div className="main">
          <div className="pagehead">
            <div className="crumb">
              <span>Golondrina de Mar</span>
              <span>/</span>
              <span className="crumb-current">Inicio</span>
            </div>
            <div className="pagehead-row">
              <div>
                <h1>Inicio</h1>
              </div>
            </div>
          </div>

          <div className="content">{children}</div>
        </div>
      </div>
    </>
  );
}
