import Link from "next/link";

export default function Home() {
  return (
    <div className="stats">
      <Link href="/inventario/maquinas" className="stat" style={{ cursor: "pointer" }}>
        <div className="stat-label">Inventario</div>
        <div className="stat-value" style={{ fontSize: 18 }}>
          Maquinas
        </div>
      </Link>
      <Link href="/catalogos" className="stat" style={{ cursor: "pointer" }}>
        <div className="stat-label">Catalogos</div>
        <div className="stat-value" style={{ fontSize: 18 }}>
          Ubicaciones y motivos
        </div>
      </Link>
    </div>
  );
}
