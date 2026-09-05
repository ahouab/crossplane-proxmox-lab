#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="${NAMESPACE:-crossplane-lab}"
SECRET_NAME="${SECRET_NAME:-proxmox-credentials}"

for command_name in kubectl jq; do
  if ! command -v "${command_name}" >/dev/null 2>&1; then
    echo "Commande manquante: ${command_name}" >&2
    exit 1
  fi
done

read -r -p "URL Proxmox (ex. https://192.0.2.10:8006/): " PROXMOX_ENDPOINT
read -r -s -p "Token complet (user@realm!id=secret): " PROXMOX_API_TOKEN
echo
read -r -p "Certificat auto-signe ? [o/N]: " SELF_SIGNED

case "${SELF_SIGNED}" in
  o|O|oui|OUI|y|Y|yes|YES) TLS_INSECURE=true ;;
  *) TLS_INSECURE=false ;;
esac

if [[ ! "${PROXMOX_ENDPOINT}" =~ ^https://.+:8006/?$ ]]; then
  echo "URL invalide: utiliser https://hote-ou-ip:8006/" >&2
  exit 1
fi

if [[ ! "${PROXMOX_API_TOKEN}" =~ ^[^=]+![^=]+=.+$ ]]; then
  echo "Token invalide: format attendu user@realm!tokenid=secret" >&2
  exit 1
fi

CREDENTIALS="$(
  jq -cn \
    --arg endpoint "${PROXMOX_ENDPOINT}" \
    --arg api_token "${PROXMOX_API_TOKEN}" \
    --argjson insecure "${TLS_INSECURE}" \
    '{endpoint: $endpoint, api_token: $api_token, insecure: $insecure}'
)"

kubectl create namespace "${NAMESPACE}" --dry-run=client -o yaml | kubectl apply -f -
kubectl create secret generic "${SECRET_NAME}" \
  --namespace "${NAMESPACE}" \
  --from-literal="credentials=${CREDENTIALS}" \
  --dry-run=client -o yaml | kubectl apply -f -

unset PROXMOX_API_TOKEN CREDENTIALS
echo "Secret ${NAMESPACE}/${SECRET_NAME} cree ou mis a jour."
