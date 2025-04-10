#!/bin/sh

source ../cloud/azure/config

# Build the sample app
az acr build --registry $ACR_NAME --image sampleapp:latest -f Dockerfile.sampleapp ../

# Build the load tester
az acr build --registry $ACR_NAME --image loadtest:latest -f Dockerfile.loadtest ../
