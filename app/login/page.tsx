"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { createClient } from "@/lib/supabase/client";

export default function LoginPage() {
  const router = useRouter();
  const [email, setEmail] = useState("");
  const [pass, setPass] = useState("");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");

  const handleLogin = async () => {
    setLoading(true);
    setError("");
    try {
      const supabase = createClient();
      const { error: e } = await supabase.auth.signInWithPassword({ email, password: pass });
      if (e) {
        setError("Credenciales incorrectas. Verifica tu email y contrasena.");
        return;
      }
      router.push("/");
      router.refresh();
    } catch {
      setError("Error de conexion. Verifica tu red e intenta nuevamente.");
    } finally {
      setLoading(false);
    }
  };

  const handleKey = (e: React.KeyboardEvent) => {
    if (e.key === "Enter") handleLogin();
  };

  return (
    <div className="login-page">
      <div className="login-left">
        <img src="/integra-logo-white-noclaim.svg" alt="INTEGRA" className="login-left-integra-img" />
        <div>
          <div className="login-left-divider" />
          <div className="login-left-company">
            <img src="/PL.png" alt="PL Offshore" className="login-left-company-logo" />
            <div className="login-left-company-name">PL Offshore | Golondrina de Mar</div>
          </div>
          <div className="login-left-line" />
          <div className="login-left-sub">We Find the Way, or We Make One.</div>
        </div>
      </div>

      <div className="login-right">
        <div className="login-card">
          <div className="login-card-eyebrow">PL Offshore | Golondrina de Mar</div>
          <div className="login-card-title">Acceso al portal</div>
          <div className="login-card-sub">Solo personal autorizado</div>
          {error && <div className="login-error">{error}</div>}
          <div className="login-fg">
            <label>Email</label>
            <input
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              onKeyDown={handleKey}
              placeholder="usuario@terra-mare.com.ar"
              autoFocus
            />
          </div>
          <div className="login-fg">
            <label>Contrasena</label>
            <input
              type="password"
              value={pass}
              onChange={(e) => setPass(e.target.value)}
              onKeyDown={handleKey}
              placeholder="********"
            />
          </div>
          <button className="login-btn" onClick={handleLogin} disabled={loading || !email || !pass}>
            {loading ? "Ingresando..." : "Ingresar →"}
          </button>
          <div className="login-footer">PL Offshore &middot; Acceso restringido</div>
        </div>
      </div>
    </div>
  );
}
