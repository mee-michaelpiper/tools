#!/bin/bash
# GitHub Actions → Azure ohne Secrets (OIDC, Federated Credentials), 19.11.2026 – Schritt 2 „Deploy über GitHub Actions“.
# Mit dem Admin-Profil ausführen (Entra: App-Registrierungen anlegen; Azure: Rollen auf ACR und AKS vergeben).
# Legt an (idempotent – ein zweiter Lauf ändert nichts):
#   github-actions-build   AcrPush auf crmeesenburg; vertraut den Repos es-integration und sise-shop, nur in deren GitHub-Umgebung „build“
#   github-actions-deploy  AKS-Zugriff nur auf die Namespaces mee-eserp, mee-siseshop-test, mee-siseshop; vertraut nur infra, Umgebungen „test“/„prod“
# Getrennt, damit ein Build-Workflow nie im Cluster schreiben kann und der Deploy nie Images verändert.
# Free-Plan (20.11.2026): private Repos haben dort keine GitHub-Umgebungen. Deshalb zusätzlich je ein Eintrag „nur Branch main“
# (Workflows ohne environment:, Start von main). Nach dem Wechsel auf GitHub Team: in den Workflows environment: ergänzen und die
# main-Einträge löschen (sonst umgeht ein Lauf von main die Prod-Freigabe) – Befehl siehe ganz unten.
# Gibt am Ende die IDs aus, die in GitHub als Variablen (nicht als Secrets – es sind keine) eingetragen werden.
set -euo pipefail

ORG="Meesenburg-GmbH"
# GitHub schickt bei dieser Organisation das Subject mit unveränderlichen IDs (repo:<org>@<org-id>/<repo>@<repo-id>:…, 20.11.2026 –
# erster Lauf scheiterte mit AADSTS700213). Schützt davor, dass ein später gleichnamig angelegtes Repo vertraut wird.
# IDs: Repo-Seite → Meta-Tags octolytics-dimension-user_id / -repository_id
ORG_ID="357889096"
ES_REPO="es-integration@1462538206"
SHOP_REPO="sise-shop@1462539184"
INFRA_REPO="infra@1461644878"
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

fed() { # appId, Name, Subject – legt an oder korrigiert das Subject eines bestehenden Eintrags
  local body="{\"name\":\"$2\",\"issuer\":\"https://token.actions.githubusercontent.com\",\"subject\":\"$3\",\"audiences\":[\"api://AzureADTokenExchange\"]}"
  local current; current=$(az ad app federated-credential list --id "$1" --query "[?name=='$2'].subject | [0]" -o tsv)
  if [ -z "$current" ]; then
    az ad app federated-credential create --id "$1" --parameters "$body" >/dev/null; echo "  vertraut: $3"
  elif [ "$current" != "$3" ]; then
    az ad app federated-credential update --id "$1" --federated-credential-id "$2" --parameters "$body" >/dev/null; echo "  korrigiert: $3"
  fi
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
fed "$BUILD" es-integration-build "repo:$ORG@$ORG_ID/$ES_REPO:environment:build"
fed "$BUILD" sise-shop-build "repo:$ORG@$ORG_ID/$SHOP_REPO:environment:build"
fed "$BUILD" es-integration-main "repo:$ORG@$ORG_ID/$ES_REPO:ref:refs/heads/main"   # Free-Plan, später löschen
fed "$BUILD" sise-shop-main "repo:$ORG@$ORG_ID/$SHOP_REPO:ref:refs/heads/main"             # Free-Plan, später löschen
role "$BUILD" AcrPush "$ACR_ID"

echo "== github-actions-deploy"
DEPLOY=$(app github-actions-deploy)
fed "$DEPLOY" infra-test "repo:$ORG@$ORG_ID/$INFRA_REPO:environment:test"
fed "$DEPLOY" infra-prod "repo:$ORG@$ORG_ID/$INFRA_REPO:environment:prod"
fed "$DEPLOY" infra-main "repo:$ORG@$ORG_ID/$INFRA_REPO:ref:refs/heads/main"                    # Free-Plan, später löschen
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
echo "Free-Plan: Variablen je Repo (es-integration, sise-shop, infra) mit denselben Namen; nach dem Wechsel auf Team in die Organisation."
# Nach dem Wechsel auf GitHub Team (Umgebungen in den Workflows aktiv):
#   for a in "$BUILD:es-integration-main" "$BUILD:sise-shop-main" "$DEPLOY:infra-main"; do az ad app federated-credential delete --id "${a%%:*}" --federated-credential-id "${a##*:}"; done
