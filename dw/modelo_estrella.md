# Modelo estrella

Generado por `run_sql.py` a partir de las tablas de `warehouse.duckdb`.

```mermaid
erDiagram
    dim_channel ||--o{ fact_nps : "channel_key"
    dim_channel ||--o{ fact_orders : "channel_key"
    dim_channel ||--o{ fact_sales : "channel_key"
    dim_channel ||--o{ fact_shipment : "channel_key"
    dim_customer ||--o{ fact_nps : "customer_key"
    dim_customer ||--o{ fact_orders : "customer_key"
    dim_customer ||--o{ fact_sales : "customer_key"
    dim_customer ||--o{ fact_web_session : "customer_key"
    dim_date ||--o{ fact_nps : "date_key"
    dim_date ||--o{ fact_orders : "date_key"
    dim_date ||--o{ fact_sales : "date_key"
    dim_date ||--o{ fact_shipment : "date_key"
    dim_date ||--o{ fact_web_session : "date_key"
    dim_product ||--o{ fact_sales : "product_key"
    dim_province ||--o{ fact_orders : "province_key"
    dim_province ||--o{ fact_sales : "province_key"
    dim_province ||--o{ fact_shipment : "province_key"
    dim_store ||--o{ fact_orders : "store_key"
    dim_store ||--o{ fact_sales : "store_key"
    fact_orders ||--o{ fact_sales : "order_id"
    fact_orders ||--o{ fact_shipment : "order_id"
    dim_channel {
        INTEGER channel_key PK
        INTEGER channel_id
        VARCHAR channel_code
        VARCHAR channel_name
    }
    dim_customer {
        INTEGER customer_key PK
        INTEGER customer_id
        VARCHAR full_name
        VARCHAR email
        VARCHAR status
        TIMESTAMP created_at
    }
    dim_date {
        INTEGER date_key PK
        DATE full_date
        INTEGER year
        INTEGER month
        VARCHAR month_name
        INTEGER day
        VARCHAR day_name
        INTEGER quarter
        BOOLEAN is_weekend
    }
    dim_product {
        INTEGER product_key PK
        INTEGER product_id
        VARCHAR sku
        VARCHAR name
        VARCHAR category
        VARCHAR family
        DECIMAL list_price
    }
    dim_province {
        INTEGER province_key PK
        INTEGER province_id
        VARCHAR province_name
        VARCHAR province_code
    }
    dim_store {
        INTEGER store_key PK
        INTEGER store_id
        VARCHAR store_name
        VARCHAR city
        VARCHAR province
        VARCHAR store_type
    }
    fact_nps {
        BIGINT nps_id PK
        INTEGER date_key FK
        INTEGER customer_key FK
        INTEGER channel_key FK
        SMALLINT score
        VARCHAR category
    }
    fact_orders {
        BIGINT order_id PK
        INTEGER date_key FK
        INTEGER customer_key FK
        INTEGER channel_key FK
        INTEGER store_key FK
        INTEGER province_key FK
        VARCHAR status
        BOOLEAN is_sale
        DECIMAL subtotal
        DECIMAL tax_amount
        DECIMAL shipping_fee
        DECIMAL total_amount
    }
    fact_sales {
        BIGINT order_item_id PK
        BIGINT order_id FK
        INTEGER date_key FK
        INTEGER product_key FK
        INTEGER customer_key FK
        INTEGER channel_key FK
        INTEGER store_key FK
        INTEGER province_key FK
        BOOLEAN is_sale
        INTEGER quantity
        DECIMAL unit_price
        DECIMAL discount_amount
        DECIMAL line_total
    }
    fact_shipment {
        BIGINT shipment_id PK
        BIGINT order_id FK
        INTEGER date_key FK
        INTEGER province_key FK
        INTEGER channel_key FK
        VARCHAR carrier
        VARCHAR status
        TIMESTAMP shipped_at
        TIMESTAMP delivered_at
        DECIMAL delivery_days
    }
    fact_web_session {
        BIGINT session_id PK
        INTEGER date_key FK
        INTEGER customer_key FK
        VARCHAR source
        VARCHAR device
        DECIMAL duration_minutes
    }
```
