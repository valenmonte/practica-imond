"""Genera web/data.json, el dataset que lee el dashboard de GitHub Pages.

Lee las tablas del data warehouse (dw/*.csv, generadas por run_sql.py) y
deja un JSON compacto en web/.

Uso (desde la raiz del repo, con el entorno virtual activado):
    python run_sql.py
    python build_dashboard.py
"""
import json
from pathlib import Path

import duckdb

DW = Path("dw")
OUT = Path("web")
OUT.mkdir(exist_ok=True)

TABLAS = ["dim_date", "dim_channel", "dim_province", "dim_product", "dim_customer",
          "fact_orders", "fact_sales", "fact_web_session", "fact_nps", "fact_shipment"]
faltan = [t for t in TABLAS if not (DW / f"{t}.csv").exists()]
if faltan:
    raise SystemExit(f"Faltan en dw/: {', '.join(faltan)}. Ejecuta primero: python run_sql.py")

con = duckdb.connect()
for t in TABLAS:
    con.execute(f"CREATE VIEW {t} AS SELECT * FROM read_csv_auto('{(DW / t).as_posix()}.csv')")


def rows(sql):
    return [list(r) for r in con.execute(sql).fetchall()]


DAY = "strftime(CAST(d.full_date AS DATE), '%Y-%m-%d')"

data = {
    "channels": [{"id": r[0], "name": r[1]} for r in rows(
        "SELECT channel_id, channel_name FROM dim_channel ORDER BY 1")],
    "provinces": [{"id": r[0], "name": r[1]} for r in rows(
        "SELECT province_id, province_name FROM dim_province WHERE province_key > 0 ORDER BY 2")],
    "products": [{"id": r[0], "name": r[1]} for r in rows(
        "SELECT product_id, name FROM dim_product ORDER BY 1")],
    # [order_id, dia, canal, provincia (0 = sin dato), total]
    "orders": rows(f"""
        SELECT f.order_id, {DAY}, ch.channel_id, pr.province_id, CAST(f.total_amount AS DOUBLE)
        FROM fact_orders f
        JOIN dim_date d USING (date_key)
        JOIN dim_channel ch USING (channel_key)
        JOIN dim_province pr USING (province_key)
        WHERE f.is_sale ORDER BY 2"""),
    # [order_id, dia, canal, provincia, producto, line_total]
    "items": rows(f"""
        SELECT s.order_id, {DAY}, ch.channel_id, pr.province_id, p.product_id,
               CAST(s.line_total AS DOUBLE)
        FROM fact_sales s
        JOIN dim_date d USING (date_key)
        JOIN dim_channel ch USING (channel_key)
        JOIN dim_province pr USING (province_key)
        JOIN dim_product p USING (product_key)
        WHERE s.is_sale"""),
    # [dia, usuario]  (usuario = customer_id, o -session_id si es anonimo)
    "sessions": rows(f"""
        SELECT DISTINCT {DAY},
               CASE WHEN w.customer_key = -1 THEN -w.session_id ELSE c.customer_id END
        FROM fact_web_session w
        JOIN dim_date d USING (date_key)
        JOIN dim_customer c USING (customer_key)"""),
    # [dia, canal, score]
    "nps": rows(f"""
        SELECT {DAY}, ch.channel_id, n.score
        FROM fact_nps n JOIN dim_date d USING (date_key) JOIN dim_channel ch USING (channel_key)"""),
    # [order_id, dias de despacho a entrega]
    "shipments": rows("""
        SELECT order_id, ROUND(CAST(delivery_days AS DOUBLE), 2)
        FROM fact_shipment WHERE status = 'DELIVERED' AND delivery_days IS NOT NULL"""),
}

path = OUT / "data.json"
path.write_text(json.dumps(data, separators=(",", ":"), ensure_ascii=False), encoding="utf-8")
print(f"OK -> {path} ({path.stat().st_size / 1024:.0f} KB): "
      f"{len(data['orders'])} pedidos, {len(data['items'])} items, "
      f"{len(data['sessions'])} usuarios-dia, {len(data['nps'])} respuestas NPS")
