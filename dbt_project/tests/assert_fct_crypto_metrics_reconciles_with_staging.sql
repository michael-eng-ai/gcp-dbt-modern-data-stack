-- Reconciliação mart x staging: toda combinação (coin_id, dia) presente em
-- stg_crypto precisa existir em fct_crypto_metrics, e vice-versa, com o mesmo
-- horário da última atualização do dia. Pega linha perdida, linha inventada e
-- agregação que mudou de sentido. O teste falha se retornar qualquer linha.

WITH esperado AS (
    SELECT
        coin_id,
        DATE(api_updated_at) AS execution_date,
        MAX(api_updated_at) AS latest_daily_update
    FROM {{ ref('stg_crypto') }}
    GROUP BY coin_id, DATE(api_updated_at)
),

obtido AS (
    SELECT
        coin_id,
        execution_date,
        MAX(latest_daily_update) AS latest_daily_update
    FROM {{ ref('fct_crypto_metrics') }}
    GROUP BY coin_id, execution_date
)

SELECT
    COALESCE(e.coin_id, o.coin_id) AS coin_id,
    COALESCE(e.execution_date, o.execution_date) AS execution_date,
    CASE
        WHEN o.coin_id IS NULL THEN 'faltando no mart'
        WHEN e.coin_id IS NULL THEN 'sobrando no mart'
        ELSE 'latest_daily_update diverge do staging'
    END AS problema
FROM esperado AS e
FULL OUTER JOIN obtido AS o
    ON e.coin_id = o.coin_id
    AND e.execution_date = o.execution_date
WHERE e.coin_id IS NULL
    OR o.coin_id IS NULL
    OR e.latest_daily_update != o.latest_daily_update
