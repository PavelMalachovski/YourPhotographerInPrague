#!/usr/bin/env bash
set -euo pipefail

#=============================================================================
# Deploy WordPress + MySQL to the kubespray cluster (k8s/ kustomize overlays).
#
# Required env:
#   KUBECONFIG            admin kubeconfig (written by kubespray.sh)
#   MYSQL_ROOT_PASSWORD   } stored in GitHub Secrets, turned into the
#   MYSQL_PASSWORD        } Kubernetes Secret "wordpress-db"
# Optional env:
#   MYSQL_USER            default: wordpress
#   IMAGE_TAG             immutable image tag to deploy, default: latest
#   K8S_OVERLAY           dev | production, default: dev
#=============================================================================

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
: "${KUBECONFIG:?KUBECONFIG is not set}"
: "${MYSQL_ROOT_PASSWORD:?MYSQL_ROOT_PASSWORD is not set}"
: "${MYSQL_PASSWORD:?MYSQL_PASSWORD is not set}"
MYSQL_USER="${MYSQL_USER:-wordpress}"
IMAGE_TAG="${IMAGE_TAG:-latest}"
K8S_OVERLAY="${K8S_OVERLAY:-dev}"
export KUBECONFIG

if [[ ! "${IMAGE_TAG}" =~ ^[A-Za-z0-9._-]{1,128}$ ]]; then
  echo "Invalid IMAGE_TAG: ${IMAGE_TAG}" >&2; exit 1
fi
if [[ ! -d "${PROJECT_DIR}/k8s/overlays/${K8S_OVERLAY}" ]]; then
  echo "Unknown overlay: ${K8S_OVERLAY}" >&2; exit 1
fi

echo "== Waiting for nodes"
kubectl wait --for=condition=Ready nodes --all --timeout=300s

echo "== Namespace + DB secret"
kubectl apply -f "${PROJECT_DIR}/k8s/base/namespace.yaml"
# Values go through a 0600 temp file, never through command-line arguments.
SECRET_ENV="$(mktemp)"
trap 'rm -f "${SECRET_ENV}"' EXIT
chmod 600 "${SECRET_ENV}"
printf 'mysql-root-password=%s\nmysql-user=%s\nmysql-password=%s\n' \
  "${MYSQL_ROOT_PASSWORD}" "${MYSQL_USER}" "${MYSQL_PASSWORD}" > "${SECRET_ENV}"
kubectl -n ypip create secret generic wordpress-db \
  --from-env-file="${SECRET_ENV}" --dry-run=client -o yaml | kubectl apply -f -

echo "== Apply overlay '${K8S_OVERLAY}' with image tag '${IMAGE_TAG}'"
# Throw-away overlay that pins the immutable image tag (git-ignored).
DEPLOY_DIR="${PROJECT_DIR}/k8s/overlays/.deploy"
rm -rf "${DEPLOY_DIR}" && mkdir -p "${DEPLOY_DIR}"
cat > "${DEPLOY_DIR}/kustomization.yaml" <<KUST
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - ../${K8S_OVERLAY}
images:
  - name: pavelmalachovski/yourphotographerinprague
    newTag: "${IMAGE_TAG}"
KUST
kubectl apply -k "${DEPLOY_DIR}"
rm -rf "${DEPLOY_DIR}"

echo "== Rollout"
kubectl -n ypip rollout status statefulset/mysql --timeout=600s
kubectl -n ypip rollout status deployment/wordpress --timeout=600s
kubectl -n ypip get pods,svc,ingress
