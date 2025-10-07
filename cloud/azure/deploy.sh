#!/bin/sh

source config

# Build the sample app
az acr build --registry $ACR_NAME --image sampleapp:latest -f Dockerfile.sampleapp ../

# Build the load tester
az acr build --registry $ACR_NAME --image loadtest:latest -f Dockerfile.loadtest ../


# Deploy sampleapp container to AKS
kubectl apply -f sampleapp.yaml

# Deploy loadtester container to AKS
kubectl apply -f loadtest.yaml

# Deploy ingress controller to AKS
kubectl apply -f ingress.yaml

# Deploy ingress rules to AKS
kubectl apply -f ingress-rules.yaml

# Deploy autoscaler to AKS
kubectl apply -f autoscaler.yaml

# Deploy autoscaler rules to AKS
kubectl apply -f autoscaler-rules.yaml
