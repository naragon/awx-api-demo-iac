#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 2 || $# -gt 3 ]]; then
  echo "Usage: $0 <image-repo> <tag> [platform]"
  echo "Example: $0 docker.io/myuser/awx-ee-api-demo v1 linux/arm64"
  exit 1
fi

IMAGE_REPO="$1"
IMAGE_TAG="$2"
PLATFORM="${3:-${EE_PLATFORM:-linux/arm64}}"
FULL_IMAGE="${IMAGE_REPO}:${IMAGE_TAG}"

cd "$(dirname "$0")/.."

echo "Generating ansible-builder context"
uv run ansible-builder create \
  --file ee/execution-environment.yml \
  --context _build

echo "Building EE image: ${FULL_IMAGE} for platform: ${PLATFORM}"
docker buildx build \
  --platform "${PLATFORM}" \
  -f _build/Dockerfile \
  -t "${FULL_IMAGE}" \
  --load \
  .

echo "Built ${FULL_IMAGE} (${PLATFORM})"
