#!/bin/bash

# Quick Test of Benchmark Automation
# Tests a single configuration with short duration

set -e

echo "======================================"
echo "Quick Benchmark Test"
echo "======================================"
echo ""

CONFIG="2by2"
RESULTS_DIR="benchmark-results/test-$(date +%Y%m%d-%H%M%S)"
DURATION="30s"
WARMUP="10s"

echo "Testing configuration: $CONFIG"
echo "Results directory: $RESULTS_DIR"
echo ""

mkdir -p "$RESULTS_DIR"

echo "1. Deploying $CONFIG..."
kubectl apply -f "kubernetes/redistribution/app-deployment-$CONFIG.yml"

echo "2. Waiting for pods..."
sleep 30

echo "3. Checking pod status..."
kubectl get pods -l "version=$CONFIG"

echo ""
echo "4. Running quick benchmark..."
kubectl exec deployment/loadtest -- wrk \
  -t10 -c50 -d$DURATION --timeout 5s -R3000 -L \
  http://internal-sampleapp-$CONFIG.default.svc.cluster.local/json \
  | tee "$RESULTS_DIR/${CONFIG}_test.txt"

echo ""
echo "5. Resource utilization:"
kubectl top pods -l "version=$CONFIG"

echo ""
echo "6. Cleaning up..."
kubectl delete -f "kubernetes/redistribution/app-deployment-$CONFIG.yml"

echo ""
echo "✅ Test complete!"
echo "📁 Results: $RESULTS_DIR"
echo ""
