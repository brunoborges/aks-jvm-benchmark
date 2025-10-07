# 🚀 Benchmark Scripts - Quick Reference

## Scripts Overview

| Script | Duration | Purpose |
|--------|----------|---------|
| `test-benchmark.sh` | ~2 min | Quick test, validates setup |
| `run-redistribution-benchmark.sh` | ~60-80 min | Full suite, all 4 configs |
| `generate-charts.sh <dir>` | ~2 min | Generate visualization charts |
| `verify-compliance.sh` | ~1 min | Check Azure Policy compliance |

## Quick Commands

### Test Setup
```bash
./test-benchmark.sh
```

### Run Full Benchmark
```bash
./run-redistribution-benchmark.sh
```

### Generate Charts
```bash
# First time: Install Node.js dependencies
cd chart-generator && npm install && npx playwright install chromium && cd ..

# Generate charts from results
./generate-charts.sh benchmark-results/20250107-143022
```

### Check Results
```bash
# List results
ls -lt benchmark-results/

# View summary
cat benchmark-results/20250107-143022/*_simple.txt | grep "Requests/sec:"

# View charts
open benchmark-results/20250107-143022/charts/
```

## Service URLs

All services use port **8080**:

```bash
# 6x1 configuration
http://internal-sampleapp-6by1.default.svc.cluster.local:8080

# 3x2 configuration
http://internal-sampleapp-3by2.default.svc.cluster.local:8080

# 2x3 configuration
http://internal-sampleapp-2by3.default.svc.cluster.local:8080

# 2x2 configuration
http://internal-sampleapp-2by2.default.svc.cluster.local:8080
```

## Endpoints Tested

### Simple JSON
```
/json
```
Low CPU, tests basic throughput

### CPU-Intensive
```
/waitWithPrimeFactor?duration=50&number=927398173993974
```
Prime factorization + network wait, tests under load

## Default Parameters

```bash
THREADS=10              # Load generator threads
CONNECTIONS=50          # Concurrent connections
WARMUP_DURATION="30s"   # Warmup period
BENCH_DURATION="3m"     # Benchmark duration
RATE=3000              # Target rate (req/s)
TIMEOUT="5s"           # Request timeout
```

## Manual Benchmark

```bash
# Deploy
kubectl apply -f kubernetes/redistribution/app-deployment-6by1.yml

# Wait for ready
kubectl wait --for=condition=ready pod -l version=6by1 --timeout=300s

# Verify service
kubectl get endpoints internal-sampleapp-6by1

# Test connectivity
kubectl exec deployment/loadtest -- curl http://internal-sampleapp-6by1.default.svc.cluster.local:8080/

# Run benchmark
kubectl exec deployment/loadtest -- wrk \
  -t10 -c50 -d3m --timeout 5s -R3000 -L \
  http://internal-sampleapp-6by1.default.svc.cluster.local:8080/json

# Clean up
kubectl delete -f kubernetes/redistribution/app-deployment-6by1.yml
```

## Troubleshooting

### Service Not Accessible
```bash
# Check service
kubectl get service internal-sampleapp-6by1

# Check endpoints
kubectl get endpoints internal-sampleapp-6by1

# Check from pod
kubectl exec deployment/loadtest -- curl -v \
  http://internal-sampleapp-6by1.default.svc.cluster.local:8080/
```

### Pods Not Ready
```bash
# Check status
kubectl get pods -l version=6by1

# Describe pod
kubectl describe pod <pod-name>

# Check logs
kubectl logs <pod-name>
```

### Load Test Pod Missing
```bash
kubectl apply -f kubernetes/loadtest-deployment.yml
kubectl wait --for=condition=ready pod -l app=loadtest --timeout=300s
```

## Key Metrics

From benchmark output:

```
Requests/sec: 2999.89       # Throughput
Latency Distribution:
  50%    1.85ms              # Median
  99%   15.31ms              # P99 (critical!)
  99.9% 23.76ms              # Tail latency
```

## Configuration Resources

| Config | Pods | CPU/Pod | Memory/Pod | Total CPU | Total Memory |
|--------|------|---------|------------|-----------|--------------|
| 6x1 | 6 | 1 | 512Mi | 6 | 3Gi |
| 3x2 | 3 | 2 | 1Gi | 6 | 3Gi |
| 2x3 | 2 | 3 | 3Gi | 6 | 6Gi |
| 2x2 | 2 | 2 | 1Gi | 4 | 2Gi |

## Files Structure

```
benchmark-results/
└── 20250107-143022/          # Timestamp
    ├── 6by1_simple.txt       # Simple endpoint results
    ├── 6by1_cpu.txt          # CPU-intensive results
    ├── 6by1_resources.txt    # Resource usage
    ├── 3by2_simple.txt
    ├── 3by2_cpu.txt
    ├── 3by2_resources.txt
    ├── 2by3_simple.txt
    ├── 2by3_cpu.txt
    ├── 2by3_resources.txt
    ├── 2by2_simple.txt
    ├── 2by2_cpu.txt
    ├── 2by2_resources.txt
    └── charts/
        ├── comparison_simple.png
        └── comparison_cpu.png
```

## Common Issues

| Issue | Quick Fix |
|-------|-----------|
| Connection timeout | Wait longer, check endpoints |
| Service not found | Check deployment applied |
| Load test pod missing | Deploy loadtest pod |
| Charts empty | Check Node.js installed |
| High latency | Check cluster resources |

## Documentation

- **BENCHMARK-AUTOMATION.md** - Full guide
- **BENCHMARK-FIXES.md** - Troubleshooting fixes
- **DEMO-FLOW.md** - Manual demo script
- **chart-generator/README.md** - Chart generation

## Pre-Demo Checklist

- [ ] AKS cluster running
- [ ] Load test pod deployed
- [ ] Test script runs successfully: `./test-benchmark.sh`
- [ ] Node.js installed (for charts)
- [ ] Playwright browsers installed
- [ ] No other workloads consuming resources

## Support

For issues: Review **BENCHMARK-FIXES.md** and **BENCHMARK-AUTOMATION.md**

---

**Quick Start**: `./test-benchmark.sh` → `./run-redistribution-benchmark.sh` → `./generate-charts.sh <results-dir>`
