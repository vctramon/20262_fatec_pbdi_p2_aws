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

