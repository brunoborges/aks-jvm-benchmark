#!/bin/bash

# Build and push application images to Azure Container Registry

set -e

source config

echo "======================================"
echo "Building Application Images"
echo "ACR Name: $ACR_NAME"
echo "======================================"

# Navigate to containers directory
cd ../../containers

# Build the sample app
echo ""
echo "🔨 Building sampleapp..."
az acr build \
  --registry $ACR_NAME \
  --image sampleapp:latest \
  --file Dockerfile.sampleapp \
  ../

echo "✅ sampleapp built and pushed successfully"

# Build the load tester
echo ""
echo "🔨 Building loadtest..."
az acr build \
  --registry $ACR_NAME \
  --image loadtest:latest \
  --file Dockerfile.loadtest \
  ../

echo "✅ loadtest built and pushed successfully"

# Return to original directory
cd ../cloud/azure

# List all images in ACR
echo ""
echo "======================================"
echo "All images in ACR:"
echo "======================================"
az acr repository list --name $ACR_NAME --output table

echo ""
echo "✅ All application images built and pushed successfully!"
