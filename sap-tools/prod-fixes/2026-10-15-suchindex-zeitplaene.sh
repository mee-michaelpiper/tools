#!/bin/zsh
# 15.10.2026 – Prod-ES-Worker: Suchindex-Zeitpläne aufteilen und verwaisten Rechnungsversand-Job beenden.
# Ausführen: zsh ~/repos/sap-tools/prod-fixes/2026-10-15-suchindex-zeitplaene.sh
set -e
cd ~/repos/sap-tools/tools/mongowrite
dotnet build -v q >/dev/null
export MONGO_CS="$(az keyvault secret show --vault-name kv-meesenburg-prod -n MongoDBConnectionString --query value -o tsv)"

echo "== 1) Bestehender Zeitplan: nur Kunden + Artikel, alle 15 Min."
dotnet run --no-build -- update Prod-ES-Worker Jobs-Schedules '{ "_id": { "$oid": "6ad13c83e13990d4da2c137b" } }' \
  '{ "$set": { "FilterJson": "{\"Types\":[\"customer\",\"article\"]}", "IntervalSeconds": 900 } }'

echo "== 2) Neuer Zeitplan: Rechnungen, alle 5 Min."
NEXT=$(python3 -c "import datetime;print((datetime.datetime.now(datetime.timezone.utc)+datetime.timedelta(minutes=1)).strftime('%Y-%m-%dT%H:%M:%S.000Z'))")
dotnet run --no-build -- insert Prod-ES-Worker Jobs-Schedules "{ \"Enabled\": true, \"JobType\": 9, \"FilterJson\": \"{\\\"Types\\\":[\\\"invoice\\\"]}\", \"Priority\": 1, \"ScheduleKind\": 0, \"IntervalSeconds\": 300, \"DailyLocalTime\": null, \"TimeZoneId\": null, \"PayloadJson\": null, \"NextRunUtc\": { \"\$date\": \"$NEXT\" }, \"LastDispatchedUtc\": null, \"LastError\": null }"

echo "== 3) Verwaisten Rechnungsversand-Job 1b76d7e6 auf „fehlgeschlagen“ (nur wenn noch Status 2 = läuft)"
read MS TICKS <<< $(python3 -c "import time;ms=int(time.time()*1000);print(ms, ms*10000+621355968000000000)")
ISO=$(python3 -c "import datetime;print(datetime.datetime.fromtimestamp($MS/1000, datetime.timezone.utc).strftime('%Y-%m-%dT%H:%M:%S.%f')[:-3]+'Z')")
ID=$(python3 -c "import uuid,base64;print(base64.b64encode(uuid.UUID('1b76d7e6-7679-4293-9673-8ed68aab0021').bytes).decode())")
dotnet run --no-build -- update Prod-ES-Worker Jobs "{ \"_id\": { \"\$binary\": { \"base64\": \"$ID\", \"subType\": \"04\" } }, \"Status\": 2 }" \
  "{ \"\$set\": { \"Status\": 4, \"FinishedAtUtc\": { \"DateTime\": { \"\$date\": \"$ISO\" }, \"Ticks\": { \"\$numberLong\": \"$TICKS\" }, \"Offset\": 0 }, \"LastError\": \"Verwaist: kein Heartbeat seit 20:45:24 UTC (Mongo kurz nicht erreichbar, Worker-Pod danach ersetzt) – von Hand beendet\" } }"
