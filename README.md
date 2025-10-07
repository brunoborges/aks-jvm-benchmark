# aks-jvm-benchmark

[![Java CI with Maven](https://github.com/brunoborges/aks-jvm-benchmark/actions/workflows/maven.yml/badge.svg)](https://github.com/brunoborges/aks-jvm-benchmark/actions/workflows/maven.yml)

This project is used as an exercise for evaluating different deployment styles (horizontal scaling versus vertical scaling) of JVM workloads on Kubernetes.

## 🚀 Quick Start

### Prerequisites
- Azure subscription with AKS cluster
- Azure Container Registry (ACR)
- `kubectl` configured for your cluster
- Azure CLI installed

### Setup

1. **Configure your ACR** in `cloud/azure/config`:
   ```bash
   ACR_NAME=your-acr-name
   ```

2. **Import external images** (for Azure Policy compliance):
   ```bash
   cd cloud/azure
   ./import-images.sh
   ```

3. **Build and push application images**:
   ```bash
   cd cloud/azure
   ./build-and-push.sh
   ```

4. **Deploy to AKS** - See [DEMO-FLOW.md](DEMO-FLOW.md) for detailed instructions

### Important Notes
- This project is configured for AKS clusters with Azure Policy restrictions
- All images use ACR to comply with container registry policies
- See [AZURE-POLICY.md](AZURE-POLICY.md) for detailed policy compliance information

## 📖 Documentation

- **[DEMO-FLOW.md](DEMO-FLOW.md)**: Complete conference demo script with step-by-step instructions
- **[AZURE-POLICY.md](AZURE-POLICY.md)**: Azure Policy compliance guide and troubleshooting


## Generate HdrHistogram chart
See: http://hdrhistogram.github.io/HdrHistogram/plotFiles.html


### Demo script

First we show difference between GCs and Heap config with the same resource limits (1 CPU, 1 GB RAM).

Then we use the Load Balancer and fire up wrk against them.

#### Comparing different JVM settings

Start the benchmark with this script:

```bash
wrk -t10 -c50 -d5m -R3000 -L http://internal-sampleapp-all.default.svc.cluster.local/json
```

Wait with Prime Factor:

```bash
wrk -t10 -c50 -d5m -R3000 -L  http://internal-sampleapp-all.default.svc.cluster.local/waitWithPrimeFactor?duration=50\&number=927398173993974
```



#### Comparing different resource configurations

Because the k8s Load Balancer only round robin against pods, we must use Nginx for a two-tier load balancing approach.

Delete the gc-related pods, and deploy the `redistribution` pods, followed by `nginx` pod.



Start the benchmark with this script:

```bash
wrk -t10 -c50 -d5m -R3000 -L http://internal-nginx.default.svc.cluster.local/json
```

Wait with Prime Factor:

```bash
wrk -t10 -c50 -d5m -R3000 -L  http://internal-nginx.default.svc.cluster.local/waitWithPrimeFactor?duration=50\&number=927398173993974
```

