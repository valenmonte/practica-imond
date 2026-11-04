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
SELECT 
    d.year,
    d.month,
    d.month_name,
    COUNT(f.order_item_id) AS total_items_vendidos,
    SUM(f.line_total) AS ventas_totales
FROM fact_sales f
JOIN dim_date d ON f.date_key = d.date_key
GROUP BY d.year, d.month, d.month_name
ORDER BY d.year, d.month;

#------------------------------------------------------------------------------------------------------------

SELECT 
    c.province,
    COUNT(f.order_item_id) AS total_ventas,
    SUM(f.line_total) AS facturacion_total
FROM fact_sales f
JOIN dim_customer c ON f.customer_key = c.customer_key
GROUP BY c.province
ORDER BY facturacion_total DESC;

#------------------------------------------------------------------------------------------------------------

SELECT 
    AVG(f.line_total) AS ticket_promedio
FROM fact_sales f;

#------------------------------------------------------------------------------------------------------------

SELECT 
    d.year,
    d.month,
    p.name AS product_name,
    SUM(f.line_total) AS facturacion_producto
FROM fact_sales f
JOIN dim_product p ON f.product_key = p.product_key
JOIN dim_date d ON f.date_key = d.date_key
GROUP BY d.year, d.month, p.name
ORDER BY d.year DESC, d.month DESC, facturacion_producto DESC;
