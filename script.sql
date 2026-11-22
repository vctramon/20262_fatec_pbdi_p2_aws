SELECT
    COUNT(*) AS total_linhas,
    SUM(sales) AS total_vendas,
    MIN(order_date) AS primeira_data_pedido,
    MAX(ship_date) AS ultima_data_envio,
    COUNT(*) FILTER (
        WHERE postal_code = 'N/D'
    ) AS codigos_postais_ausentes,
    COUNT(*) FILTER (
        WHERE ship_date < order_date
    ) AS envios_anteriores_pedido
FROM staging.sales;

FROM staging.sales;

-- Enunciado 12
-- Escreva três consultas de verificação sobre a staging e registre os resultados em comentário:

-- 1) Quantos product_id aparecem com mais de um product_name
SELECT COUNT(*) AS qtd_product_id_multiplos_nomes
FROM (
 SELECT product_id
 FROM staging.sales
 GROUP BY product_id
 HAVING COUNT(DISTINCT product_name) > 1
) t;
--Resposta: 32

-- 2) Quantos customer_id aparecem com mais de um customer_name ou mais de um segment
SELECT COUNT(*) AS qtd_customer_id_multiplos_atributos
FROM (
 SELECT customer_id
 FROM staging.sales
 GROUP BY customer_id
 HAVING COUNT(DISTINCT customer_name) > 1
     OR COUNT(DISTINCT segment) > 1
) t;
--Resposta: 0

-- 3) Quantas combinações de cidade, estado e código postal aparecem com mais de uma região
SELECT COUNT(*) AS qtd_localizacoes_multiplas_regioes
FROM (
 SELECT city, state, postal_code
 FROM staging.sales
 GROUP BY city, state, postal_code
 HAVING COUNT(DISTINCT region) > 1
) t;
--Resposta: 0

-- Enunciado 13

-- 1. Dimensão de clientes
CREATE TABLE IF NOT EXISTS dw.dim_customer (
    customer_sk   SERIAL PRIMARY KEY,
    customer_id   VARCHAR(20) NOT NULL UNIQUE,
    customer_name VARCHAR(60) NOT NULL,
    segment       VARCHAR(20) NOT NULL
);

-- 2. Dimensão de produtos
CREATE TABLE IF NOT EXISTS dw.dim_product (
    product_sk   SERIAL PRIMARY KEY,
    product_id   VARCHAR(20) NOT NULL UNIQUE,
    product_name VARCHAR(200) NOT NULL,
    category     VARCHAR(30) NOT NULL,
    sub_category VARCHAR(30) NOT NULL
);

-- 3. Dimensão de localização
CREATE TABLE IF NOT EXISTS dw.dim_location (
    location_sk SERIAL PRIMARY KEY,
    country     VARCHAR(40) NOT NULL,
    state       VARCHAR(40) NOT NULL,
    city        VARCHAR(60) NOT NULL,
    postal_code VARCHAR(10) NOT NULL,
    region      VARCHAR(20) NOT NULL,
    CONSTRAINT uq_dim_location_natural
        UNIQUE (country, state, city, postal_code)
);

-- 4. Dimensão de modalidade de envio
CREATE TABLE IF NOT EXISTS dw.dim_ship_mode (
    ship_mode_sk SERIAL PRIMARY KEY,
    ship_mode    VARCHAR(20) NOT NULL UNIQUE
);

-- 5. Tabela fato de vendas
CREATE TABLE IF NOT EXISTS dw.fact_sales (
    sale_sk       SERIAL PRIMARY KEY,
    row_nk        INTEGER NOT NULL UNIQUE,
    order_nk      VARCHAR(20) NOT NULL,
    order_date_sk INTEGER NOT NULL
        REFERENCES dw.dim_date(date_sk),
    ship_date_sk  INTEGER NOT NULL
        REFERENCES dw.dim_date(date_sk),
    customer_sk   INTEGER NOT NULL
        REFERENCES dw.dim_customer(customer_sk),
    product_sk    INTEGER NOT NULL
        REFERENCES dw.dim_product(product_sk),
    location_sk   INTEGER NOT NULL
        REFERENCES dw.dim_location(location_sk),
    ship_mode_sk  INTEGER NOT NULL
        REFERENCES dw.dim_ship_mode(ship_mode_sk),
    sales         NUMERIC(12,2) NOT NULL,
    ship_days     INTEGER NOT NULL
);

-- Enunciado 13
CREATE TABLE IF NOT EXISTS dw.dim_customer (
    customer_sk   SERIAL PRIMARY KEY,
    customer_id   VARCHAR(20) NOT NULL UNIQUE,
    customer_name VARCHAR(60) NOT NULL,
    segment       VARCHAR(20) NOT NULL
);
 
CREATE TABLE IF NOT EXISTS dw.dim_product (
    product_sk   SERIAL PRIMARY KEY,
    product_id   VARCHAR(20) NOT NULL UNIQUE,
    product_name VARCHAR(200) NOT NULL,
    category     VARCHAR(30) NOT NULL,
    sub_category VARCHAR(30) NOT NULL
);
 

CREATE TABLE IF NOT EXISTS dw.dim_location (
    location_sk SERIAL PRIMARY KEY,
    country     VARCHAR(40) NOT NULL,
    state       VARCHAR(40) NOT NULL,
    city        VARCHAR(60) NOT NULL,
    postal_code VARCHAR(10) NOT NULL,
    region      VARCHAR(20) NOT NULL,
    CONSTRAINT uq_dim_location_natural
        UNIQUE (country, state, city, postal_code)
);
 

CREATE TABLE IF NOT EXISTS dw.dim_ship_mode (
    ship_mode_sk SERIAL PRIMARY KEY,
    ship_mode    VARCHAR(20) NOT NULL UNIQUE
);
 

CREATE TABLE IF NOT EXISTS dw.fact_sales (
    sale_sk       SERIAL PRIMARY KEY,
    row_nk        INTEGER NOT NULL UNIQUE,
    order_nk      VARCHAR(20) NOT NULL,
    order_date_sk INTEGER NOT NULL
        REFERENCES dw.dim_date(date_sk),
    ship_date_sk  INTEGER NOT NULL
        REFERENCES dw.dim_date(date_sk),
    customer_sk   INTEGER NOT NULL
        REFERENCES dw.dim_customer(customer_sk),
    product_sk    INTEGER NOT NULL
        REFERENCES dw.dim_product(product_sk),
    location_sk   INTEGER NOT NULL
        REFERENCES dw.dim_location(location_sk),
    ship_mode_sk  INTEGER NOT NULL
        REFERENCES dw.dim_ship_mode(ship_mode_sk),
    sales         NUMERIC(12,2) NOT NULL,
    ship_days     INTEGER NOT NULL
);
 

CREATE INDEX IF NOT EXISTS idx_fact_order_date_sk
    ON dw.fact_sales(order_date_sk);
 
CREATE INDEX IF NOT EXISTS idx_fact_ship_date_sk
    ON dw.fact_sales(ship_date_sk);
 
CREATE INDEX IF NOT EXISTS idx_fact_customer_sk
    ON dw.fact_sales(customer_sk);
 
CREATE INDEX IF NOT EXISTS idx_fact_product_sk
    ON dw.fact_sales(product_sk);
 
CREATE INDEX IF NOT EXISTS idx_fact_location_sk
    ON dw.fact_sales(location_sk);
 
CREATE INDEX IF NOT EXISTS idx_fact_ship_mode_sk
    ON dw.fact_sales(ship_mode_sk);