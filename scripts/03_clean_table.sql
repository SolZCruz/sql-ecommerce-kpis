-- ============================================================
-- 03_clean_table.sql
-- Objetivo: aplicar las reglas de negocio y quedarnos con la tabla
-- final "clean_table", lista para calcular los KPIs.
--
-- DECISIONES DE LIMPIEZA 
--
-- 1) DEDUPLICACIÓN: row_id debería ser único (hay 10000
--    row_id distintos en 10286 filas). Las filas repetidas son el
--    MISMO pedido, a veces con la fecha escrita en el otro formato
--    (ej. '13-02-2024' vs '2024.02.13' = la misma fecha). Por eso
--    deduplicamos después de normalizar (en silver_layer), usando
--    row_id como clave, y nos quedamos con la primera aparición.
--    Para los pocos casos (19) donde el mismo row_id tiene datos
--    realmente distintos (ej. distinto customer_segment), igual
--    nos quedamos con la primera fila — es una decisión simple y
--    reproducible, pero queda documentada por si se quiere revisar
--    manualmente más adelante.
--
-- 2) FILAS SIN order_amount_old: no se puede calcular ingreso ni
--    margen sin ese valor, así que se descartan (regla de negocio
--    explícita: "una fila sin monto de pedido no es una venta válida").
-- ============================================================

DROP TABLE IF EXISTS clean_table;

CREATE TABLE clean_table AS
WITH deduplicated AS (
    SELECT *,
        ROW_NUMBER() OVER (PARTITION BY row_id ORDER BY row_id) AS rn
    FROM silver_layer
)
SELECT
    row_id,
    order_date,
    customer_segment,
    order_amount_old,
    cost,
    is_return,
    payment_method,
    hour_of_day
FROM deduplicated
WHERE rn = 1
  AND order_amount_old IS NOT NULL;

-- ------------------------------------------------------------
-- Chequeos finales antes de pasar a los KPIs
-- ------------------------------------------------------------

SELECT COUNT(*) AS total_rows_clean FROM clean_table;

-- No deberían quedar row_id repetidos
SELECT row_id, COUNT(*)
FROM clean_table
GROUP BY row_id
HAVING COUNT(*) > 1;

-- Distribución final de segmentos (para comparar con la capa silver)
SELECT customer_segment, COUNT(*) AS nbr_segments
FROM clean_table
GROUP BY customer_segment
ORDER BY nbr_segments DESC;
