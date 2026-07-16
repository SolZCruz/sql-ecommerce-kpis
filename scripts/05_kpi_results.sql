-- ============================================================
-- 05_kpi_results.sql
-- Junta los 10 KPIs en una sola tabla final: kpi_results
-- Esquema final: kpi_name | kpi_value | kpi_key
-- ============================================================

DROP TABLE IF EXISTS kpi_results;

CREATE TABLE kpi_results AS
SELECT * FROM kpi_1
UNION ALL SELECT * FROM kpi_2
UNION ALL SELECT * FROM kpi_3
UNION ALL SELECT * FROM kpi_4
UNION ALL SELECT * FROM kpi_5
UNION ALL SELECT * FROM kpi_6
UNION ALL SELECT * FROM kpi_7
UNION ALL SELECT * FROM kpi_8
UNION ALL SELECT * FROM kpi_9
UNION ALL SELECT * FROM kpi_10;


-- Agregar columna numérica
ALTER TABLE kpi_results
ADD COLUMN kpi_value_num NUMERIC;

-- Llenar la columna numérica donde el valor sea convertible a número
UPDATE kpi_results
SET kpi_value_num = kpi_value::NUMERIC
WHERE kpi_name NOT IN ('kpi_8');

-- Resultado final
SELECT * FROM kpi_results
ORDER BY kpi_name, kpi_key;