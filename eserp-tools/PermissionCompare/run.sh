#!/bin/bash
# Rechte-Vergleich altes ↔ neues Paket (siehe Program.cs). Liest Prod-ES-Portal nur, schreibt nur in die lokale Aspire-Mongo.
set -euo pipefail
cd "$(dirname "$0")"
# Startrollen von ES ins Werkzeug übernehmen – eigener Namensraum, weil das alte Paket denselben Namensraum Meesenburg.ES.Authorization hat
mkdir -p Generated
sed -e 's/^namespace Meesenburg.ES.Authorization;/namespace PermissionCompareSeed;\nusing Permissions = Meesenburg.ES.Authorization.Permissions;/' \
    -e 's/public static class EsPermissionSeed/public static class EsPermissionSeedForCompare/' \
    "$HOME/repos/Meesenburg.ES/src/Meesenburg.ES.Permissions/EsPermissionSeed.cs" > Generated/EsPermissionSeedForCompare.cs
local=$(podman ps --format '{{.Names}}' | grep -m1 -i mongo) || { echo "Lokale Mongo läuft nicht (Aspire starten)."; exit 1; }
port=$(podman port "$local" 27017 | head -1 | sed 's/.*://')
user=$(podman exec "$local" printenv MONGO_INITDB_ROOT_USERNAME); pass=$(podman exec "$local" printenv MONGO_INITDB_ROOT_PASSWORD)
export LOCAL_CS="mongodb://$user:$pass@127.0.0.1:$port/?authSource=admin&directConnection=true"
export MONGO_CS=$(az keyvault secret show --vault-name kv-meesenburg-prod -n MongoDBConnectionString --query value -o tsv)
export GITHUB_PACKAGES_TOKEN=$(security find-generic-password -s github-packages-meesenburg -w)
dotnet run 2>&1 | grep -v "warning"
