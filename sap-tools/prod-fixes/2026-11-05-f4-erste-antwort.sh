#!/usr/bin/env bash
# F-4 „Kunde ist in SAP angelegt aber kann nicht übertragen werden“ (Prod-ES-Portal/BugReports):
# Die erste Antwort vom 03.11.2026 10:33 UTC stand nur im alten Feld Answer und wurde am 05.11. durch die Antwort im
# Verlauf überschrieben (Fehler in Web 1.6.7, behoben). Text und Zeitpunkt stammen aus dem Änderungsprotokoll
# (AuditLog, Action bug.status-changed). Setzt sie als ersten Eintrag in den Verlauf – mit Statuswechsel „in Arbeit“.
# Nur mit ausdrücklicher Freigabe ausführen. Mehrfaches Ausführen bricht ab (Filter: Eintrag noch nicht vorhanden).
set -euo pipefail
export MONGO_CS="$(az keyvault secret show --vault-name kv-meesenburg-prod -n MongoDBConnectionString --query value -o tsv)"
cd "$(dirname "$0")/../tools/mongowrite"
dotnet run --no-build -- update Prod-ES-Portal BugReports \
  '{"_id":"3b9908d4e8a84dd983fe2b148f59e553","Messages._id":{"$ne":"restored-f4-2026-11-03"}}' \
  '{"$push":{"Messages":{"$each":[{"_id":"restored-f4-2026-11-03","AuthorObjectId":"8b74a410-3610-43e8-8152-d33f83c1b251","AuthorName":"Piper, Michael (HBG)","FromTeam":true,"Text":"Danke für die Meldung! Wir schauen uns das an und prüfen eine automatisierte Umsetzung um den Kunden um den benötigten Datensatz zu erweitern.","CreatedAtUtc":{"$date":"2026-11-03T10:33:42.386Z"},"Status":"InProgress"}],"$position":0}}}'
