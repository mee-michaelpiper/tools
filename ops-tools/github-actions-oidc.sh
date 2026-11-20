#!/bin/bash
# GitHub Actions → Azure ohne Secrets (OIDC, Federated Credentials), 19.11.2026 – Schritt 2 „Deploy über GitHub Actions“.
# Mit dem Admin-Profil ausführen (Entra: App-Registrierungen anlegen; Azure: Rollen auf ACR und AKS vergeben).
# Legt an (idempotent – ein zweiter Lauf ändert nichts):
#   github-actions-build   AcrPush auf crmeesenburg; vertraut den Repos es-integration und sise-shop, nur in deren GitHub-Umgebung „build“
#   github-actions-deploy  AKS-Zugriff nur auf die Namespaces mee-eserp, mee-siseshop-test, mee-siseshop; vertraut nur infra, Umgebungen „test“/„prod“
# Getrennt, damit ein Build-Workflow nie im Cluster schreiben kann und der Deploy nie Images verändert.
# Gibt am Ende die IDs aus, die in GitHub als Variablen (nicht als Secrets – es sind keine) eingetragen werden.
set -euo pipefail

ORG="Meesenburg-GmbH"
TENANT="a7473855-450e-4993-befa-62446ec6444b"
ACR_ID="/subscriptions/5b5ab2b8-1d9b-4822-8967-8f387ee117ce/resourceGroups/rg-hub/providers/Microsoft.ContainerRegistry/registries/crmeesenburg"
AKS_ID="/subscriptions/7ad27b6e-b0f6-4c89-b9bf-6089bae5a24f/resourcegroups/rg-kubernetes-prod/providers/Microsoft.ContainerService/managedClusters/aks-meesenburg-prod"
NAMESPACES=(mee-eserp mee-siseshop-test mee-siseshop)

[ "$(az account show --query tenantId -o tsv)" = "$TENANT" ] || { echo "Falscher Mandant – erst mit dem Admin-Profil anmelden"; exit 1; }
echo "Angemeldet als: $(az account show --query user.name -o tsv)"

app() { # Name → appId (anlegen, falls es sie noch nicht gibt)
  local id; id=$(az ad app list --display-name "$1" --query "[0].appId" -o tsv)
  if [ -z "$id" ]; then id=$(az ad app create --display-name "$1" --sign-in-audience AzureADMyOrg --query appId -o tsv); echo "App $1 angelegt" >&2; fi
  az ad sp show --id "$id" >/dev/null 2>&1 || az ad sp create --id "$id" >/dev/null
  echo "$id"
}

fed() { # appId, Name, Subject
  if az ad app federated-credential list --id "$1" --query "[?name=='$2'] | length(@)" -o tsv | grep -q '^1$'; then return; fi
  az ad app federated-credential create --id "$1" --parameters "{\"name\":\"$2\",\"issuer\":\"https://token.actions.githubusercontent.com\",\"subject\":\"$3\",\"audiences\":[\"api://AzureADTokenExchange\"]}" >/dev/null
  echo "  vertraut: $3"
}

role() { # appId, Rolle, Scope
  local sp; sp=$(az ad sp show --id "$1" --query id -o tsv)
  if [ "$(az role assignment list --assignee "$sp" --role "$2" --scope "$3" --query 'length(@)' -o tsv 2>/dev/null)" = "0" ]; then
    az role assignment create --assignee-object-id "$sp" --assignee-principal-type ServicePrincipal --role "$2" --scope "$3" >/dev/null
    echo "  Rolle: $2 auf ${3##*/}"
  fi
}

echo "== github-actions-build"
BUILD=$(app github-actions-build)
fed "$BUILD" es-integration-build "repo:$ORG/es-integration:environment:build"
fed "$BUILD" sise-shop-build "repo:$ORG/sise-shop:environment:build"
role "$BUILD" AcrPush "$ACR_ID"

echo "== github-actions-deploy"
DEPLOY=$(app github-actions-deploy)
fed "$DEPLOY" infra-test "repo:$ORG/infra:environment:test"
fed "$DEPLOY" infra-prod "repo:$ORG/infra:environment:prod"
role "$DEPLOY" "Azure Kubernetes Service Cluster User Role" "$AKS_ID"
for ns in "${NAMESPACES[@]}"; do role "$DEPLOY" "Azure Kubernetes Service RBAC Writer" "$AKS_ID/namespaces/$ns"; done

echo
echo "In GitHub als Variablen eintragen (Organisation → Settings → Secrets and variables → Actions → Variables):"
echo "  AZURE_TENANT_ID        = $TENANT"
echo "  AZURE_BUILD_CLIENT_ID  = $BUILD"
echo "  AZURE_DEPLOY_CLIENT_ID = $DEPLOY"
echo "  AZURE_ACR_SUBSCRIPTION = 5b5ab2b8-1d9b-4822-8967-8f387ee117ce"
echo "  AZURE_AKS_SUBSCRIPTION = 7ad27b6e-b0f6-4c89-b9bf-6089bae5a24f"
echo "Und je Repo die Umgebungen anlegen: es-integration + sise-shop → „build“, infra → „test“ und „prod“ (prod mit Freigabe durch dich)."
