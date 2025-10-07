#!/bin/bash

# Import external images to Azure Container Registry
# This ensures compliance with Azure Policy that restricts container registries

set -e

source config

echo "======================================"
echo "Importing External Images to ACR"
echo "ACR Name: $ACR_NAME"
echo "======================================"

# Import nginx image
echo ""
echo "📦 Importing nginx:1.29.1..."
az acr import \
  --name $ACR_NAME \
  --source docker.io/library/nginx:1.29.1 \
  --image nginx:1.29.1 \
  --force

echo "✅ nginx:1.29.1 imported successfully"

# Verify imported images
echo ""
echo "======================================"
echo "Verifying imported images in ACR..."
echo "======================================"
az acr repository list --name $ACR_NAME --output table

echo ""
echo "✅ All images imported successfully!"
echo ""
echo "Note: Application images (sampleapp, loadtest) should be built separately using:"
echo "  ./build-and-push.sh"
