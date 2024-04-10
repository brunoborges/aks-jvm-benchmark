#!/bin/sh

for file in ./*.yml; do kubectl apply -f "$file" --force; done

kubectl rollout restart deployment/sampleapp-2by2
kubectl rollout restart deployment/sampleapp-2by3
kubectl rollout restart deployment/sampleapp-3by2
kubectl rollout restart deployment/sampleapp-6by1

kubectl get pods
