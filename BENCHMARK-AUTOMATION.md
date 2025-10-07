# Benchmark Automation

This directory contains tools for automated benchmarking and visualization of the redistribution scenarios.

## Overview

The benchmark suite automatically:
1. Deploys each redistribution configuration (6x1, 3x2, 2x3, 2x2)
2. Warms up the application
3. Runs benchmarks against two endpoints:
   - Simple JSON endpoint (low CPU)
   - CPU-intensive endpoint (prime factorization)
4. Collects resource utilization metrics
5. Generates HdrHistogram charts for visualization

## Prerequisites

### For Running Benchmarks
- AKS cluster with deployed load test pod
- `kubectl` configured and authenticated
- Bash shell

### For Generating Charts
- Node.js 18+ installed
- npm package manager

## Quick Start

### 1. Run the Full Benchmark Suite

```bash
./run-redistribution-benchmark.sh
```

This will:
- Test all four redistribution configurations
- Run warmup and benchmark cycles
- Save results to timestamped directory
- Take approximately 60-80 minutes total

### 2. Generate Visualization Charts

```bash
./generate-charts.sh benchmark-results/20250107-143022
```

Replace the directory name with your actual results directory.

This will:
- Launch a headless browser
- Navigate to HdrHistogram plotter
- Upload benchmark data
- Generate comparison charts
- Save PNG images in the charts subdirectory

## Configuration

### Benchmark Parameters

Edit `run-redistribution-benchmark.sh` to customize:

```bash
THREADS=10              # Number of load generator threads
CONNECTIONS=50          # Concurrent connections
WARMUP_DURATION="30s"   # Warmup period
BENCH_DURATION="3m"     # Benchmark duration
RATE=3000              # Target request rate (req/s)
TIMEOUT="5s"           # Request timeout
```

### Endpoints Tested

1. **Simple JSON** (`/json`)
   - Lightweight endpoint
   - Tests basic throughput

2. **CPU-Intensive** (`/waitWithPrimeFactor?duration=50&number=927398173993974`)
   - Prime factorization + network wait
   - Tests under computational load

## Output Structure

```
benchmark-results/
└── 20250107-143022/          # Timestamp
    ├── 6by1_simple.txt       # Raw benchmark output
    ├── 6by1_cpu.txt
    ├── 6by1_resources.txt    # Resource utilization
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
        ├── comparison_simple.png  # Chart comparing all configs
        └── comparison_cpu.png     # Chart for CPU-intensive tests
```

## Understanding Results

### Key Metrics

From the raw `.txt` files:

```
Requests/sec: 2847.23              # Throughput
Latency Distribution:
  50%    12.45ms                    # Median latency
  75%    18.32ms                    # 75th percentile
  90%    24.67ms                    # 90th percentile
  99%    45.89ms                    # 99th percentile (critical!)
```

### Resource Utilization

From `*_resources.txt` files:
- CPU usage per pod
- Memory usage per pod
- Helps identify resource constraints

### HdrHistogram Charts

The generated PNG charts show:
- Latency percentiles across all configurations
- Tail latency behavior (p99, p99.9, p99.99)
- Visual comparison of different resource distributions

## Manual Benchmark Run

If you want to test a single configuration:

```bash
# Deploy the configuration
kubectl apply -f kubernetes/redistribution/app-deployment-6by1.yml

# Wait for pods to be ready
kubectl wait --for=condition=ready pod -l version=6by1 --timeout=300s

# Run benchmark from load test pod
kubectl exec -it deployment/loadtest -- wrk \
  -t10 -c50 -d3m --timeout 5s -R3000 -L \
  http://internal-sampleapp-6by1.default.svc.cluster.local/json

# Clean up
kubectl delete -f kubernetes/redistribution/app-deployment-6by1.yml
```

## Troubleshooting

### Benchmark Script Issues

**Pods not becoming ready:**
```bash
# Check pod status
kubectl get pods -l version=6by1

# Check events
kubectl describe pod <pod-name>

# Check logs
kubectl logs <pod-name>
```

**Service connection timeout:**
```bash
# Check service exists
kubectl get service internal-sampleapp-6by1

# Check endpoints are populated
kubectl get endpoints internal-sampleapp-6by1

# Test connectivity from load test pod
kubectl exec deployment/loadtest -- curl -v http://internal-sampleapp-6by1.default.svc.cluster.local:8080/

# Check DNS resolution
kubectl exec deployment/loadtest -- nslookup internal-sampleapp-6by1.default.svc.cluster.local
```

**Script skips configuration:**
- Check error messages - service may not be accessible
- Verify no NetworkPolicies blocking traffic
- Check cluster has sufficient resources
- Review BENCHMARK-FIXES.md for detailed troubleshooting

**Load test pod not found:**
```bash
# Deploy load test pod
kubectl apply -f kubernetes/loadtest-deployment.yml

# Verify it's running
kubectl get pods | grep loadtest
```

### Chart Generation Issues

**Node.js not found:**
```bash
# Install Node.js from https://nodejs.org/
# Or use a version manager like nvm
brew install node  # macOS
```

**Playwright installation fails:**
```bash
# Install Playwright browsers manually
cd chart-generator
npx playwright install chromium
```

**Empty or missing charts:**
- Check that benchmark results contain latency data
- Verify the results directory path is correct
- Look for error messages in the console output

### Data Quality Issues

**Inconsistent results:**
- Ensure cluster has stable resources
- Check for other workloads consuming resources
- Increase warmup duration
- Run multiple iterations

**High error rates:**
- Increase timeout value
- Reduce rate limit
- Check pod logs for application errors

## Advanced Usage

### Custom Test Scenarios

Create a custom benchmark script:

```bash
#!/bin/bash
# custom-benchmark.sh

# Deploy specific configuration
kubectl apply -f kubernetes/redistribution/app-deployment-3by2.yml

# Custom benchmark parameters
wrk -t20 -c100 -d5m --timeout 10s -R5000 -L \
  http://internal-sampleapp-3by2.default.svc.cluster.local/json \
  > results/custom_test.txt

# Generate chart
./generate-charts.sh results/
```

### Continuous Benchmarking

Set up a cron job for regular benchmarks:

```bash
# Run benchmarks daily at 2 AM
0 2 * * * cd /path/to/aks-jvm-benchmark && ./run-redistribution-benchmark.sh >> benchmark.log 2>&1
```

### Integration with CI/CD

Add to your GitHub Actions or Azure Pipelines:

```yaml
- name: Run Benchmarks
  run: |
    ./run-redistribution-benchmark.sh
    
- name: Generate Charts
  run: |
    LATEST_RESULTS=$(ls -td benchmark-results/*/ | head -1)
    ./generate-charts.sh "$LATEST_RESULTS"
    
- name: Upload Artifacts
  uses: actions/upload-artifact@v3
  with:
    name: benchmark-results
    path: benchmark-results/
```

## Performance Tips

1. **Minimize cluster noise**: Ensure no other workloads running
2. **Network stability**: Test during low-traffic periods
3. **Longer benchmarks**: Increase duration for stable metrics
4. **Multiple runs**: Average results across 3-5 runs
5. **Resource isolation**: Use node selectors or taints/tolerations

## References

- [wrk2 Documentation](https://github.com/giltene/wrk2)
- [HdrHistogram](http://hdrhistogram.org/)
- [Percentile Interpretation](http://hdrhistogram.github.io/HdrHistogram/)
- [Load Testing Best Practices](https://kubernetes.io/docs/tasks/debug/debug-cluster/resource-metrics-pipeline/)

## Support

For issues or questions:
- Check the main [README.md](../README.md)
- Review [DEMO-FLOW.md](../DEMO-FLOW.md) for manual steps
- Open an issue on GitHub
