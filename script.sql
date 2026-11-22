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

-- Resposta do Enunciado 15
-- linhas_fato | linhas_log | auditoria 
-------------+------------+-----------
--    9800    |    9800    |      OK
--(1 row)

-- Enunciado 16
-- Mostre, para cada região e categoria, a quantidade de pedidos distintos, a quantidade de itens
-- vendidos e a receita, da maior para a menor receita.
SELECT

 dl.region,

 dp.category,

 COUNT(DISTINCT fs.order_nk) AS pedidos_distintos,

 COUNT(*) AS itens_vendidos,

 SUM(fs.sales) AS receita

FROM dw.fact_sales fs

JOIN dw.dim_location dl

 ON dl.location_sk = fs.location_sk

JOIN dw.dim_product dp

 ON dp.product_sk = fs.product_sk

GROUP BY

 dl.region,

 dp.category

ORDER BY

 receita DESC;
 
 -- resposta
 superstore_dw->  receita DESC;
region  |    category     | pedidos_distintos | itens_vendidos |  receita  
---------+-----------------+-------------------+----------------+-----------
East    | Technology      |               436 |            527 | 263116.59
West    | Technology      |               483 |            589 | 247404.95
West    | Furniture       |               582 |            691 | 245348.36
West    | Office Supplies |              1150 |           1860 | 217466.46
East    | Furniture       |               480 |            591 | 206461.36
East    | Office Supplies |              1048 |           1667 | 199940.90
Central | Technology      |               348 |            408 | 168739.19
Central | Office Supplies |               865 |           1399 | 163590.15
Central | Furniture       |               393 |            470 | 160317.56
South   | Technology      |               252 |            289 | 148195.21
South   | Office Supplies |               613 |            983 | 124424.77
South   | Furniture       |               272 |            326 | 116531.47
(12 rows)

-- Enunciado 17
-- Mostre, para cada modalidade de envio, a quantidade de itens, a média de ship_days
-- arredondada para uma casa decimal e o menor e o maior valor de ship_days, da menor
-- para a maior média.
SELECT
 dsm.ship_mode,
 COUNT(*) AS quantidade_itens,
 ROUND(AVG(fs.ship_days)::NUMERIC, 1) AS media_ship_days,
 MIN(fs.ship_days) AS menor_ship_days,
 MAX(fs.ship_days) AS maior_ship_days
FROM dw.fact_sales fs
JOIN dw.dim_ship_mode dsm
 ON dsm.ship_mode_sk = fs.ship_mode_sk
GROUP BY
 dsm.ship_mode
ORDER BY
 media_ship_days ASC;


--resposta 
    ship_mode    | quantidade_itens | media_ship_days | menor_ship_days | maior_ship_days 

----------------+------------------+-----------------+-----------------+-----------------

Same Day       |              538 |             0.0 |               0 |               1

First Class    |             1501 |             2.2 |               1 |               4

Second Class   |             1902 |             3.2 |               1 |               5

Standard Class |             5859 |             5.0 |               3 |               7

(4 rows)
 
 -- Enunciado 18
-- Usando a dw.dim_date, mostre, por ano e mês, em ordem cronológica: a receita do mês, a
-- receita acumulada no ano (reiniciando a cada ano) e a diferença percentual em relação ao mês
-- anterior, arredondada para uma casa decimal.
WITH receita_mensal AS (
 SELECT
   dd.year,
   dd.month,
   SUM(fs.sales) AS receita_mes
 FROM dw.fact_sales fs
 JOIN dw.dim_date dd
   ON dd.date_sk = fs.order_date_sk
 GROUP BY
   dd.year,
   dd.month
)
SELECT
 year,
 month,
 receita_mes,
 SUM(receita_mes) OVER (
   PARTITION BY year
   ORDER BY month
   ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
 ) AS receita_acumulada_ano,
 ROUND(
   (
     (receita_mes - LAG(receita_mes) OVER (ORDER BY year, month))
     / NULLIF(LAG(receita_mes) OVER (ORDER BY year, month), 0)
   ) * 100,
   1
 ) AS variacao_pct_mes_anterior
FROM receita_mensal
ORDER BY
 year,
 month;

 -- resposta 
 year | month | receita_mes | receita_acumulada_ano | variacao_pct_mes_anterior 

------+-------+-------------+-----------------------+---------------------------

2015 |     1 |    14205.71 |              14205.71 |                          

2015 |     2 |     4519.92 |              18725.63 |                     -68.2

2015 |     3 |    55205.83 |              73931.46 |                    1121.4

2015 |     4 |    27906.86 |             101838.32 |                     -49.4

2015 |     5 |    23644.30 |             125482.62 |                     -15.3

2015 |     6 |    34322.94 |             159805.56 |                      45.2

2015 |     7 |    33781.52 |             193587.08 |                      -1.6

2015 |     8 |    27117.53 |             220704.61 |                     -19.7

2015 |     9 |    81623.52 |             302328.13 |                     201.0

2015 |    10 |    31453.37 |             333781.50 |                     -61.5

2015 |    11 |    77907.69 |             411689.19 |                     147.7

2015 |    12 |    68167.08 |             479856.27 |                     -12.5

2016 |     1 |    18066.96 |              18066.96 |                     -73.5

2016 |     2 |    11951.40 |              30018.36 |                     -33.8

2016 |     3 |    32339.32 |              62357.68 |                     170.6

2016 |     4 |    34154.51 |              96512.19 |                       5.6

2016 |     5 |    29959.56 |             126471.75 |                     -12.3

2016 |     6 |    23599.39 |             150071.14 |                     -21.2

2016 |     7 |    28608.25 |             178679.39 |                      21.2

2016 |     8 |    36818.33 |             215497.72 |                      28.7

2016 |     9 |    63133.56 |             278631.28 |                      71.5

2016 |    10 |    31011.71 |             309642.99 |                     -50.9
 

 -- Enunciado 19
-- Mostre os dez clientes com maior receita: identificação ou nome, segmento, receita,
-- quantidade de pedidos distintos, ticket médio por pedido e percentual sobre a receita total
-- da fato.
SELECT
 dc.customer_id,
 dc.customer_name,
 dc.segment,
 SUM(fs.sales) AS receita,
 COUNT(DISTINCT fs.order_nk) AS pedidos_distintos,
 ROUND((SUM(fs.sales) / NULLIF(COUNT(DISTINCT fs.order_nk), 0))::NUMERIC, 2) AS ticket_medio_pedido,
 ROUND(
   ((SUM(fs.sales) / NULLIF(SUM(SUM(fs.sales)) OVER (), 0)) * 100)::NUMERIC,
   2
 ) AS pct_receita_total
FROM dw.fact_sales fs
JOIN dw.dim_customer dc
 ON dc.customer_sk = fs.customer_sk
GROUP BY
 dc.customer_id,
 dc.customer_name,
 dc.segment
ORDER BY
 receita DESC
LIMIT 10;

-- resposta 
customer_id |   customer_name    |   segment   | receita  | pedidos_distintos | ticket_medio_pedido | pct_receita_total 

-------------+--------------------+-------------+----------+-------------------+---------------------+-------------------

SM-20320    | Sean Miller        | Home Office | 25043.07 |                 5 |             5008.61 |              1.11

TC-20980    | Tamara Chand       | Corporate   | 19052.22 |                 5 |             3810.44 |              0.84

RB-19360    | Raymond Buch       | Consumer    | 15117.35 |                 6 |             2519.56 |              0.67

TA-21385    | Tom Ashbrook       | Home Office | 14595.62 |                 4 |             3648.91 |              0.65

AB-10105    | Adrian Barton      | Consumer    | 14473.57 |                10 |             1447.36 |              0.64

KL-16645    | Ken Lonsdale       | Consumer    | 14175.23 |                12 |             1181.27 |              0.63

SC-20095    | Sanjit Chand       | Consumer    | 14142.34 |                 9 |             1571.37 |              0.63

HL-15040    | Hunter Lopez       | Consumer    | 12873.30 |                 6 |             2145.55 |              0.57

SE-20110    | Sanjit Engle       | Consumer    | 12209.44 |                11 |             1109.95 |              0.54

CC-12370    | Christopher Conant | Consumer    | 12129.08 |                 5 |             2425.82 |              0.54

(10 rows)
 
-- Enunciado 20
-- Com o script.sql completo, execute-o inteiro sobre uma base limpa, usando o script de
-- execução fornecido na aula, e rode novamente a coleta de evidências. Registre em
-- comentário no script.sql a confirmação de que a execução ocorreu sem erros e quantas
-- linhas havia na tabela fato ao final.

-- Execucao final:
-- Status: executado do inicio ao fim sem erros.
-- Total de linhas em dw.fact_sales ao final: 9800
