#!/bin/zsh
# 15.10.2026 – Fehlgeschlagene Jobs der letzten 90 Tage als Log-Einträge nachtragen (Prod-ES-Logs/Logs),
# gekennzeichnet mit Properties.Backfilled = true, ohne Dubletten (erneuter Aufruf schreibt nichts doppelt).
# Probelauf vorher: gleicher Aufruf ohne --write. Stand 15.10.: 784 Einträge (29 Dateifreigaben, 4 IMAP, 2 interne Dienste).
set -e
cd ~/repos/sap-tools/tools/job-failures-to-log
dotnet build -v q >/dev/null
export MONGO_CS="$(az keyvault secret show --vault-name kv-meesenburg-prod -n MongoDBConnectionString --query value -o tsv)"
dotnet run --no-build -- 90 --write
