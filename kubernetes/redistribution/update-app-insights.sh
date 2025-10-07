#!/bin/bash

# Script to update Application Insights connection string and restart all deployments

set -e

echo "======================================"
echo "Update Application Insights ConfigMap"
echo "======================================"
echo ""

# Apply the ConfigMap
echo "📝 Applying ConfigMap..."
kubectl apply -f kubernetes/redistribution/app-insights-config.yml
echo "✅ ConfigMap updated"
echo ""

# Restart all deployments to pick up the new value
echo "🔄 Restarting deployments..."
kubectl rollout restart deployment/sampleapp-2by2
kubectl rollout restart deployment/sampleapp-2by3
kubectl rollout restart deployment/sampleapp-3by2
kubectl rollout restart deployment/sampleapp-6by1
echo "✅ All deployments restarted"
echo ""

# Wait for rollouts to complete
echo "⏳ Waiting for rollouts to complete..."
kubectl rollout status deployment/sampleapp-2by2
kubectl rollout status deployment/sampleapp-2by3
kubectl rollout status deployment/sampleapp-3by2
kubectl rollout status deployment/sampleapp-6by1
echo ""

echo "======================================"
echo "✅ Update complete!"
echo "======================================"
echo ""
echo "All deployments are now using the updated Application Insights connection string."
