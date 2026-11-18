#!/usr/bin/env bash
# Reiter „Protokoll“ in Berechtigungen liest seit Web 1.6.7 nur noch AuditLog (ObjectType Role).
# Seit 13.10.2026 schrieb PermissionStore doppelt (PermissionAudit + AuditLog). Diese 5 Einträge stehen nur in der alten
# Collection PermissionAudit (Startdaten 06.10., 2 Zuweisungen 06.10., Rolle Grundzugang 13.10., Migration 15.10.) →
# mit gleicher _id nach Prod-ES-Portal/AuditLog übernehmen. mongoinsert fügt nur fehlende _id ein → mehrfach ausführbar.
# Nur mit ausdrücklicher Freigabe ausführen. PermissionAudit danach NICHT löschen (eigene Freigabe, erst wenn alle Dienste auf Authorization 1.0.15).
set -euo pipefail
export MONGO_CS="$(az keyvault secret show --vault-name kv-meesenburg-prod -n MongoDBConnectionString --query value -o tsv)"
here="$(cd "$(dirname "$0")" && pwd)"
cd "$here/../tools/mongoinsert"
dotnet run --no-build -- Prod-ES-Portal AuditLog "$here/data/2026-11-05-permission-audit.json"
