## Dashboard (GitHub Pages)

Tablero comercial de EcoBottle AR, publicado en https://valenmonte.github.io/practica-imond/

Muestra ventas, usuarios activos, ticket promedio, NPS, ventas por provincia y ranking mensual por producto, con filtros de fecha, canal, provincia y producto. También sigue las dos metas del trimestre: crecer 15% las ventas en Córdoba y reducir los tiempos de entrega en Mendoza.

### Cómo regenerarlo

```
python run_sql.py          # arma el data warehouse (dw/)
python build_dashboard.py  # genera web/data.json
python -m http.server      # abrir http://localhost:8000
```

`index.html` es una página estática (Chart.js desde CDN) que lee `web/data.json`. No necesita servidor ni base de datos, por eso funciona en GitHub Pages.

### Definiciones de los KPI

| KPI | Cálculo |
|---|---|
| Total de ventas | `SUM(total_amount)` de `sales_order` con `status IN ('PAID','FULFILLED')` |
| Usuarios activos | usuarios distintos en `web_session` (`customer_id`, o la sesión si es anónima) |
| Ticket promedio | `SUM(total_amount) / COUNT(*)` de los pedidos que cuentan como venta |
| NPS | `(%9-10 − %0-6) × 100` sobre `nps_response` |
| Ventas por provincia | `total_amount` agrupado por `shipping_address_id → address.province_id` |
| Ranking por producto | `line_total` agrupado por producto y mes de `order_date` |
| Meta Córdoba | ventas de los últimos 92 días vs. los 92 anteriores |
| Entrega | días entre `shipped_at` y `delivered_at` de envíos `DELIVERED`, por provincia |

### Supuestos

- Con un producto seleccionado, ventas y ticket se calculan sobre sus ítems (`line_total`, sin IVA ni envío).
- Los usuarios activos solo responden al filtro de fechas (`web_session` no tiene canal, provincia ni producto). El NPS responde a fechas y canal.
- En compras en tienda, la provincia es la de la tienda (su dirección es la de envío).
- Los pedidos sin dirección de envío figuran como "Sin dato".
