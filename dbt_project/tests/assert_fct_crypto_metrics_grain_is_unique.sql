-- Grão declarado de fct_crypto_metrics: 1 linha por (coin_id, execution_date).
-- O modelo agrupa também por coin_symbol e coin_name; se a API devolver nome ou
-- símbolo diferente para a mesma moeda no mesmo dia, o grão quebra em silêncio.
-- O teste falha se retornar qualquer linha.

SELECT
    coin_id,
    execution_date,
    COUNT(*) AS n_linhas
FROM {{ ref('fct_crypto_metrics') }}
GROUP BY coin_id, execution_date
HAVING COUNT(*) > 1
