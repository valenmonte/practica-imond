-- =====================================================================
-- 03_consultas.sql — Consultas para revisar el modelo y calcular KPIs
-- =====================================================================
-- Cada SELECT de este archivo se muestra en la terminal al ejecutar
-- run_sql.py. Usalo para:
--   * comprobar que las tablas se cargaron bien (cantidad de filas, nulos...)
--   * escribir las consultas clave de los KPIs que pide la consigna
--     (ventas, usuarios activos, ticket promedio, NPS, ventas por provincia,
--     ranking mensual por producto) usando las tablas del modelo estrella.
-- =====================================================================


-- Ejemplo: revisar la dimensión producto
SELECT product_key, name, category, family, list_price
FROM dim_product
ORDER BY product_key;


-- TU TURNO: agregá acá tus consultas.

SELECT 'fact_orders' AS tabla, COUNT(*) AS filas FROM fact_orders
UNION ALL SELECT 'fact_sales', COUNT(*) FROM fact_sales
UNION ALL SELECT 'fact_web_session', COUNT(*) FROM fact_web_session
UNION ALL SELECT 'fact_nps', COUNT(*) FROM fact_nps
UNION ALL SELECT 'fact_shipment', COUNT(*) FROM fact_shipment;


SELECT (SELECT SUM(subtotal) FROM fact_orders) - (SELECT SUM(line_total) FROM fact_sales) AS diferencia;


SELECT d.year, d.month, SUM(f.total_amount) AS ventas
FROM fact_orders f JOIN dim_date d USING (date_key)
WHERE f.is_sale
GROUP BY d.year, d.month
ORDER BY d.year, d.month;

SELECT d.year, d.month,
       COUNT(DISTINCT CASE WHEN w.customer_key = -1 THEN -w.session_id ELSE w.customer_key END) AS usuarios_activos
FROM fact_web_session w JOIN dim_date d USING (date_key)
GROUP BY d.year, d.month
ORDER BY d.year, d.month;


SELECT ch.channel_name, SUM(f.total_amount) / COUNT(*) AS ticket_promedio
FROM fact_orders f JOIN dim_channel ch USING (channel_key)
WHERE f.is_sale
GROUP BY ch.channel_name;


SELECT d.year, d.month, ch.channel_name,
       ROUND(100.0 * (AVG((score >= 9)::INT) - AVG((score <= 6)::INT)), 1) AS nps,
       COUNT(*) AS respuestas
FROM fact_nps n JOIN dim_date d USING (date_key) JOIN dim_channel ch USING (channel_key)
GROUP BY d.year, d.month, ch.channel_name
ORDER BY d.year, d.month, ch.channel_name;


SELECT pr.province_name, SUM(f.total_amount) AS ventas,
       ROUND(100.0 * SUM(f.total_amount) / SUM(SUM(f.total_amount)) OVER (), 1) AS pct
FROM fact_orders f JOIN dim_province pr USING (province_key)
WHERE f.is_sale
GROUP BY pr.province_name
ORDER BY ventas DESC;


SELECT d.year, d.month, p.name AS producto, SUM(s.line_total) AS ventas,
       RANK() OVER (PARTITION BY d.year, d.month ORDER BY SUM(s.line_total) DESC) AS ranking
FROM fact_sales s JOIN dim_product p USING (product_key) JOIN dim_date d USING (date_key)
WHERE s.is_sale
GROUP BY d.year, d.month, p.name
ORDER BY d.year DESC, d.month DESC, ranking;


SELECT pr.province_name, ROUND(AVG(sh.delivery_days), 2) AS dias_entrega
FROM fact_shipment sh JOIN dim_province pr USING (province_key)
WHERE sh.status = 'DELIVERED'
GROUP BY pr.province_name
ORDER BY dias_entrega DESC;