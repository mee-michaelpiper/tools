#!/bin/zsh
# Aufruf: ./run.sh "SELECT …" ["SELECT …"]  – Zugang aus KV-Secret esErpSqlReadonly (nur lesend, Transaktion wird zurückgerollt)
az keyvault secret show --vault-name kv-meesenburg-prod -n esErpSqlReadonly --query value -o tsv \
  | dotnet run --no-build --project "${0:A:h}" -- "$@"
