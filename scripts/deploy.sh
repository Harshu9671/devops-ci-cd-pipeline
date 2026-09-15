#!/usr/bin/env bash
# ==============================================================================
# Continuous Deployment (CD) Script
# Pulls an image, replaces the running container, verifies health, and rolls back
# automatically if the replacement cannot start or serve traffic.
# ==============================================================================

set -euo pipefail

IMAGE_NAME="${1:-}"
CONTAINER_NAME="devops-cicd-app"
HOST_PORT="3000"
CONTAINER_PORT="3000"

if [[ -z "$IMAGE_NAME" ]]; then
    echo "❌ Error: Docker image name must be provided as first argument!"
    echo "Usage: ./deploy.sh <docker-username>/<image-name>:<tag>"
    exit 1
fi

if [[ ! "$IMAGE_NAME" =~ ^[^:]+/[^:]+:.+$ ]]; then
    echo "❌ Error: image must use the form <registry-user>/<image>:<tag>"
    exit 1
fi

echo "======================================================================"
echo "🚀 Starting Deployment for: ${IMAGE_NAME}"
echo "======================================================================"

# Step 1: Pull the latest target Docker image
echo "==> Pulling Docker image: ${IMAGE_NAME}..."
docker pull "${IMAGE_NAME}"

# Step 2: Record the current image so a failed release can be rolled back
OLD_IMAGE=""
if docker container inspect "$CONTAINER_NAME" >/dev/null 2>&1; then
    OLD_IMAGE="$(docker container inspect --format '{{.Config.Image}}' "$CONTAINER_NAME")"
    echo "==> Stopping existing container: ${CONTAINER_NAME}..."
    docker stop "${CONTAINER_NAME}" || true
    echo "==> Removing existing container..."
    docker rm "${CONTAINER_NAME}" || true
fi

# Restores the previous image when the new container fails to start or become healthy.
rollback() {
    local reason="$1"
    echo "❌ ${reason}"
    docker rm -f "${CONTAINER_NAME}" >/dev/null 2>&1 || true

    if [[ -n "$OLD_IMAGE" ]]; then
        echo "==> Rolling back to ${OLD_IMAGE}..."
        if ! docker run -d \
            --name "${CONTAINER_NAME}" \
            --restart unless-stopped \
            -p "${HOST_PORT}:${CONTAINER_PORT}" \
            -e NODE_ENV=production \
            -e APP_VERSION="${OLD_IMAGE##*:}" \
            "${OLD_IMAGE}" >/dev/null; then
            echo "❌ Rollback container failed to start."
            exit 1
        fi
        echo "✅ Previous container restored."
    else
        echo "ℹ️  No previous container was available to restore."
    fi
    exit 1
}

# Step 3: Run the new container
echo "==> Starting new container on port ${HOST_PORT}..."
if ! docker run -d \
    --name "${CONTAINER_NAME}" \
    --restart unless-stopped \
    -p "${HOST_PORT}:${CONTAINER_PORT}" \
    -e NODE_ENV=production \
    -e APP_VERSION="${IMAGE_NAME##*:}" \
    "${IMAGE_NAME}" >/dev/null; then
    rollback "New container failed to start."
fi

# Step 4: Health check verification (Smoke Test)
echo "==> Running post-deployment health check..."
MAX_RETRIES=10
RETRY_COUNT=0
HEALTHY=false

while [[ $RETRY_COUNT -lt $MAX_RETRIES ]]; do
    echo "Checking health endpoint (attempt $((RETRY_COUNT + 1))/${MAX_RETRIES})..."
    if curl -sf "http://localhost:${HOST_PORT}/health" > /dev/null; then
        HEALTHY=true
        break
    fi
    RETRY_COUNT=$((RETRY_COUNT + 1))
    sleep 3
done

if [[ "$HEALTHY" = true ]]; then
    echo "======================================================================"
    echo "✅ Deployment Succeeded! Container is healthy and serving traffic."
    echo "🌐 Access URL: http://<EC2-IP>:${HOST_PORT}"
    echo "======================================================================"
else
    echo "======================================================================"
    echo "❌ Health check failed! Inspecting container logs:"
    docker logs --tail 50 "${CONTAINER_NAME}"
    echo "======================================================================"
    rollback "New container did not become healthy."
fi

# Step 5: Clean up dangling / unused old images to save disk on Free Tier
echo "==> Pruning dangling docker images..."
docker image prune -f || true
