#!/bin/sh

# Build the sample app
az acr build --registry aksjvmlabacr --image sampleapp:latest -f Dockerfile.sampleapp ../

# Build the load tester
az acr build --registry aksjvmlabacr --image loadtest:latest -f Dockerfile.loadtest ../
