-- models/marts/fct_crypto_metrics.sql
-- Camada Gold/Marts. Tabela agregada final pronta para o consumo de um BI (Ex: Power BI / Looker)

{{ config(
    materialized='table',
    partition_by={
      "field": "execution_date",
      "data_type": "date",
      "granularity": "day"
    }
) }}

WITH staged_data AS (
    SELECT * FROM {{ ref('stg_crypto') }}
),

aggregated_metrics AS (
    SELECT
        coin_id,
        coin_symbol,
        coin_name,
        
        -- Snapshot dimensions
        DATE(api_updated_at) AS execution_date,
        
        -- Latest values per day per coin (Deduplication if multiple runs happen in a day)
        MAX(api_updated_at) AS latest_daily_update,
        AVG(current_price_usd) AS avg_daily_price_usd,
        MAX(market_cap_usd) AS max_daily_market_cap,
        SUM(volume_24h_usd) AS total_daily_volume,
        
        -- Conditional Volatility Flag Example
        MAX(price_change_pct_24h) AS eod_price_change_pct,
        CASE 
            WHEN MAX(price_change_pct_24h) > 5.0 THEN 'High Growth'
            WHEN MAX(price_change_pct_24h) < -5.0 THEN 'High Drop'
            ELSE 'Stable'
        END AS volatility_status

    FROM staged_data
    GROUP BY 
        coin_id, 
        coin_symbol, 
        coin_name, 
        DATE(api_updated_at)
)

SELECT * FROM aggregated_metrics
