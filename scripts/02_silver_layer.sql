-- ============================================================
-- 02_silver_layer.sql
--
-- Objetivo:
--   - Convertir fechas (texto, 2 formatos mezclados) a tipo DATE real
--   - Convertir columnas numéricas de TEXT a NUMERIC/INTEGER
--   - Normalizar errores de escritura en customer_segment
--   - Validar is_return (debe ser 0 o 1)
-- ============================================================

DROP TABLE IF EXISTS silver_layer;

CREATE TABLE silver_layer AS
SELECT
    row_id::INTEGER                       AS row_id,

    -- Fecha: dos formatos posibles en el CSV original
    --   'YYYY.MM.DD'  ej. 2024.12.05
    --   'DD-MM-YYYY'  ej. 29-06-2024
    CASE
        WHEN order_date ~ '^\d{4}\.\d{2}\.\d{2}$'
            THEN TO_DATE(order_date, 'YYYY.MM.DD')
        WHEN order_date ~ '^\d{2}-\d{2}-\d{4}$'
            THEN TO_DATE(order_date, 'DD-MM-YYYY')
        ELSE NULL
    END                                     AS order_date,

    -- Categoría normalizada: minúsculas, sin espacios, typos corregidos
    CASE
        WHEN customer_segment IS NULL THEN NULL
        WHEN regexp_replace(LOWER(TRIM(customer_segment)), '[^a-z]', '', 'g') = 'standrad' THEN 'standard'
        WHEN regexp_replace(LOWER(TRIM(customer_segment)), '[^a-z]', '', 'g') = 'premuim'  THEN 'premium'
        WHEN regexp_replace(LOWER(TRIM(customer_segment)), '[^a-z]', '', 'g') = 'platnum'  THEN 'platinum'
        ELSE LOWER(TRIM(customer_segment))
    END                                     AS customer_segment,

    order_amount_old::NUMERIC               AS order_amount_old,
    cost::NUMERIC                           AS cost,

    -- is_return válido solo si es 0 o 1; si no, lo dejamos en NULL
    CASE
        WHEN is_return::INTEGER IN (0, 1) THEN is_return::INTEGER
        ELSE NULL
    END                                     AS is_return,

    LOWER(TRIM(payment_method))             AS payment_method,
    hour_of_day::INTEGER                    AS hour_of_day

FROM raw_ecommerce;

-- ------------------------------------------------------------
-- Chequeos de salud de la capa silver
-- ------------------------------------------------------------

-- ¿Cuántas fechas no se pudieron parsear?
SELECT
    COUNT(*) AS total_rows,
    SUM(CASE WHEN order_date IS NULL THEN 1 ELSE 0 END) AS date_parse_failures
FROM silver_layer;

-- Distribución normalizada de customer_segment (ya sin typos)
SELECT
    customer_segment,
    COUNT(*) AS nbr_segments
FROM silver_layer
GROUP BY customer_segment
ORDER BY nbr_segments DESC;

-- Muestra visual de la capa silver
SELECT *
FROM silver_layer
LIMIT 10;
