-- =====================================================================
-- 01_dimensiones.sql — Tablas de DIMENSIONES del modelo estrella
-- =====================================================================
-- Para cada dimensión:
--   1. CREATE TABLE con sus columnas, tipos y PRIMARY KEY.
--   2. INSERT INTO ... SELECT para cargarla desde las tablas de origen.
--
-- Las tablas de origen (los CSV de raw/) están en el esquema raw:
--     FROM raw.product
-- Para ver qué columnas y tipos tiene una:  DESCRIBE raw.product;
-- Para explorarlas antes de escribir nada:  python run_sql.py --explorar
-- =====================================================================


-- ---------------------------------------------------------------------
-- EJEMPLO RESUELTO: dimensión producto
-- ---------------------------------------------------------------------
-- En raw/ la categoría está en otra tabla y tiene jerarquía
-- (Bottles -> Classic / Sport). En la dimensión la "aplanamos":
-- cada producto queda en una sola fila con su categoría y su familia.
--
-- product_key es la clave SUBROGADA: un número propio del data warehouse.
-- product_id es la clave NATURAL: el ID que viene del sistema de origen.
-- Las tablas de hechos usan product_key; product_id sirve para encontrarla.

CREATE TABLE dim_product (
    product_key INTEGER PRIMARY KEY,
    product_id  INTEGER NOT NULL,
    sku         VARCHAR NOT NULL,
    name        VARCHAR NOT NULL,
    category    VARCHAR,             -- Classic / Sport
    family      VARCHAR,             -- Bottles
    list_price  DECIMAL(12, 2)
);

INSERT INTO dim_product
SELECT
    ROW_NUMBER() OVER (ORDER BY p.product_id) AS product_key,
    p.product_id,
    p.sku,
    p.name,
    c.name AS category,
    f.name AS family,
    p.list_price
FROM raw.product AS p
LEFT JOIN raw.product_category AS c ON c.category_id = p.category_id   -- categoría
LEFT JOIN raw.product_category AS f ON f.category_id = c.parent_id;    -- familia (categoría padre)



-- ---------------------------------------------------------------------
-- TU TURNO: el resto de las dimensiones
-- ---------------------------------------------------------------------
-- Pensá qué preguntas tiene que responder el dashboard (por fecha, canal,
-- provincia, producto, cliente, tienda...) y creá una dimensión para cada una.
--
-- Tips:
--   * Generar todas las fechas entre dos días:
--       SELECT CAST(range AS DATE) AS fecha
--       FROM range(DATE '2024-01-01', DATE '2025-10-01', INTERVAL 1 DAY);
--   * Partes de una fecha: year(fecha), month(fecha), monthname(fecha), dayname(fecha)
--   * Clave numérica para una fecha (ej. 20240131):
--       CAST(strftime(fecha, '%Y%m%d') AS INTEGER)
--   * Si algo puede venir vacío (ej. NPS anónimos, sin cliente), podés agregar
--     una fila "Desconocido" con clave -1 y usar COALESCE(clave, -1) en los hechos.


-- ---------------------------------------------------------------------
CREATE TABLE dim_date (
    date_key   INTEGER PRIMARY KEY,   
    full_date  DATE NOT NULL,
    year       INTEGER NOT NULL,
    month      INTEGER NOT NULL,
    month_name VARCHAR NOT NULL,
    day        INTEGER NOT NULL,
    day_name   VARCHAR NOT NULL,
    quarter    INTEGER NOT NULL,
    is_weekend BOOLEAN NOT NULL
);

INSERT INTO dim_date
SELECT
    CAST(strftime(fecha, '%Y%m%d') AS INTEGER),
    fecha,
    year(fecha),
    month(fecha),
    monthname(fecha),
    day(fecha),
    dayname(fecha),
    quarter(fecha),
    dayname(fecha) IN ('Saturday', 'Sunday')
FROM (SELECT CAST(range AS DATE) AS fecha
      FROM range(DATE '2024-01-01', DATE '2025-10-01', INTERVAL 1 DAY));

-- ---------------------------------------------------------------------
-- dim_province
-- ---------------------------------------------------------------------
CREATE TABLE dim_province (
    province_key  INTEGER PRIMARY KEY,
    province_id   INTEGER NOT NULL,
    province_name VARCHAR NOT NULL,
    province_code VARCHAR
);

INSERT INTO dim_province
SELECT ROW_NUMBER() OVER (ORDER BY province_id), province_id, name, code
FROM raw.province;

INSERT INTO dim_province VALUES (-1, 0, 'Sin dato', NULL);

-- ---------------------------------------------------------------------

CREATE TABLE dim_customer (
    customer_key INTEGER PRIMARY KEY,
    customer_id  INTEGER NOT NULL,
    full_name    VARCHAR NOT NULL,
    email        VARCHAR,
    status       CHAR(1),          
    created_at   TIMESTAMP
);

INSERT INTO dim_customer
SELECT
    ROW_NUMBER() OVER (ORDER BY c.customer_id),
    c.customer_id,
    c.first_name || ' ' || c.last_name,
    c.email,
    c.status,
    c.created_at
FROM raw.customer AS c;

INSERT INTO dim_customer VALUES (-1, -1, 'Desconocido', NULL, NULL, NULL);


-- ---------------------------------------------------------------------
CREATE TABLE dim_store (
    store_key  INTEGER PRIMARY KEY,
    store_id   INTEGER NOT NULL,
    store_name VARCHAR NOT NULL,
    city       VARCHAR,
    province   VARCHAR,
    store_type VARCHAR
);

INSERT INTO dim_store
SELECT
    ROW_NUMBER() OVER (ORDER BY s.store_id),
    s.store_id,
    s.name,
    a.city,
    pr.name,
    'Física'
FROM raw.store AS s
LEFT JOIN raw.address  AS a  ON a.address_id = s.address_id
LEFT JOIN raw.province AS pr ON pr.province_id = a.province_id;

INSERT INTO dim_store VALUES (-1, -1, 'Online (sin tienda)', NULL, NULL, 'Online');


-- ---------------------------------------------------------------------
CREATE TABLE dim_channel (
    channel_key  INTEGER PRIMARY KEY,
    channel_id   INTEGER NOT NULL,
    channel_code VARCHAR NOT NULL,   
    channel_name VARCHAR NOT NULL
);

INSERT INTO dim_channel
SELECT ROW_NUMBER() OVER (ORDER BY channel_id), channel_id, code, name
FROM raw.channel;