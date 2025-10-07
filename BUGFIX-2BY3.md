# 🐛 Bug Fix: 2by3 Configuration

## Problem

The `app-deployment-2by3.yml` file had **incorrect replica count**:

```yaml
# ❌ BEFORE (WRONG)
replicas: 3          # 3 pods
cpu: "3000m"        # 3 CPUs per pod
# Total: 9 CPUs required!
```

**Impact:**
- Kubernetes couldn't schedule all pods (no node has 9 CPUs available)
- 2by3 configuration failed to deploy during benchmarks
- Missing from benchmark results

## Root Cause

Configuration name **"2by3"** means:
- **2 pods** (first number)
- **3 CPUs** per pod (second number)

But the YAML incorrectly had `replicas: 3` instead of `replicas: 2`.

## Solution

Fixed the deployment file:

```yaml
# ✅ AFTER (CORRECT)
replicas: 2          # 2 pods
cpu: "3000m"        # 3 CPUs per pod
memory: "3Gi"       # 3Gi per pod (increased from 1536Mi)
# Total: 6 CPUs (same as other configs)
```

## Resource Allocation Summary

All configurations now correctly allocate **6 CPUs total**:

| Config | Pods | CPU/Pod | Memory/Pod | Total CPU | Total Memory |
|--------|------|---------|------------|-----------|--------------|
| 6x1 | 6 | 1 | 512Mi | 6 | 3Gi |
| 3x2 | 3 | 2 | 1Gi | 6 | 3Gi |
| **2x3** | **2** | **3** | **3Gi** | **6** | **6Gi** |
| 2x2 | 2 | 2 | 1Gi | 4 | 2Gi |

*Note: 2x2 intentionally uses only 4 CPUs as a reduced-resource scenario*

## Verification

Check correct replica counts:
```bash
grep -A 2 "replicas:" kubernetes/redistribution/app-deployment-*.yml | grep "replicas:"
```

Expected output:
```
app-deployment-2by2.yml:  replicas: 2
app-deployment-2by3.yml:  replicas: 2  ← Fixed!
app-deployment-3by2.yml:  replicas: 3
app-deployment-6by1.yml:  replicas: 6
```

## Testing

To test the fix:

```bash
# Deploy 2by3
kubectl apply -f kubernetes/redistribution/app-deployment-2by3.yml

# Wait for ready
kubectl wait --for=condition=ready pod -l version=2by3 --timeout=300s

# Verify all 2 pods are running
kubectl get pods -l version=2by3

# Check resources
kubectl top pods -l version=2by3

# Test connectivity
kubectl exec deployment/loadtest -- curl http://internal-sampleapp-2by3.default.svc.cluster.local:8080/

# Run quick benchmark
./test-benchmark.sh
```

## Files Changed

- ✅ `kubernetes/redistribution/app-deployment-2by3.yml`
  - Changed `replicas: 3` → `replicas: 2`
  - Changed memory from `1536Mi` → `3Gi` (proportional to CPU)

## Re-run Benchmarks

After applying this fix, re-run the full benchmark suite:

```bash
# Full suite (includes 2by3 now)
./run-redistribution-benchmark.sh

# Generate charts
./generate-charts.sh benchmark-results/<timestamp>
```

You should now see all 4 configurations in the results:
- 6by1_simple.txt ✅
- 3by2_simple.txt ✅
- **2by3_simple.txt** ✅ ← Should now be included!
- 2by2_simple.txt ✅

---

**Date Fixed:** October 7, 2025  
**Issue:** Incorrect replica count prevented deployment  
**Status:** ✅ **RESOLVED**
