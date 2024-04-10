#!/bin/sh

for file in ./*.yml; do kubectl delete  --wait=false -f "$file"; done

kubectl get pods
