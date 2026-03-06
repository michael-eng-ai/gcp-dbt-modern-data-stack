# Modern Data Stack: Data Engineering Orchestration on GCP

![Google Cloud](https://img.shields.io/badge/GoogleCloud-%234285F4.svg?style=for-the-badge&logo=google-cloud&logoColor=white) ![dbt](https://img.shields.io/badge/dbt-%23FF694B.svg?style=for-the-badge&logo=dbt&logoColor=white) ![Python](https://img.shields.io/badge/python-3670A0?style=for-the-badge&logo=python&logoColor=ffdd54) ![Terraform](https://img.shields.io/badge/terraform-%235835CC.svg?style=for-the-badge&logo=terraform&logoColor=white) ![GitHub Actions](https://img.shields.io/badge/github%20actions-%232671E5.svg?style=for-the-badge&logo=githubactions&logoColor=white)

Este repositório estabelece as definições estruturais e conceituais de uma Modern Data Stack (MDS) alocada nativamente na Google Cloud Platform (GCP). O modelo proposto assegura arquiteturas modulares orientadas por CI/CD e focadas em tecnologias Open Source para Engenharia de Dados corporativa.

O pipeline encarrega-se da extração pontual analítica de dados de mercado financeiro, transaciona-os à base de Data Lakes de nuvem integrados, e posteriormente aproveita o motor distribuído nativo do Google BigQuery pareado ao dbt Core para orquestrar as transformações tabulares de Inteligência de Negócios. O diferencial central repousa na governança de infraestrutura programada mediante a esteira GitHub Actions.

## Arquitetura Estrutural do Pipeline

1. **Infraestrutura via Código (Terraform)**: O código declarado em `infrastructure/main.tf` gerencia todas as alocações físicas na plataforma, providenciando Buckets GCS transacionais e o BigQuery Dataset definitivo em conformidade de permissões.
2. **Rotinas de Extração de Dados (EL - Python)**: O componente `src/extract_load.py` executa o polling contínuo sob a API da CoinGecko (recuperando índices restritos das principais criptomoedas do mercado). O módulo estabiliza o retorno sob a estrutura iterável de um arquivo em formato Parquet para posterior transporte ao Google Cloud Storage.
3. **Data Quality e Modelagem (dbt Core)**: 
   - A especificação base do dbt materializa interfaces lógicas baseadas nas fontes designadas da Nuvem.
   - Conduz processos iterativos e DAG-oriented originando modelos dimensionais sobre estágios escalonados Bronze/Staging (re-tipados com cast formal) transicionando progressivamente para bases consolidadas Gold/Marts (`fct_crypto_metrics.sql`), com processamento de volatilidade referencial cambial.
   - Testes de Regra de Negócio aplicam obrigações restritivas (Validação Not Null categórica).
4. **Governança Orquestral (CI/CD)**: Dependências sistêmicas repousam codificadas declarativamente via `el_dbt_pipeline.yml`, permitindo disparos CRON e acoplamento serial condicionado (ex: restrição do estágio transformação do dbt até o fechamento exitoso do serviço de Ingestão e Carga).

---

## Procedimentos Base Recomendados

### Pré-Requisitos Sistêmicos
1. Conta instanciada na Google Cloud Platform e client `gcloud CLI` sincronizado.
2. Ambiente global munido por instalação consolidada do binário do dbt Core.

### 1. Implantação de Infraestrutura Declarativa
```bash
cd infrastructure
terraform init
terraform plan -var="project_id=SEU_PROJECT_ID_CORRETO"
terraform apply
```

### 2. Delegação de Acessos Autorizados
Desenvolva a emissão restrita de Service Accounts Keypairs baseados em roles mínimas necessárias para o workflow automatizado (roles como Storage Admin e BigQuery Admin no projeto local).

### 3. Execução Autárquica Temporária (EL Layer)
Para a execução manual programada sem supervisão do CI/CD, determine as restrições:
```bash
export GCP_GCS_BUCKET="nome-do-bucket-criado-referenciado"
export GOOGLE_APPLICATION_CREDENTIALS="/caminho/do/sa_gerado.json"
pip install -r requirements.txt
python src/extract_load.py
```

### 4. Compilação Analítica de Warehouse (dbt)
Verifique e acione a arquitetura no escopo raiz do subdiretório do Analytics Engineering:
```bash
cd dbt_project
export GCP_PROJECT_ID="SEU_PROJECT_ID_CORRETO"

# Compilar dependências e aferir comunicação RPC
dbt debug --profiles-dir .

# Acionamento sistemático sobre toda modelagem modularizada
dbt run --profiles-dir .

# Despacho analítico de Qualidade Relacional e Singular
dbt test --profiles-dir .
```

---
> *A integridade e design desse projeto reflete o domínio sobre soluções robustas no espectro analítico corporativo moderno, balanceando estabilidade ponta-a-ponta e performance escalável no Google BigQuery.*
