#!/bin/sh

for file in ./*.yml; do kubectl apply -f "$file" --force; done

kubectl rollout restart deployment/sampleapp-ergonomics
kubectl rollout restart deployment/sampleapp-g1gc
kubectl rollout restart deployment/sampleapp-pgc

kubectl get pods
