#!/usr/bin/env bash
# Deploy Life-Level API to Docker Hub (bash version of deploy.ps1).
# Usage: ./deploy.sh   (from anywhere; builds the backend folder this script lives in)
set -euo pipefail

DOCKER_USER="${DOCKER_USER:-mpavlov9905}"
IMAGE_NAME="${IMAGE_NAME:-life-level-api}"

cd "$(dirname "$0")"

version="latest.$(date +%s)"
remote="$DOCKER_USER/$IMAGE_NAME:$version"

echo "Building..."
docker build -t "$IMAGE_NAME" -f Dockerfile .

echo "Tagging..."
docker tag "$IMAGE_NAME" "$remote"

echo "Pushing..."
docker push "$remote"

echo "Done! Image: $remote"
echo "Render image URL: docker.io/$remote"
echo "Set this in Render and redeploy."
