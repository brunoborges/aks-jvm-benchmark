# Conference Demo Flow: Java/JVM Performance on Kubernetes
## AKS JVM Benchmark Demo

> **Duration**: 20-25 minutes  
> **Audience**: Developers, DevOps engineers, Platform engineers  
> **Focus**: Comparing JVM configurations and resource allocation strategies on Kubernetes

---

## 🎯 Demo Objectives

1. **Part 1**: Compare different JVM GC configurations with identical resource limits
2. **Part 2**: Compare different resource distribution strategies (horizontal vs vertical scaling)
3. Show real-time performance metrics and Application Insights integration

---

## 📋 Pre-Demo Checklist

### Before the Conference
- [ ] AKS cluster is up and running
- [ ] ACR (Azure Container Registry) has the latest images
- [ ] Run `cloud/azure/import-images.sh` to import external images
- [ ] Run `cloud/azure/build-and-push.sh` to build application images
- [ ] Application Insights is configured and accessible
- [ ] `kubectl` context is set to your AKS cluster
- [ ] All scripts have execute permissions
- [ ] Test the full flow at least once

### Verify Setup
```bash
# Check cluster connection
kubectl get nodes

# Check if images are available in ACR
az acr repository list --name techxchange2025acr --output table

# Should show: nginx, sampleapp, loadtest

# Verify no deployments are running
kubectl get deployments
kubectl get pods
```

### Clean Slate (if needed)
```bash
# Remove all previous deployments
cd kubernetes/deployments
./undeploy-all.sh

cd ../redistribution
./undeploy-all.sh

kubectl get pods  # Should show no sampleapp pods
```

---

## 🎬 Part 1: Comparing JVM GC Configurations

### Story
> "Let's start by comparing three different JVM garbage collection strategies, all running with the **exact same resource constraints**: 1 CPU and 512MB RAM. We'll see how the choice of GC can dramatically impact performance."

### Step 1.1: Deploy Applications with Different GC Configurations

```bash
cd kubernetes/deployments

# Show the deployment files to the audience
cat app-deployment-ergonomics.yml | grep -A 5 "name: sampleapp"
cat app-deployment-g1gc.yml | grep -A 5 "name: sampleapp"
cat app-deployment-pgc.yml | grep -A 5 "name: sampleapp"

# Deploy all three configurations
./deploy-all.sh
```

**Talking Points:**
- **Ergonomics**: Let the JVM decide (default behavior)
- **G1GC**: Optimized for balanced throughput and latency
- **Parallel GC**: Optimized for maximum throughput

### Step 1.2: Wait for Pods to be Ready

```bash
# Watch pods come up
kubectl get pods -w

# Once all are running (Ctrl+C to stop watching)
kubectl get pods | grep sampleapp
```

### Step 1.3: Inspect Each Deployment

```bash
# Check what GC each pod is actually using
kubectl exec -it deployment/sampleapp-ergonomics -- curl localhost:8080/inspect
kubectl exec -it deployment/sampleapp-g1gc -- curl localhost:8080/inspect
kubectl exec -it deployment/sampleapp-pgc -- curl localhost:8080/inspect
```

**Talking Points:**
- Point out the "Running GC" field in the response
- Show available processors and memory settings
- Highlight that all three have identical resource limits

### Step 1.4: Deploy Load Test Pod

```bash
# Deploy the load tester
kubectl apply -f ../loadtest-deployment.yml

# Get the load test pod name
kubectl get pods | grep loadtest
```

### Step 1.5: Run Benchmark - Simple JSON Endpoint

```bash
# Get into the load test pod
kubectl exec -it deployment/loadtest -- /bin/bash

# Inside the pod, run the benchmark against all three
wrk -t10 -c50 -d2m -R3000 -L http://internal-sampleapp-all.default.svc.cluster.local/json

# Exit the pod
exit
```

**Talking Points:**
- This is a simple endpoint that returns JSON (low CPU)
- Rate-limited to 3000 requests/second
- 10 threads, 50 connections, 2 minutes duration
- Watch the latency percentiles (p50, p99, p99.9)

### Step 1.6: Run Benchmark - CPU-Intensive Workload

```bash
# Get back into the load test pod
kubectl exec -it deployment/loadtest -- /bin/bash

# Run CPU-intensive benchmark (prime factorization + network wait)
wrk -t10 -c50 -d2m -R3000 -L http://internal-sampleapp-all.default.svc.cluster.local/waitWithPrimeFactor?duration=50\&number=927398173993974

# Exit the pod
exit
```

**Talking Points:**
- This endpoint does both CPU work (prime factorization) AND simulates network wait
- This represents a more realistic workload
- Notice how latencies differ between GC configurations
- P99 and P99.9 latencies are critical for user experience

### Step 1.7: Check Application Insights (Optional)

Open Application Insights in the Azure Portal and show:
- Request rates across the three deployments
- Response times comparison
- GC activity (if profiler is enabled)

**Talking Points:**
- Application Insights gives us visibility into production behavior
- Each deployment has a different role name for easy filtering

---

## 🎬 Part 2: Resource Distribution Strategies

### Story
> "Now let's look at a different question: Given the same total resources, is it better to have more pods with fewer resources (horizontal scaling) or fewer pods with more resources (vertical scaling)?"

### Step 2.1: Clean Up Previous Deployments

```bash
cd kubernetes/deployments
./undeploy-all.sh

# Verify they're gone
kubectl get pods | grep sampleapp
```

### Step 2.2: Explain the Redistribution Scenarios

**Show the audience the different configurations:**

```bash
cd ../redistribution

# 6 pods with 1 CPU, 1GB RAM each = 6 CPUs, 6GB total
cat app-deployment-6by1.yml | grep -A 10 resources

# 3 pods with 2 CPUs, 2GB RAM each = 6 CPUs, 6GB total
cat app-deployment-3by2.yml | grep -A 10 resources

# 2 pods with 3 CPUs, 3GB RAM each = 6 CPUs, 6GB total
cat app-deployment-2by3.yml | grep -A 10 resources

# 2 pods with 2 CPUs, 2GB RAM each = 4 CPUs, 4GB total (smaller baseline)
cat app-deployment-2by2.yml | grep -A 10 resources
```

**Talking Points:**
- All configurations use Parallel GC for consistency
- Total cluster resources remain the same
- We're testing: **many small pods vs few large pods**

### Step 2.3: Deploy All Redistribution Configurations

```bash
./deploy-all.sh

# Watch them come up
kubectl get pods -w
```

### Step 2.4: Deploy Nginx Load Balancer

**Explain the Problem:**
> "Kubernetes service load balancing is basic round-robin at the connection level. For more sophisticated load balancing, we need a two-tier approach with Nginx."

```bash
cd ../two-tier-lb

# Show the nginx configuration
cat nginx-config-redistribution.yml

# Deploy nginx
kubectl apply -f nginx-config-redistribution.yml
kubectl apply -f nginx-deployment-redistribution.yml

# Wait for nginx to be ready
kubectl get pods | grep nginx
```

**Note**: All images are pre-imported to ACR for Azure Policy compliance (see [AZURE-POLICY.md](AZURE-POLICY.md))

### Step 2.5: Run Benchmarks Against Each Configuration

```bash
# Get into the load test pod
kubectl exec -it deployment/loadtest -- /bin/bash

# Benchmark through Nginx (which distributes across all configs)
wrk -t10 -c50 -d2m -R3000 -L http://internal-nginx.default.svc.cluster.local/json

# For CPU-intensive workload
wrk -t10 -c50 -d2m -R3000 -L http://internal-nginx.default.svc.cluster.local/waitWithPrimeFactor?duration=50\&number=927398173993974

exit
```

**Alternative: Benchmark Individual Configurations**

```bash
# Test each configuration separately
kubectl exec -it deployment/loadtest -- /bin/bash

# 6x1 configuration
wrk -t10 -c50 -d1m -R3000 -L http://internal-sampleapp-6by1.default.svc.cluster.local/waitWithPrimeFactor?duration=50\&number=927398173993974

# 3x2 configuration
wrk -t10 -c50 -d1m -R3000 -L http://internal-sampleapp-3by2.default.svc.cluster.local/waitWithPrimeFactor?duration=50\&number=927398173993974

# 2x3 configuration
wrk -t10 -c50 -d1m -R3000 -L http://internal-sampleapp-2by3.default.svc.cluster.local/waitWithPrimeFactor?duration=50\&number=927398173993974

# 2x2 configuration
wrk -t10 -c50 -d1m -R3000 -L http://internal-sampleapp-2by2.default.svc.cluster.local/waitWithPrimeFactor?duration=50\&number=927398173993974

exit
```

### Step 2.6: Analyze Results

**Key Metrics to Compare:**
- **Throughput**: Requests completed per second
- **P50 Latency**: Median response time
- **P99 Latency**: 99th percentile (critical for user experience)
- **P99.9 Latency**: Tail latency
- **Resource Utilization**: Check with `kubectl top pods`

```bash
# Check resource utilization
kubectl top pods | grep sampleapp
```

### Step 2.7: Application Insights Comparison

Open Application Insights and show:
- Filter by role name (6BY1, 3BY2, 2BY3, 2BY2)
- Compare request rates
- Compare average response times
- Show any error rates

---

## 🎤 Key Takeaways & Conclusions

### Part 1 Findings (GC Comparison)
- **Parallel GC**: Best for batch processing and high throughput
- **G1GC**: More predictable latencies, better for user-facing apps
- **Ergonomics**: Depends on heap size; may choose Serial, G1, or Parallel

### Part 2 Findings (Resource Distribution)
- **Fewer large pods (vertical)**: 
  - Better for CPU-intensive workloads
  - JVM has more memory for heap and GC
  - Fewer context switches
  
- **More small pods (horizontal)**:
  - Better fault tolerance
  - More even distribution across nodes
  - Better for bursty traffic

### General Insights
1. **Right-sizing matters**: Don't over-provision or under-provision
2. **Test your workload**: No one-size-fits-all solution
3. **Monitor everything**: Application Insights + Kubernetes metrics
4. **Consider your traffic pattern**: Steady vs bursty
5. **GC choice impacts latency**: Especially at P99 and P99.9

---

## 🧹 Post-Demo Cleanup

```bash
# Clean up all deployments
cd kubernetes/deployments
./undeploy-all.sh

cd ../redistribution
./undeploy-all.sh

# Remove load balancer
kubectl delete -f ../two-tier-lb/nginx-deployment-redistribution.yml
kubectl delete -f ../two-tier-lb/nginx-config-redistribution.yml

# Remove load test
kubectl delete -f ../loadtest-deployment.yml

# Verify cleanup
kubectl get pods
kubectl get services
kubectl get deployments
```

---

## 🚨 Troubleshooting Tips

### Pods Not Starting
```bash
# Check pod status
kubectl describe pod <pod-name>

# Check logs
kubectl logs <pod-name>

# Check events
kubectl get events --sort-by='.lastTimestamp'
```

### Can't Connect to Service
```bash
# Verify service exists
kubectl get svc

# Check endpoints
kubectl get endpoints

# Test from within cluster
kubectl run debug --rm -it --image=alpine -- sh
apk add curl
curl http://internal-sampleapp-all.default.svc.cluster.local/
```

### Benchmark Pod Issues
```bash
# Rebuild if needed
docker build -t loadtest:latest -f containers/Dockerfile.loadtest .

# Push to ACR
az acr build --registry techxchange2025acr --image loadtest:latest -f containers/Dockerfile.loadtest .
```

### Performance Not as Expected
- Check node resources: `kubectl top nodes`
- Check pod resources: `kubectl top pods`
- Verify no resource contention from other workloads
- Check Application Insights for errors

### Azure Policy Blocking Container Images
```bash
# Error: Container image has not been allowed
# This shouldn't happen if you ran import-images.sh, but if it does:

# Solution 1: Use the provided script
cd cloud/azure
./import-images.sh

# Solution 2: Manual import
az acr import --name techxchange2025acr \
  --source docker.io/library/nginx:1.29.1 \
  --image nginx:1.29.1

# Solution 3: Check policy assignments
az policy assignment list \
  --query "[?contains(displayName, 'Kubernetes')].{Name:displayName}" \
  -o table

# For more details, see AZURE-POLICY.md
```

---

## 📊 Slide Recommendations

### Opening Slide
- Title: "Java Performance on Kubernetes: GC and Resource Strategy Comparison"
- Your info + conference name

### Architecture Diagram
- Show: Spring Boot app → AKS → Application Insights
- Highlight: Load tester, Nginx LB, multiple pod configurations

### GC Comparison Slide
- Table comparing Parallel, G1, Serial, ZGC
- When to use each

### Resource Distribution Slide
- Visual: 6x1 vs 3x2 vs 2x3 vs 2x2
- Total resources calculation

### Results Slide (prepare with actual data)
- Charts showing latency percentiles
- Throughput comparison

### Closing Slide
- Key takeaways
- Call to action: "Profile your workload, test configurations, monitor continuously"
- GitHub repo link

---

## 🎯 Presenter Notes

### Time Management
- **Intro + Setup explanation**: 3-5 minutes
- **Part 1 (GC comparison)**: 8-10 minutes
- **Part 2 (Resource distribution)**: 8-10 minutes
- **Q&A**: 5 minutes

### Engagement Tips
1. Ask audience about their experience with Java/Kubernetes
2. Poll: "Who has experienced GC issues in production?"
3. Show live metrics changing during benchmark
4. Have backup screenshots in case of technical issues

### Demo Safety
- **Always have a backup**: Screenshots/videos of successful runs
- **Test the full flow** the morning of your talk
- **Have a kill switch**: Know how to quickly recover if something breaks
- **Network contingency**: Can you run everything locally if venue Wi-Fi fails?

### Backup Plan
If live demo fails:
1. Use pre-recorded video of the demo
2. Walk through pre-captured Application Insights screenshots
3. Focus on the code and configuration explanations
4. Share lessons learned from previous test runs

---

## 📚 Additional Resources

- GitHub Repo: https://github.com/brunoborges/aks-jvm-benchmark
- Azure Kubernetes Service Docs: https://docs.microsoft.com/azure/aks/
- JVM Ergonomics: https://docs.oracle.com/en/java/javase/17/gctuning/
- Application Insights: https://docs.microsoft.com/azure/azure-monitor/app/app-insights-overview

---

## ✅ Final Checks (Night Before)

- [ ] AKS cluster is running and accessible
- [ ] All container images pushed to ACR
- [ ] Application Insights connection string is valid
- [ ] `kubectl` authentication works
- [ ] Load test pod can reach services
- [ ] Laptop fully charged + power adapter ready
- [ ] Presentation clicker batteries checked
- [ ] Demo scripts have execute permissions
- [ ] Browser bookmarks for Application Insights dashboard
- [ ] Backup screenshots/videos ready
- [ ] Water bottle nearby 😊

---

**Good luck with your conference presentation! 🚀**
