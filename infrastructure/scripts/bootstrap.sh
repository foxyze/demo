#!/usr/bin/env bash
# Bootstrap Terraform remote state and GitHub OIDC identity.
# Idempotent: safe to re-run. Requires: az login.
set -euo pipefail

LOCATION="swedencentral"
STATE_RG="rg-demo-tfstate"
STATE_CONTAINER="tfstate"
APP_NAME="sp-demo-github"
GITHUB_REPO="foxyze/demo"
GITHUB_ENVIRONMENTS=("preprod" "prod")

SUBSCRIPTION_ID=$(az account show --query id -o tsv)
TENANT_ID=$(az account show --query tenantId -o tsv)
# Storage account names are global; derive a stable unique suffix from the subscription.
STATE_SA="stdemotf${SUBSCRIPTION_ID:0:8}"

az provider register --namespace Microsoft.Storage --wait

echo "Resource group: $STATE_RG"
az group create --name "$STATE_RG" --location "$LOCATION" -o none

echo "Storage account: $STATE_SA"
if ! az storage account show --name "$STATE_SA" --resource-group "$STATE_RG" &>/dev/null; then
  az storage account create \
    --name "$STATE_SA" \
    --resource-group "$STATE_RG" \
    --location "$LOCATION" \
    --sku Standard_LRS \
    --kind StorageV2 \
    --min-tls-version TLS1_2 \
    --allow-blob-public-access false \
    -o none
fi

echo "Container: $STATE_CONTAINER"
az storage container create \
  --name "$STATE_CONTAINER" \
  --account-name "$STATE_SA" \
  --auth-mode key \
  -o none

echo "App registration: $APP_NAME"
APP_ID=$(az ad app list --display-name "$APP_NAME" --query "[0].appId" -o tsv)
if [[ -z "$APP_ID" ]]; then
  APP_ID=$(az ad app create --display-name "$APP_NAME" --query appId -o tsv)
fi

SP_OBJECT_ID=$(az ad sp list --filter "appId eq '$APP_ID'" --query "[0].id" -o tsv)
if [[ -z "$SP_OBJECT_ID" ]]; then
  SP_OBJECT_ID=$(az ad sp create --id "$APP_ID" --query id -o tsv)
fi

for ENV in "${GITHUB_ENVIRONMENTS[@]}"; do
  CRED_NAME="github-${ENV}"
  echo "Federated credential: $CRED_NAME"
  if ! az ad app federated-credential show --id "$APP_ID" --federated-credential-id "$CRED_NAME" &>/dev/null; then
    az ad app federated-credential create --id "$APP_ID" -o none --parameters "{
      \"name\": \"${CRED_NAME}\",
      \"issuer\": \"https://token.actions.githubusercontent.com\",
      \"subject\": \"repo:${GITHUB_REPO}:environment:${ENV}\",
      \"audiences\": [\"api://AzureADTokenExchange\"]
    }"
  fi
done

echo
echo "AZURE_CLIENT_ID=$APP_ID"
echo "AZURE_TENANT_ID=$TENANT_ID"
echo "AZURE_SUBSCRIPTION_ID=$SUBSCRIPTION_ID"
echo "SP_OBJECT_ID=$SP_OBJECT_ID"
echo "STATE_RG=$STATE_RG"
echo "STATE_SA=$STATE_SA"
echo "STATE_CONTAINER=$STATE_CONTAINER"

