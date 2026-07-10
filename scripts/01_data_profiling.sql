-- ============================================================
-- 01_data_profiling.sql
-- Objetivo: entender qué tan sucios están los datos antes de
-- limpiarlos.
-- ============================================================

-- 1) Muestra inicial de los datos crudos
SELECT *
FROM raw_ecommerce
LIMIT 20;

-- 2) Conteo de valores nulos/vacíos por columna
--    (En modo CSV, un campo vacío sin comillas se carga como NULL,
--    pero igual chequeamos '' por seguridad)
SELECT
    COUNT(*) AS total_rows,
    SUM(CASE WHEN order_date IS NULL OR order_date = ''        THEN 1 ELSE 0 END) AS null_date,
    SUM(CASE WHEN customer_segment IS NULL OR customer_segment = '' THEN 1 ELSE 0 END) AS null_customer_segment,
    SUM(CASE WHEN order_amount_old IS NULL OR order_amount_old = '' THEN 1 ELSE 0 END) AS null_order_amount_old,
    SUM(CASE WHEN cost IS NULL OR cost = ''                     THEN 1 ELSE 0 END) AS null_cost,
    SUM(CASE WHEN is_return IS NULL OR is_return = ''           THEN 1 ELSE 0 END) AS null_is_return,
    SUM(CASE WHEN payment_method IS NULL OR payment_method = '' THEN 1 ELSE 0 END) AS null_payment_method,
    SUM(CASE WHEN hour_of_day IS NULL OR hour_of_day = ''       THEN 1 ELSE 0 END) AS null_hour_of_day
FROM raw_ecommerce;

-- 3) Distribución de customer_segment
--    Aquí se ven los errores de escritura: "standrad", "premuim", "platnum"
SELECT
    customer_segment,
    COUNT(*) AS nbr_segments
FROM raw_ecommerce
GROUP BY customer_segment
ORDER BY nbr_segments DESC;

-- 4) Distribución de payment_method (chequeo de consistencia)
SELECT
    payment_method,
    COUNT(*) AS nbr_methods
FROM raw_ecommerce
GROUP BY payment_method
ORDER BY nbr_methods DESC;

-- 5) Detección de filas con row_id repetido
--    (pista de duplicados; los confirmamos del todo en la capa silver,
--    porque algunos "duplicados" solo lo son una vez se normaliza la fecha)
SELECT
    row_id,
    COUNT(*) AS apariciones
FROM raw_ecommerce
GROUP BY row_id
HAVING COUNT(*) > 1
ORDER BY apariciones DESC;
