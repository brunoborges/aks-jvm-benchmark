#!/bin/sh

# Build the sample app
az acr build --registry devsummit2024 --image sampleapp:latest -f Dockerfile.sampleapp ../

# Build the load tester
az acr build --registry devsummit2024 --image loadtest:latest -f Dockerfile.loadtest ../
