-- models/staging/stg_crypto.sql
-- Essa é a camada Silver/Staging. Lê os dados brutos e padroniza tipos e nomes.

WITH source AS (
    SELECT * FROM {{ source('crypto_raw', 'raw_crypto_prices') }}
),

renamed_and_casted AS (
    SELECT
        CAST(id AS STRING) AS coin_id,
        UPPER(CAST(symbol AS STRING)) AS coin_symbol,
        CAST(name AS STRING) AS coin_name,
        
        -- Métricas Financeiras
        CAST(current_price AS FLOAT64) AS current_price_usd,
        CAST(market_cap AS INT64) AS market_cap_usd,
        CAST(total_volume AS INT64) AS volume_24h_usd,
        
        -- Variação de Preço
        CAST(high_24h AS FLOAT64) AS high_price_24h_usd,
        CAST(low_24h AS FLOAT64) AS low_price_24h_usd,
        CAST(price_change_percentage_24h AS FLOAT64) AS price_change_pct_24h,
        
        -- Datas e Metadados
        CAST(last_updated AS TIMESTAMP) AS api_updated_at,
        CAST(ingestion_timestamp AS TIMESTAMP) AS dl_ingested_at
    FROM source
)

SELECT * FROM renamed_and_casted
