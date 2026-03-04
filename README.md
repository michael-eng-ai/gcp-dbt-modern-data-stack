# 🌩️ Modern Data Stack: Orquestração ELT no GCP 

![Google Cloud](https://img.shields.io/badge/GoogleCloud-%234285F4.svg?style=for-the-badge&logo=google-cloud&logoColor=white) ![dbt](https://img.shields.io/badge/dbt-%23FF694B.svg?style=for-the-badge&logo=dbt&logoColor=white) ![Python](https://img.shields.io/badge/python-3670A0?style=for-the-badge&logo=python&logoColor=ffdd54) ![Terraform](https://img.shields.io/badge/terraform-%235835CC.svg?style=for-the-badge&logo=terraform&logoColor=white) ![GitHub Actions](https://img.shields.io/badge/github%20actions-%232671E5.svg?style=for-the-badge&logo=githubactions&logoColor=white)

Este repositório prova a capacidade de desenhar e construir a **Modern Data Stack** (MDS) na Google Cloud Platform (GCP) com custo praticamente zerado, focando nas tecnologias Open Source adotadas por times de Engenharia Analítica de alto desempenho.

O pipeline extrai diariamente dados de mercado de criptomoedas (via API aberta), carrega dados no Data Lake (*Extract & Load*), e utiliza todo poder elástico do **BigQuery** para transformar a inteligência de negócios através do **dbt Core** (*Transform*). O super-diferencial é a total orquestração unificada via **GitHub Actions** dispensando orquestradores verbosos. 

## 🗺️ Fluxo Macro da Arquitetura

1. **Infraestrutura via Código (Terraform)**: Script (`infrastructure/main.tf`) provê automaticamente o Bucket raw do GCS e o Analytics Dataset destino no BigQuery.
2. **Camada de Extração (EL - Python)**: O job `src/extract_load.py` consome a API REST da CoinGecko (Top 5 Criptomoedas do momento), tipa para *Parquet* em memória e atira o artefato no **Google Cloud Storage**.
3. **Data Quality & Transformação (dbt Core)**: 
   - A ferramenta `dbt` mapeia a *Source* externa automaticamente.
   - Aplica os padrões analíticos criando *Views / Tables* em Bigquery partindo de *Bronze (Staging)* re-tipados, até modelar a View *Gold (Marts)* particionada (`fct_crypto_metrics.sql`), agregando a volatilidade do mercado em USD.
   - Testes de Regra de Negócio aplicados com *YAML* (Not Null e Aceitação Categórica).
4. **Schedule Masterpiece (Cérebro do Pipeline)**: O Workflow (`el_dbt_pipeline.yml`) roda no GitHub Actions num *CRON Job* diário enfileirando as dependências lógicas (Ex: o dbt só roda após o EL do Python passar com sucesso).

---

## 🚀 Como Executar Localmente

### Pré-Requisitos
1. Conta no [Google Cloud Platform](https://console.cloud.google.com/) e gcloud CLI configurado.
2. [dbt Core](https://docs.getdbt.com/docs/core/installation) localmente instalado.

### 1️⃣ Subindo a Infraestrutura com Terraform
```bash
cd infrastructure
terraform init
# Substitua o fake-id nas variáveis ou via cli
terraform plan -var="project_id=seu-gcp-project-123"
terraform apply
```

### 2️⃣ Gerando Auth Secrets
Crie uma chave JSON associada ao Service Account no seu projeto do GCP que detenha os acessos (Storage Admin e BigQuery Admin) para a esteira conseguir trabalhar.

### 3️⃣ Carga EL Local (Python)
Para popular os dados *raw* no Storage recém criado:
```bash
export GCP_GCS_BUCKET="raw-crypto-data-lake-1234"
export GOOGLE_APPLICATION_CREDENTIALS="/caminho/do/sa_gerado.json"
pip install -r requirements.txt
python src/extract_load.py
```

### 4️⃣ A Mágica do dbt (Transformação)
No nível físico (BigQuery), o schema destino já está provisionado, ative os modelos:
```bash
cd dbt_project
export GCP_PROJECT_ID="seu-gcp-project-123"

# Compilar e Testar a conexão
dbt debug --profiles-dir .

# Rodar todos os Modelos (Staging e Fact)
dbt run --profiles-dir .

# Executar Testes de Qualidade
dbt test --profiles-dir .
```
> Após as instâncias passarem, explore suas moedas via console oficial de visualização nativa na UI do Google BigQuery ou atrelando as fact tables no PowerBI/Looker!

---
> *Este projeto valida expertise avançada orquestral reduzindo TCO (Total Cost of Ownership) do cloud stack ao mínimo possível usando CI/CD pipelines puros e arquitetura serverless nativa na GCP.*
