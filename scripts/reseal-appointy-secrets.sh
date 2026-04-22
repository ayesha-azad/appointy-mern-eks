#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="${KUBE_NAMESPACE:-appointy}"
SECRET_NAME="${SECRET_NAME:-appointy-secrets}"
CONTROLLER_NAMESPACE="${SEALED_SECRETS_CONTROLLER_NAMESPACE:-kube-system}"
CONTROLLER_NAME="${SEALED_SECRETS_CONTROLLER_NAME:-sealed-secrets-controller}"

require() {
  local key="$1"
  if [[ -z "${!key:-}" ]]; then
    echo "Missing required env var: $key" >&2
    exit 1
  fi
}

require MONGODB_ROOT_PASSWORD
require MONGODB_URI
require JWT_SECRET
require ADMIN_EMAIL
require ADMIN_PASSWORD
require CLOUDINARY_NAME
require CLOUDINARY_API_KEY
require CLOUDINARY_SECRET_KEY

if ! command -v kubectl >/dev/null 2>&1; then
  echo "kubectl not found in PATH" >&2
  exit 1
fi
if ! command -v kubeseal >/dev/null 2>&1; then
  echo "kubeseal not found in PATH" >&2
  exit 1
fi

echo "Generating SealedSecret for ${NAMESPACE}/${SECRET_NAME} using ${CONTROLLER_NAMESPACE}/${CONTROLLER_NAME}..."

tmp_secret="$(mktemp)"
tmp_sealed="$(mktemp)"
trap 'rm -f "$tmp_secret" "$tmp_sealed"' EXIT

kubectl create secret generic "${SECRET_NAME}" \
  -n "${NAMESPACE}" \
  --from-literal=mongodb-root-password="${MONGODB_ROOT_PASSWORD}" \
  --from-literal=mongodb-uri="${MONGODB_URI}" \
  --from-literal=jwt-secret="${JWT_SECRET}" \
  --from-literal=admin-email="${ADMIN_EMAIL}" \
  --from-literal=admin-password="${ADMIN_PASSWORD}" \
  --from-literal=cloudinary-name="${CLOUDINARY_NAME}" \
  --from-literal=cloudinary-api-key="${CLOUDINARY_API_KEY}" \
  --from-literal=cloudinary-secret-key="${CLOUDINARY_SECRET_KEY}" \
  --dry-run=client -o yaml > "$tmp_secret"

kubeseal \
  --controller-namespace "${CONTROLLER_NAMESPACE}" \
  --controller-name "${CONTROLLER_NAME}" \
  --format yaml < "$tmp_secret" > "$tmp_sealed"

mkdir -p k8s
cp "$tmp_sealed" k8s/sealed-secrets.yaml

echo "Wrote k8s/sealed-secrets.yaml"
echo "Next: git add k8s/sealed-secrets.yaml && git commit -m \"Reseal appointy secrets\" && git push"
