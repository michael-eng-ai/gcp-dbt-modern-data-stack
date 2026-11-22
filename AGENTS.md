# AGENTS.md

Instruções para agentes de código (Claude Code, Codex e similares) que trabalham neste repositório. Valem também para pessoas.

## Mapa do repositório

| Caminho | O que é |
|---|---|
| `src/extract_load.py` | Extração da CoinGecko, grava Parquet e envia ao GCS em `raw/crypto/year=/month=/day=/` |
| `dbt_project/` | Projeto dbt `crypto_analytics` (BigQuery). Perfil `crypto_bg_profile`, único target `dev` |
| `dbt_project/models/staging/` | Camada silver: views `stg_*`, com tipos e nomes padronizados |
| `dbt_project/models/marts/` | Camada gold: tabelas `fct_*` para consumo de BI |
| `dbt_project/tests/` | Testes singulares de reconciliação e de grão |
| `infrastructure/` | Terraform do bucket GCS e do dataset BigQuery |
| `.github/workflows/el_dbt_pipeline.yml` | Pipeline diário (12:00 UTC): extração, depois dbt |
| `scripts/verify.sh` | Critério de pronto (ver abaixo) |

O dataset base é `crypto_dbt_analytics`. Como o projeto usa `+schema` sem macro própria de nomes, o dbt materializa em `crypto_dbt_analytics_silver` e `crypto_dbt_analytics_gold`.

## Ambiente e comandos

Python 3.10 ou 3.11.

```bash
pip install -r requirements.txt
pip install 'dbt-bigquery==1.7.9'

cd dbt_project
dbt parse --profiles-dir .                  # offline
dbt build --profiles-dir . --target dev     # exige credenciais
```

Variáveis para acessar o BigQuery: `GCP_PROJECT_ID` e `GOOGLE_APPLICATION_CREDENTIALS` (caminho da chave de dev). Sem elas o perfil cai em valores falsos e qualquer comando que toque o warehouse falha.

## Convenções

- Staging só lê de `source()`. Marts só leem de `ref()`. Nenhum modelo referencia tabela pelo nome físico.
- Todo `CAST` e renomeação acontece no staging. Mart não retipa coluna.
- Prefixos: `stg_` no staging, `fct_` e `dim_` nos marts. Colunas em `snake_case`, valores monetários com sufixo da moeda (`_usd`), timestamps com sufixo `_at`.
- Todo modelo novo ou alterado tem entrada em um `schema.yml` com descrição, grão declarado e testes na chave do grão (`not_null`, e `unique` ou teste singular quando a chave é composta).
- Mudou a lógica de um mart: atualize ou crie o teste de reconciliação correspondente em `dbt_project/tests/`.
- SQL no dialeto do BigQuery. Comentários em português, identificadores em inglês.

## Definição de pronto

Uma mudança só está pronta quando `scripts/verify.sh` termina com `VERIFICACAO COMPLETA: passou.`

```bash
scripts/verify.sh             # completa: parse + dbt build (modelos, testes, reconciliação)
scripts/verify.sh --offline   # parcial: só sintaxe e dbt parse
```

Códigos de saída: `0` passou, `1` falhou, `2` não foi possível verificar por falta de credenciais.

Ao reportar o trabalho, diga qual das três situações ocorreu e cole a última linha do script. Saída `2` ou resultado `PARCIAL` se reporta como "não verificado no warehouse", nunca como concluído.

## Ciclo de trabalho

1. Antes de editar, escreva em uma frase o que muda e qual teste vai provar que funcionou. Se não existe teste que prove, crie-o primeiro.
2. Faça a mudança e rode `scripts/verify.sh`.
3. Falhou: leia o erro, corrija a causa e rode de novo. No máximo três tentativas para a mesma falha; depois disso pare e reporte o que tentou e o que observou.
4. Passou: revise o `git diff` inteiro antes de reportar. Só entra o que a tarefa pediu.

## Limites

- Não rode `terraform apply` nem `terraform destroy`. Mudança em `infrastructure/` só quando pedida, e entregue como `terraform plan`.
- Use apenas o target `dev`. Não crie outros targets nem altere `profiles.yml` sem pedido.
- Nunca commite chaves, `.env` ou qualquer credencial. Não imprima conteúdo de chave em logs.
- Não remova, afrouxe nem desative um teste para fazer a verificação passar. Se o teste estiver errado, explique por quê e proponha a correção em separado.
- Não adicione `continue-on-error`, `|| true` ou `try/except` que engula erro.
- Trabalhe em branch e abra pull request. Nada de push direto na `main`.

## Estado atual que engana

- A CI exige os secrets `GCP_SA_KEY`, `GCP_PROJECT_ID` e `GCP_GCS_BUCKET`. Sem `GCP_SA_KEY` ela falha na autenticação, de propósito. O job de dbt verde significa que modelos e testes rodaram; o job de extração verde ainda não garante o envio ao GCS (ver abaixo).
- Não volte para `dbt-bigquery==1.7.0`: essa versão quebra no import com a `google-cloud-bigquery` atual. Use a `1.7.9`, a mesma da CI.
- A tabela de origem `crypto_dbt_analytics.raw_crypto_prices` não é criada por nenhum código deste repositório: o script de extração só envia Parquet ao GCS. O `dbt build` depende de ela existir.
- `upload_to_gcs` em `src/extract_load.py` pula o envio quando faltam credenciais e captura exceções sem relançar. O script termina com sucesso mesmo sem ter enviado nada.
- `stg_crypto` ainda não tem entrada em `schema.yml`.
