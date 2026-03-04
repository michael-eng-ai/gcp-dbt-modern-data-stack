import os
import requests
import pandas as pd
from datetime import datetime
from google.cloud import storage

# ==========================================
# Configurações e Variáveis de Ambiente
# ==========================================
# O dbt usará o BigQuery, mas o ELT bruto pode ir para o GCS
BUCKET_NAME = os.getenv("GCP_GCS_BUCKET", "raw-crypto-data-lake")
# Lista de moedas favoritas
COINS = ["bitcoin", "ethereum", "solana", "cardano", "polkadot"]

def fetch_crypto_data():
    """
    Busca dados atuais de mercado para as moedas selecionadas usando a CoinGecko API (gratuita).
    """
    print("⏳ Iniciando extração da CoinGecko API...")
    url = "https://api.coingecko.com/api/v3/coins/markets"
    params = {
        "vs_currency": "usd",
        "ids": ",".join(COINS),
        "order": "market_cap_desc",
        "per_page": 100,
        "page": 1,
        "sparkline": "false"
    }
    
    response = requests.get(url, params=params)
    response.raise_for_status()
    data = response.json()
    print(f"✅ Extraídos {len(data)} registros com sucesso.")
    return data

def process_and_save_local(data):
    """
    Converte o JSON em um DataFrame Pandas, adiciona metadata e salva em formato Parquet localmente.
    """
    df = pd.DataFrame(data)
    
    # Selecionando e renomeando colunas principais (Raw level)
    cols = [
        "id", "symbol", "name", "current_price", 
        "market_cap", "total_volume", "high_24h", "low_24h", 
        "price_change_percentage_24h", "last_updated"
    ]
    df = df[cols]
    
    # Metadados de Ingestão (Boas práticas de Data Engineering)
    df["ingestion_timestamp"] = datetime.utcnow()
    
    # Prepara o caminho local
    execution_date = datetime.now().strftime("%Y%m%d_%H%M%S")
    local_file_path = f"/tmp/crypto_raw_{execution_date}.parquet"
    
    # Salvar em Parquet (mais leve e schema-on-read amigável para BigQuery)
    df.to_parquet(local_file_path, index=False)
    print(f"📦 Dados processados e salvos localmente em {local_file_path}")
    
    return local_file_path, execution_date

def upload_to_gcs(local_file_path, execution_date):
    """
    Faz o upload do arquivo Parquet para o Google Cloud Storage.
    """
    # Verifica se as credenciais do GCP estão disponíveis
    if not os.getenv("GOOGLE_APPLICATION_CREDENTIALS") and not os.getenv("GCP_SA_KEY"):
        print("⚠️ Variáveis de ambiente de credenciais GCP não encontradas.")
        print("⚠️ Pulando a etapa de upload real para o Cloud Storage.")
        return

    try:
        print(f"☁️ Iniciando upload para o GCS no bucket: {BUCKET_NAME}...")
        client = storage.Client()
        bucket = client.bucket(BUCKET_NAME)
        
        # Particionamento lógico no bucket (Hive Style: raw/crypto/yyyy/mm/dd/)
        now = datetime.now()
        destination_blob_name = f"raw/crypto/year={now.year}/month={now.month:02d}/day={now.day:02d}/crypto_data_{execution_date}.parquet"
        
        blob = bucket.blob(destination_blob_name)
        blob.upload_from_filename(local_file_path)
        
        print(f"🚀 Sucesso! Arquivo enviado para gs://{BUCKET_NAME}/{destination_blob_name}")
    except Exception as e:
        print(f"❌ Erro ao fazer upload para o GCS: {e}")

if __name__ == "__main__":
    print("-" * 50)
    print("🪙 ELT - Extração de Dados de Criptomoedas (CoinGecko)")
    print("-" * 50)
    
    raw_data = fetch_crypto_data()
    file_path, exec_date = process_and_save_local(raw_data)
    upload_to_gcs(file_path, exec_date)
    
    print("-" * 50)
    print("🎉 Pipeline de Extração Finalizado!")
