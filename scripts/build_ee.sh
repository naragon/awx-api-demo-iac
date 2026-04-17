#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 2 ]]; then
  echo "Usage: $0 <image-repo> <tag>"
  echo "Example: $0 docker.io/myuser/awx-ee-api-demo v1"
  exit 1
fi

IMAGE_REPO="$1"
IMAGE_TAG="$2"
FULL_IMAGE="${IMAGE_REPO}:${IMAGE_TAG}"

cd "$(dirname "$0")/.."

echo "Building EE image: ${FULL_IMAGE}"
uv run ansible-builder build \
  --file ee/execution-environment.yml \
  --tag "${FULL_IMAGE}" \
  --container-runtime docker \
  --context .

echo "Built ${FULL_IMAGE}"
