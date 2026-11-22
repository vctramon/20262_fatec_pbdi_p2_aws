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

-- Enunciado 14
CREATE OR REPLACE PROCEDURE dw.carrega_dw()
LANGUAGE plpgsql
AS $$
DECLARE
    v_inseridos BIGINT;
    v_fato BIGINT;
    v_staging BIGINT;
BEGIN

    TRUNCATE TABLE
        dw.fact_sales,
        dw.dim_customer,
        dw.dim_product,
        dw.dim_location,
        dw.dim_ship_mode
    RESTART IDENTITY;
 
 
    INSERT INTO dw.dim_customer (
        customer_id, customer_name, segment
    )
    SELECT
        customer_id,
        MIN(customer_name),
        MIN(segment)
    FROM staging.sales
    GROUP BY customer_id
    ORDER BY customer_id;
 
    GET DIAGNOSTICS v_inseridos = ROW_COUNT;
    RAISE NOTICE 'dim_customer: % linhas', v_inseridos;
 
    INSERT INTO dw.dim_product (
        product_id, product_name, category, sub_category
    )
    SELECT
        product_id,
        MIN(product_name),
        MIN(category),
        MIN(sub_category)
    FROM staging.sales
    GROUP BY product_id
    ORDER BY product_id;
 
    GET DIAGNOSTICS v_inseridos = ROW_COUNT;
    RAISE NOTICE 'dim_product: % linhas', v_inseridos;
 
    INSERT INTO dw.dim_location (
        country, state, city, postal_code, region
    )
    SELECT
        country,
        state,
        city,
        postal_code,
        MIN(region)
    FROM staging.sales
    GROUP BY country, state, city, postal_code
    ORDER BY country, state, city, postal_code;
 
    GET DIAGNOSTICS v_inseridos = ROW_COUNT;
    RAISE NOTICE 'dim_location: % linhas', v_inseridos;

    INSERT INTO dw.dim_ship_mode (ship_mode)
    SELECT DISTINCT ship_mode
    FROM staging.sales
    ORDER BY ship_mode;
 
    GET DIAGNOSTICS v_inseridos = ROW_COUNT;
    RAISE NOTICE 'dim_ship_mode: % linhas', v_inseridos;
 
    INSERT INTO dw.fact_sales (
        row_nk, order_nk,
        order_date_sk, ship_date_sk,
        customer_sk, product_sk,
        location_sk, ship_mode_sk,
        sales, ship_days
    )
    SELECT
        s.row_id,
        s.order_id,
        TO_CHAR(s.order_date, 'YYYYMMDD')::INTEGER,
        TO_CHAR(s.ship_date, 'YYYYMMDD')::INTEGER,
        c.customer_sk,
        p.product_sk,
        l.location_sk,
        m.ship_mode_sk,
        s.sales,
        s.ship_date - s.order_date
    FROM staging.sales s
    JOIN dw.dim_customer c
        ON c.customer_id = s.customer_id
    JOIN dw.dim_product p
        ON p.product_id = s.product_id
    JOIN dw.dim_location l
        ON l.country = s.country
        AND l.state = s.state
        AND l.city = s.city
        AND l.postal_code = s.postal_code
    JOIN dw.dim_ship_mode m
        ON m.ship_mode = s.ship_mode
    ORDER BY s.row_id;
 
    GET DIAGNOSTICS v_inseridos = ROW_COUNT;
    RAISE NOTICE 'fact_sales: % linhas', v_inseridos;
 
    SELECT COUNT(*) INTO v_fato
    FROM dw.fact_sales;
 
    SELECT COUNT(*) INTO v_staging
    FROM staging.sales;
 
    IF v_fato <> v_staging THEN
        RAISE EXCEPTION
            'Divergência: fato=%; staging=%',
            v_fato, v_staging;
    END IF;
 
    RAISE NOTICE
        'Carga validada: fato=% e staging=%',
        v_fato, v_staging;
END;
$$;

-- Resposta do Enunciado 14
-- tabela     | linhas 
-- ---------------+--------
-- dim_customer  |    793
-- dim_product   |   1861
-- dim_location  |    628
-- dim_ship_mode |      4
-- fact_sales    |   9800
-- (5 rows)

-- ENUNCIADO 15
CREATE TABLE IF NOT EXISTS dw.carga_log (
    log_id SERIAL PRIMARY KEY,
    sale_sk INTEGER NOT NULL,
    row_nk INTEGER NOT NULL,
    operacao VARCHAR(10) NOT NULL,
    usuario VARCHAR(100) NOT NULL,
    momento TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE OR REPLACE FUNCTION dw.audita_fact_sales()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.sales <= 0 THEN
        RAISE EXCEPTION
            'row_nk %: sales deve ser maior que zero (valor=%)',
            NEW.row_nk, NEW.sales;
    END IF;

    IF NEW.ship_days < 0 THEN
        RAISE EXCEPTION
            'row_nk %: ship_days nao pode ser negativo (dias=%)',
            NEW.row_nk, NEW.ship_days;
    END IF;

    INSERT INTO dw.carga_log (
        sale_sk, row_nk, operacao, usuario, momento
    )
    VALUES (
        NEW.sale_sk, NEW.row_nk, TG_OP,
        CURRENT_USER, CLOCK_TIMESTAMP()
    );

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_audita_fact_sales
ON dw.fact_sales;

CREATE TRIGGER trg_audita_fact_sales
BEFORE INSERT ON dw.fact_sales
FOR EACH ROW
EXECUTE FUNCTION dw.audita_fact_sales();

INSERT INTO dw.fact_sales (
    row_nk, order_nk, order_date_sk, ship_date_sk,
    customer_sk, product_sk, location_sk, ship_mode_sk,
    sales, ship_days
)
SELECT
    -1, 'TESTE-TRIGGER',
    order_date_sk, ship_date_sk,
    customer_sk, product_sk,
    location_sk, ship_mode_sk,
    sales, ship_days
FROM dw.fact_sales
WHERE sales > 0
  AND ship_days >= 0
  AND NOT EXISTS (
      SELECT 1
      FROM dw.fact_sales
      WHERE row_nk = -1
  )
ORDER BY sale_sk
LIMIT 1;

SELECT COUNT(*) AS testes_validos_registrados
FROM dw.carga_log
WHERE row_nk = -1;

-- Teste de inválido
INSERT INTO dw.fact_sales (
    row_nk, order_nk, order_date_sk, ship_date_sk,
    customer_sk, product_sk, location_sk, ship_mode_sk,
    sales, ship_days
)
SELECT
    -2,
    'TESTE-INVALIDO',
    order_date_sk,
    ship_date_sk,
    customer_sk,
    product_sk,
    location_sk,
    ship_mode_sk,
    -1.00,
    ship_days
FROM dw.fact_sales
ORDER BY sale_sk
LIMIT 1;
-- ERROR: row_nk -2: sales deve ser maior que zero (valor=-1.00)

TRUNCATE TABLE dw.carga_log RESTART IDENTITY;

CALL dw.carrega_dw();

SELECT
    (SELECT COUNT(*) FROM dw.fact_sales) AS linhas_fato,
    (SELECT COUNT(*) FROM dw.carga_log) AS linhas_log,
    CASE
        WHEN (SELECT COUNT(*) FROM dw.fact_sales) =
             (SELECT COUNT(*) FROM dw.carga_log)
        THEN 'OK'
        ELSE 'DIVERGENTE'
    END AS auditoria;

