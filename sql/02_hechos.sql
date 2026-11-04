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

CREATE TABLE fact_orders (
    order_id     BIGINT PRIMARY KEY,
    date_key     INTEGER NOT NULL REFERENCES dim_date (date_key),
    customer_key INTEGER NOT NULL REFERENCES dim_customer (customer_key),
    channel_key  INTEGER NOT NULL REFERENCES dim_channel (channel_key),
    store_key    INTEGER NOT NULL REFERENCES dim_store (store_key),
    province_key INTEGER NOT NULL REFERENCES dim_province (province_key),  
    status       VARCHAR NOT NULL,
    is_sale      BOOLEAN NOT NULL,
    subtotal     DECIMAL(12, 2) NOT NULL,
    tax_amount   DECIMAL(12, 2) NOT NULL,
    shipping_fee DECIMAL(12, 2) NOT NULL,
    total_amount DECIMAL(12, 2) NOT NULL
);

INSERT INTO fact_orders
SELECT
    o.order_id,
    CAST(strftime(o.order_date, '%Y%m%d') AS INTEGER),
    COALESCE(c.customer_key, -1),
    ch.channel_key,
    COALESCE(s.store_key, -1),
    COALESCE(pr.province_key, -1),
    o.status,
    o.status IN ('PAID', 'FULFILLED'),
    o.subtotal,
    o.tax_amount,
    o.shipping_fee,
    o.total_amount
FROM raw.sales_order AS o
JOIN dim_channel AS ch ON ch.channel_id = o.channel_id
LEFT JOIN dim_customer AS c ON c.customer_id = o.customer_id
LEFT JOIN dim_store AS s ON s.store_id = o.store_id
LEFT JOIN raw.address AS a ON a.address_id = o.shipping_address_id
LEFT JOIN dim_province AS pr ON pr.province_id = a.province_id;


-- ---------------------------------------------------------------------
CREATE TABLE fact_sales (
    order_item_id   BIGINT PRIMARY KEY,
    order_id        BIGINT NOT NULL REFERENCES fact_orders (order_id),
    date_key        INTEGER NOT NULL REFERENCES dim_date (date_key),
    product_key     INTEGER NOT NULL REFERENCES dim_product (product_key),
    customer_key    INTEGER NOT NULL REFERENCES dim_customer (customer_key),
    channel_key     INTEGER NOT NULL REFERENCES dim_channel (channel_key),
    store_key       INTEGER NOT NULL REFERENCES dim_store (store_key),
    province_key    INTEGER NOT NULL REFERENCES dim_province (province_key),
    is_sale         BOOLEAN NOT NULL,
    quantity        INTEGER NOT NULL,
    unit_price      DECIMAL(12, 2) NOT NULL,
    discount_amount DECIMAL(12, 2) NOT NULL,
    line_total      DECIMAL(12, 2) NOT NULL
);

INSERT INTO fact_sales
SELECT
    i.order_item_id,
    f.order_id,
    f.date_key,
    p.product_key,
    f.customer_key,
    f.channel_key,
    f.store_key,
    f.province_key,
    f.is_sale,
    i.quantity,
    i.unit_price,
    i.discount_amount,
    i.line_total
FROM raw.sales_order_item AS i
JOIN fact_orders AS f ON f.order_id = i.order_id
JOIN dim_product AS p ON p.product_id = i.product_id;


-- ---------------------------------------------------------------------
CREATE TABLE fact_web_session (
    session_id       BIGINT PRIMARY KEY,
    date_key         INTEGER NOT NULL REFERENCES dim_date (date_key),
    customer_key     INTEGER NOT NULL REFERENCES dim_customer (customer_key),
    source           VARCHAR,
    device           VARCHAR,
    duration_minutes DECIMAL(10, 2)
);

INSERT INTO fact_web_session
SELECT
    w.session_id,
    CAST(strftime(w.started_at, '%Y%m%d') AS INTEGER),
    COALESCE(c.customer_key, -1),
    w.source,
    w.device,
    date_diff('second', w.started_at, w.ended_at) / 60.0
FROM raw.web_session AS w
LEFT JOIN dim_customer AS c ON c.customer_id = w.customer_id;


-- ---------------------------------------------------------------------
CREATE TABLE fact_nps (
    nps_id       BIGINT PRIMARY KEY,
    date_key     INTEGER NOT NULL REFERENCES dim_date (date_key),
    customer_key INTEGER NOT NULL REFERENCES dim_customer (customer_key),
    channel_key  INTEGER NOT NULL REFERENCES dim_channel (channel_key),
    score        SMALLINT NOT NULL,
    category     VARCHAR NOT NULL    
);

INSERT INTO fact_nps
SELECT
    n.nps_id,
    CAST(strftime(n.responded_at, '%Y%m%d') AS INTEGER),
    COALESCE(c.customer_key, -1),
    ch.channel_key,
    n.score,
    CASE WHEN n.score >= 9 THEN 'Promotor' WHEN n.score >= 7 THEN 'Pasivo' ELSE 'Detractor' END
FROM raw.nps_response AS n
JOIN dim_channel AS ch ON ch.channel_id = n.channel_id
LEFT JOIN dim_customer AS c ON c.customer_id = n.customer_id;

-- ---------------------------------------------------------------------
CREATE TABLE fact_shipment (
    shipment_id   BIGINT PRIMARY KEY,
    order_id      BIGINT NOT NULL REFERENCES fact_orders (order_id),
    date_key      INTEGER NOT NULL REFERENCES dim_date (date_key),   
    province_key  INTEGER NOT NULL REFERENCES dim_province (province_key),
    channel_key   INTEGER NOT NULL REFERENCES dim_channel (channel_key),
    carrier       VARCHAR,
    status        VARCHAR NOT NULL,
    shipped_at    TIMESTAMP,
    delivered_at  TIMESTAMP,
    delivery_days DECIMAL(10, 2)   
);

INSERT INTO fact_shipment
SELECT
    s.shipment_id,
    s.order_id,
    f.date_key,
    f.province_key,
    f.channel_key,
    s.carrier,
    s.status,
    s.shipped_at,
    s.delivered_at,
    date_diff('second', s.shipped_at, s.delivered_at) / 86400.0
FROM raw.shipment AS s
JOIN fact_orders AS f ON f.order_id = s.order_id;

