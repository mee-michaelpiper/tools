#!/bin/bash
# Lokale Entwicklung SiSe-Shop: dem angemeldeten Azure-Konto (az login) die Rolle „Shop-Administration“ in der lokalen Aspire-Mongo geben.
# Nötig seit 19.11.2026: Der Admin kennt keine Test-Personen mehr, auch lokal nur Entra-Anmeldung. Ändert nur die lokale Datenbank „siseshop“.
# Aufruf: ./lokal-admin-recht.sh            (Aspire des Shops muss laufen)
set -euo pipefail
local=$(podman ps --format '{{.Names}}' | grep -m1 -i mongo) || { echo "Lokale Mongo läuft nicht (Aspire des Shops starten)."; exit 1; }
oid=$(az ad signed-in-user show --query id -o tsv); upn=$(az ad signed-in-user show --query userPrincipalName -o tsv)
js="db=db.getSiblingDB('siseshop');
  db.RoleAssignments.updateOne({SubjectType:0, SubjectId:'$oid', RoleId:'shop-admin'},
    {\$setOnInsert:{_id:crypto.randomUUID().replace(/-/g,''), SubjectName:'$upn', SubjectEmail:'$upn', Permission:null, AssignedBy:'lokal-admin-recht.sh', AssignedAtUtc:new Date()}},
    {upsert:true}); print('Rolle Shop-Administration (lokal) für $upn')"
podman exec -e JS="$js" "$local" sh -c 'mongosh -u "$MONGO_INITDB_ROOT_USERNAME" -p "$MONGO_INITDB_ROOT_PASSWORD" --authenticationDatabase admin --quiet --eval "$JS"'
