#!/bin/sh

# Build the sample app
az acr build --registry teacr --image springboot:latest -f Dockerfile.sampleapp .

# Build the load tester
az acr build --registry teacr --image loadtest:latest -f Dockerfile.loadtest .
