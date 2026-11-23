#!/bin/zsh
# 19.10.2026 – Prod-ES-Portal/AuditLog: Privatkunden mit Firmenmerkmal im Namen (PrivateCustomerCheck), die vor Einführung der
# Prüfung über das Portal angelegt wurden, nachträglich protokollieren (Aktion „customer.company-hint“ = „Privatkunde mit Firmenmerkmal“).
# Nur NEUE Einträge (feste _id „companyhint-<Kundennr>“ → ein zweiter Lauf fügt nichts doppelt ein), bestehende bleiben unverändert.
# Ersteller: ab 14.10. aus dem Änderungsprotokoll, davor aus dem Übertragungsjob, den das Portal nach der Anlage einreiht (RequestedBy).
# Daten (Kundennamen) liegen nur lokal (nie im Git) und werden als Parameter übergeben.
# Ausführen: zsh ~/repos/tools/sap-tools/prod-fixes/2026-10-19-firmenmerkmal-nachtragen.sh <pfad>/companyhint-backfill.json
set -e
DATA="${1:?Pfad zur JSON-Datei mit den Einträgen angeben}"
cd ~/repos/sap-tools/tools/mongoinsert
dotnet build -v q >/dev/null
export MONGO_CS="$(az keyvault secret show --vault-name kv-meesenburg-prod -n MongoDBConnectionString --query value -o tsv)"
dotnet run --no-build -- Prod-ES-Portal AuditLog "$DATA"
