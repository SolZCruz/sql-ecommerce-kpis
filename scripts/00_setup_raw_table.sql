-- ============================================================
-- 00_setup_raw_table.sql
-- Objetivo: crear la tabla "raw" tal cual viene el CSV y cargarla.
--
-- Decisión de diseño: TODAS las columnas se crean como TEXT.
-- ¿Por qué? Porque el CSV tiene fechas en dos formatos distintos
-- y queremos que la carga NUNCA falle por un error de tipo.
-- La conversión a tipos reales (DATE, NUMERIC, INTEGER) se hace
-- después, en 02_silver_layer.sql, donde controlamos el proceso.
-- ============================================================

DROP TABLE IF EXISTS raw_ecommerce;

CREATE TABLE raw_ecommerce (
    row_id              TEXT,
    customer_segment    TEXT,
    order_amount_old    TEXT,
    cost                TEXT,
    is_return           TEXT,
    payment_method      TEXT,
    hour_of_day         TEXT,
    order_date          TEXT   -- en el CSV la columna se llama "date";
                                -- la renombramos porque DATE es palabra reservada
);

-- ------------------------------------------------------------
-- Carga del CSV
-- IMPORTANTE: ajusta la ruta al lugar real donde tengas el archivo
-- en tu máquina. Usa \copy (con barra invertida) si ejecutas esto
-- desde psql y el archivo está en tu equipo local, no en el servidor.
-- Desde la extensión de PostgreSQL en VS Code, COPY normal funciona
-- si el archivo es accesible por el proceso del servidor; si no,
-- usa el comando \copy en la terminal de psql.
-- ------------------------------------------------------------

-- Opción A: ejecutándolo en psql (terminal) -> usa \copy
-- \copy raw_ecommerce FROM 'C:/ruta/a/tu/proyecto/data/C01_l01_ecommerce_retail_data.csv' DELIMITER ',' CSV HEADER;

-- Opción B: COPY estándar (requiere que el archivo esté accesible por el servidor de Postgres)
COPY raw_ecommerce
FROM 'C:/Users/solzh/Documents/SQL Proyectos/Proyecto uno/data/C01_l01_ecommerce_retail_data.csv'
DELIMITER ','
CSV HEADER;

-- Verificación rápida de la carga
SELECT COUNT(*) AS total_rows FROM raw_ecommerce;
SELECT * FROM raw_ecommerce LIMIT 10;
