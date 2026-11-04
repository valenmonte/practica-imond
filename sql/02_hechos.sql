-- =====================================================================
-- 02_hechos.sql — Tablas de HECHOS del modelo estrella
-- =====================================================================
-- Este archivo se ejecuta después de 01_dimensiones.sql porque los hechos
-- apuntan a las dimensiones con FOREIGN KEY (REFERENCES).
--
-- Para cada tabla de hechos:
--   1. Definí el GRANO: ¿qué representa UNA fila?
--      (ej.: un producto dentro de un pedido, una sesión web, una respuesta NPS)
--   2. CREATE TABLE con:
--        - PRIMARY KEY
--        - una FOREIGN KEY por cada dimensión:  product_key INTEGER REFERENCES dim_product (product_key)
--        - las métricas (cantidades, importes, puntajes...)
--   3. INSERT INTO ... SELECT uniendo las tablas de origen (raw.) con las dimensiones
--      para obtener las claves.
--
-- Patrón para obtener la clave de una dimensión:
--
--   SELECT i.order_item_id, p.product_key, i.quantity, i.line_total
--   FROM raw.sales_order_item AS i
--   JOIN dim_product AS p ON p.product_id = i.product_id
--
-- Si una FOREIGN KEY apunta a una clave que no existe en la dimensión,
-- DuckDB rechaza la carga y run_sql.py te muestra el error.
-- =====================================================================


-- TU TURNO: creá acá las tablas de hechos.
CREATE OR REPLACE TABLE fact_sales (
    order_item_id BIGINT PRIMARY KEY,
    date_key INT,
    product_key INT,
    customer_key INT,
    store_key INT,
    channel_key INT,
    quantity INT NOT NULL,
    unit_price DECIMAL(12,2) NOT NULL,
    line_total DECIMAL(12,2) NOT NULL
);


#------------------------------------------------------------------------------------------------------------
INSERT INTO fact_sales
SELECT 
    i.order_item_id,
    CAST(strftime(o.order_date, '%Y%m%d') AS INTEGER) AS date_key,
    p.product_key,
    c.customer_key,
    s.store_key,
    ch.channel_key,
    i.quantity,
    i.unit_price,
    i.line_total
FROM raw.sales_order_item AS i
JOIN raw.sales_order AS o ON o.order_id = i.order_id
JOIN dim_product AS p ON p.product_id = i.product_id
LEFT JOIN dim_customer AS c ON c.customer_id = o.customer_id
LEFT JOIN dim_store AS s ON s.store_id = o.store_id
JOIN dim_channel AS ch ON ch.channel_id = i.product_id 
JOIN dim_date AS d ON d.full_date = CAST(o.order_date AS DATE);
