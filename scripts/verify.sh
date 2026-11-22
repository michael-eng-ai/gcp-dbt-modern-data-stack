#!/usr/bin/env bash
# Critério de "pronto" deste repositório. Ninguém (pessoa ou agente) declara
# uma mudança concluída sem este script passar.
#
#   scripts/verify.sh             verificação completa (exige credenciais GCP de dev)
#   scripts/verify.sh --offline   só o que roda sem warehouse; resultado PARCIAL
#
# Código de saída:
#   0 = passou (leia a última linha: COMPLETA ou PARCIAL)
#   1 = falhou
#   2 = não foi possível verificar (faltam credenciais); não é "passou"

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OFFLINE=0

for arg in "$@"; do
  case "$arg" in
    --offline) OFFLINE=1 ;;
    -h|--help) sed -n '2,12p' "${BASH_SOURCE[0]}"; exit 0 ;;
    *) echo "Argumento desconhecido: $arg" >&2; exit 1 ;;
  esac
done

step() { printf '\n==> %s\n' "$1"; }
fail() { printf '\nVERIFICACAO FALHOU: %s\n' "$1" >&2; exit 1; }

command -v dbt >/dev/null 2>&1 \
  || fail "dbt nao encontrado. Instale com: pip install 'dbt-bigquery==1.7.9'"

step "1/3 Sintaxe do script de extracao"
python3 -m py_compile "$ROOT/src/extract_load.py" \
  || fail "src/extract_load.py nao compila"

step "2/3 dbt parse (projeto, refs, sources e YAML; nao acessa o warehouse)"
cd "$ROOT/dbt_project" || fail "pasta dbt_project nao encontrada"
if [[ -f packages.yml ]]; then
  dbt deps --profiles-dir . || fail "dbt deps"
fi
dbt parse --profiles-dir . || fail "dbt parse"

if [[ "$OFFLINE" -eq 1 ]]; then
  printf '\nVERIFICACAO PARCIAL: passou apenas offline. Modelos, testes e reconciliacao NAO foram executados.\n'
  exit 0
fi

if [[ -z "${GCP_PROJECT_ID:-}" || ! -f "${GOOGLE_APPLICATION_CREDENTIALS:-}" ]]; then
  printf '\nNAO VERIFICADO: defina GCP_PROJECT_ID e GOOGLE_APPLICATION_CREDENTIALS (chave de dev)\n' >&2
  printf 'para rodar a verificacao completa, ou use --offline para um resultado parcial.\n' >&2
  exit 2
fi

step "3/3 dbt build no target dev (modelos + testes de schema + reconciliacao)"
dbt build --profiles-dir . --target dev || fail "dbt build"

printf '\nVERIFICACAO COMPLETA: passou.\n'
