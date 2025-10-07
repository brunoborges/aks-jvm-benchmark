# 📊 Benchmark Automation - Complete!

## What Was Created

### 🚀 Main Scripts

1. **`run-redistribution-benchmark.sh`** - Full benchmark suite
   - Tests all 4 redistribution configurations (6x1, 3x2, 2x3, 2x2)
   - Runs both simple JSON and CPU-intensive endpoints
   - Captures resource utilization metrics
   - Saves timestamped results
   - Duration: ~60-80 minutes total

2. **`generate-charts.sh`** - Chart generation wrapper
   - Uses Playwright to automate HdrHistogram plotter
   - Generates comparison charts across all configurations
   - Saves PNG images for presentations
   - Requires Node.js and npm

3. **`test-benchmark.sh`** - Quick test script
   - Tests single configuration with short duration
   - Useful for validating setup
   - Duration: ~2 minutes

### 📦 Chart Generator Package

Located in `chart-generator/`:
- **`package.json`** - Node.js dependencies
- **`generate-charts.js`** - Playwright automation script
- **`README.md`** - Detailed documentation

### 📚 Documentation

- **`BENCHMARK-AUTOMATION.md`** - Complete guide to automated benchmarking

## Quick Start

### 1. Test Your Setup (2 minutes)

```bash
./test-benchmark.sh
```

This validates that:
- Load test pod is running
- Kubernetes deployments work
- Benchmarks execute successfully

### 2. Run Full Benchmark Suite (60-80 minutes)

```bash
./run-redistribution-benchmark.sh
```

This will:
- Test all 4 configurations sequentially
- Run warmup and benchmark cycles
- Save results to `benchmark-results/<timestamp>/`

Example output structure:
```
benchmark-results/20250107-143022/
├── 6by1_simple.txt       # Benchmark results
├── 6by1_cpu.txt
├── 6by1_resources.txt    # Resource usage
├── 3by2_simple.txt
├── 3by2_cpu.txt
├── ... (all configs)
```

### 3. Generate Visualization Charts

```bash
# Install Node.js dependencies (first time only)
cd chart-generator
npm install
npx playwright install chromium
cd ..

# Generate charts
./generate-charts.sh benchmark-results/20250107-143022
```

Charts saved to `benchmark-results/<timestamp>/charts/`:
- `comparison_simple.png` - Simple JSON endpoint comparison
- `comparison_cpu.png` - CPU-intensive endpoint comparison

## How It Works

### Benchmark Flow

```
For each configuration (6x1, 3x2, 2x3, 2x2):
  1. Deploy configuration
  2. Wait for pods to be ready
  3. Run warmup (30s)
  4. Run benchmark - Simple endpoint (3 min)
  5. Run warmup (30s)
  6. Run benchmark - CPU endpoint (3 min)
  7. Capture resource metrics
  8. Clean up deployment
```

### Chart Generation Flow

```
1. Launch headless Chrome browser
2. Navigate to HdrHistogram plotter
3. For each test type (simple, cpu):
   a. Convert wrk output to HdrHistogram format
   b. Upload data for each configuration
   c. Wait for chart to render
   d. Take screenshot
   e. Save PNG image
```

## Key Features

### ✅ Automation Benefits

- **Consistency**: Same parameters across all tests
- **Reproducibility**: Timestamped results for comparison
- **Hands-off**: No manual intervention needed
- **Visualization**: Automated chart generation
- **Documentation**: Complete audit trail

### 📊 Collected Metrics

1. **Latency Distribution**
   - P50, P75, P90, P99, P99.9, P99.99 percentiles
   - Min, max, average, standard deviation

2. **Throughput**
   - Requests/second
   - Transfer rate

3. **Resource Utilization**
   - CPU usage per pod
   - Memory usage per pod

4. **Visual Comparison**
   - Percentile curves across configurations
   - Tail latency visualization

## Configuration

### Benchmark Parameters

Edit `run-redistribution-benchmark.sh`:

```bash
THREADS=10              # Load generator threads
CONNECTIONS=50          # Concurrent connections
WARMUP_DURATION="30s"   # Warmup period
BENCH_DURATION="3m"     # Benchmark duration
RATE=3000              # Target rate (req/s)
TIMEOUT="5s"           # Request timeout
```

### Chart Colors

Edit `chart-generator/generate-charts.js`:

```javascript
const CONFIG_COLORS = {
  '6by1': '#FF6B6B',  // Red
  '3x2': '#4ECDC4',   // Teal
  '2x3': '#45B7D1',   // Blue
  '2x2': '#FFA07A'    // Orange
};
```

## Example Results

### Typical Output Format

```
====================================
Testing Configuration: 6by1
====================================

1. Deploying 6by1 configuration...
   Waiting for pods to be ready... ✅ 6/6 ready

2. Running benchmarks for 6by1...
   
   Test 1: Simple JSON endpoint
   🔥 Warming up for 30s...
   ✅ Warmup complete
   📊 Running benchmark...
   ✅ Benchmark complete

   Test 2: CPU-intensive endpoint
   🔥 Warming up for 30s...
   ✅ Warmup complete
   📊 Running benchmark...
   ✅ Benchmark complete

3. Resource utilization for 6by1:
NAME                      CPU(cores)   MEMORY(bytes)
sampleapp-6by1-xxx-yyy    987m         412Mi
sampleapp-6by1-xxx-zzz    991m         408Mi
...

✅ Completed benchmarks for 6by1
```

### Summary Output

```
📊 Summary:
  
  6by1 - Simple endpoint:
  Requests/sec: 2997.45
  99%   14.23ms

  6by1 - CPU-intensive:
  Requests/sec: 2815.32
  99%   45.67ms
  
  3by2 - Simple endpoint:
  Requests/sec: 2998.12
  99%   13.89ms
  
  ... (all configs)
```

## Integration with Demo

### For Conference Presentations

1. **Pre-conference**: Run full benchmark suite
   ```bash
   ./run-redistribution-benchmark.sh
   ```

2. **Generate charts**: Create visualizations
   ```bash
   ./generate-charts.sh benchmark-results/<timestamp>
   ```

3. **During demo**: Show pre-generated results
   - Display PNG charts on slides
   - Reference specific metrics
   - Show raw data if needed

4. **Live demo option**: Run quick test
   ```bash
   ./test-benchmark.sh
   ```

### Adding to DEMO-FLOW.md

Insert after Part 2 conclusions:

```markdown
## 📊 Bonus: Automated Benchmarking

For comprehensive analysis, use the automated benchmark suite:

\`\`\`bash
# Run all configurations
./run-redistribution-benchmark.sh

# Generate comparison charts
LATEST=$(ls -td benchmark-results/*/ | head -1)
./generate-charts.sh "$LATEST"

# Open charts
open "$LATEST/charts/"
\`\`\`

This provides:
- Consistent testing across all configs
- Detailed latency percentiles
- Visual comparison charts
- Resource utilization metrics
```

## Troubleshooting

### Common Issues

**Load test pod not found:**
```bash
kubectl apply -f kubernetes/loadtest-deployment.yml
kubectl wait --for=condition=ready pod -l app=loadtest --timeout=300s
```

**Node.js not installed:**
```bash
# macOS
brew install node

# Or download from https://nodejs.org/
```

**Playwright browsers missing:**
```bash
cd chart-generator
npx playwright install chromium
```

**Benchmark times out:**
- Increase timeout in script
- Check cluster resources
- Verify no other workloads running

**Charts are blank:**
- Increase wait times in generate-charts.js
- Check that benchmark files contain data
- Verify wrk was run with `-L` flag

## Next Steps

1. **Run a test**: `./test-benchmark.sh`
2. **Review results**: Check the output
3. **Run full suite**: `./run-redistribution-benchmark.sh` (when ready)
4. **Generate charts**: `./generate-charts.sh <results-dir>`
5. **Analyze**: Compare metrics across configurations

## Files Summary

```
New files:
✅ run-redistribution-benchmark.sh      # Main benchmark suite
✅ generate-charts.sh                   # Chart generation wrapper
✅ test-benchmark.sh                    # Quick test script
✅ chart-generator/package.json         # Node.js dependencies
✅ chart-generator/generate-charts.js   # Playwright automation
✅ chart-generator/README.md            # Chart generator docs
✅ BENCHMARK-AUTOMATION.md              # Complete guide
✅ .gitignore                           # Updated for results

Updated files:
✅ README.md                            # Added benchmark section
```

## Support

For questions or issues:
- Check [BENCHMARK-AUTOMATION.md](BENCHMARK-AUTOMATION.md) for detailed docs
- Review [DEMO-FLOW.md](DEMO-FLOW.md) for manual benchmarking
- Check individual script comments

---

**Status**: ✅ Ready to use!  
**Test with**: `./test-benchmark.sh`  
**Full run**: `./run-redistribution-benchmark.sh`

Happy benchmarking! 📊🚀
