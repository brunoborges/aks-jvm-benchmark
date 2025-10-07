# Benchmark Script Fixes Applied

## Issues Fixed

### 1. Connection Timeout to Service

**Problem**: 
```
unable to connect to internal-sampleapp-6by1.default.svc.cluster.local:http Connection timed out
```

**Root Causes**:
1. Missing port specification in URL (should be `:8080`)
2. Service endpoints not fully ready when benchmark starts
3. No connectivity verification before running benchmark

**Solutions Applied**:

#### A. Added Port Specification
Changed from:
```bash
SERVICE_URL="http://internal-sampleapp-$CONFIG.default.svc.cluster.local"
```

To:
```bash
SERVICE_URL="http://internal-sampleapp-$CONFIG.default.svc.cluster.local:8080"
```

#### B. Enhanced Wait Logic
Added service endpoint checking:
```bash
wait_for_pods() {
    # ... existing pod checks ...
    
    # NEW: Wait for service endpoints
    echo -n "   Waiting for service to be ready..."
    for i in {1..60}; do
        ENDPOINTS=$(kubectl get endpoints "internal-sampleapp-$label" -o jsonpath='{.subsets[*].addresses[*].ip}' 2>/dev/null | wc -w | tr -d ' ')
        if [ "$ENDPOINTS" -ge "1" ]; then
            echo -e " ${GREEN}✅ Service ready${NC}"
            sleep 10  # Extra stabilization time
            return 0
        fi
        echo -n "."
        sleep 5
    done
}
```

#### C. Added Connectivity Verification
Before running benchmarks:
```bash
echo "   Verifying service connectivity..."
if ! kubectl exec deployment/loadtest -- curl -s --connect-timeout 5 "$SERVICE_URL/" > /dev/null 2>&1; then
    echo -e "   ${YELLOW}⚠️  Service may not be fully ready, waiting 30s more...${NC}"
    sleep 30
    if ! kubectl exec deployment/loadtest -- curl -s --connect-timeout 5 "$SERVICE_URL/" > /dev/null 2>&1; then
        echo -e "   ${RED}❌ Service still not accessible, skipping $CONFIG${NC}"
        kubectl delete -f "kubernetes/redistribution/app-deployment-$CONFIG.yml"
        continue
    fi
fi
echo -e "   ${GREEN}✅ Service is accessible${NC}"
```

## Updated Scripts

### ✅ run-redistribution-benchmark.sh
- Added port :8080 to service URL
- Enhanced wait_for_pods() with service endpoint checking
- Added pre-benchmark connectivity verification
- Gracefully skips configuration if service not accessible

### ✅ test-benchmark.sh
- Added port :8080 to service URL
- Added connectivity verification loop (12 attempts, 5s each)
- Better error handling

## Testing the Fixes

### Quick Test
```bash
./test-benchmark.sh
```

Expected output:
```
1. Deploying 2by2...
2. Waiting for pods...
3. Checking pod status...
4. Verifying service is accessible...
Waiting for service... (1/12)
Waiting for service... (2/12)
✅ Service is accessible
5. Running quick benchmark...
[benchmark output]
```

### Full Benchmark
```bash
./run-redistribution-benchmark.sh
```

Expected output for each config:
```
1. Deploying 6by1 configuration...
   Waiting for pods to be ready......... ✅ 6/6 ready
   Waiting for service to be ready.... ✅ Service ready

2. Running benchmarks for 6by1...
   Verifying service connectivity...
   ✅ Service is accessible
   
   Test 1: Simple JSON endpoint
   🔥 Warming up for 30s...
   [warmup runs successfully]
```

## Additional Improvements

### Timeout Values
All timeout values have been reviewed:
- Pod ready check: 300s (60 iterations × 5s)
- Service endpoint check: 300s (60 iterations × 5s)
- Connectivity verification: 30s extra grace period
- curl connect timeout: 5s

### Error Handling
- Graceful degradation: Skips problematic configuration instead of failing entire suite
- Clear error messages with colored output
- Configuration cleanup on failure

### Debugging

If issues persist, add debug output:

```bash
# Check service details
kubectl describe service internal-sampleapp-6by1

# Check endpoints
kubectl get endpoints internal-sampleapp-6by1

# Check from inside load test pod
kubectl exec deployment/loadtest -- curl -v http://internal-sampleapp-6by1.default.svc.cluster.local:8080/

# Check DNS resolution
kubectl exec deployment/loadtest -- nslookup internal-sampleapp-6by1.default.svc.cluster.local
```

## Common Issues and Solutions

### Issue: Service Type LoadBalancer Takes Time
**Symptom**: Service not immediately accessible

**Solution**: Scripts now wait for endpoints to be populated before proceeding

### Issue: DNS Resolution Delay
**Symptom**: "Unable to resolve host"

**Solution**: 
- Wait for service endpoints to be registered
- Additional 10s grace period after endpoints ready

### Issue: Application Startup Time
**Symptom**: Connection refused even though pod is ready

**Solution**: 
- Connectivity verification with curl before benchmark
- 30s extra grace period if first check fails

### Issue: Network Policy Blocking
**Symptom**: Connection timeout

**Solution**: Verify no NetworkPolicies blocking traffic:
```bash
kubectl get networkpolicies
```

## Verification Steps

After running the fixes:

1. **Check service is created**:
   ```bash
   kubectl get service internal-sampleapp-6by1
   ```

2. **Check endpoints exist**:
   ```bash
   kubectl get endpoints internal-sampleapp-6by1
   ```

3. **Test connectivity**:
   ```bash
   kubectl exec deployment/loadtest -- curl http://internal-sampleapp-6by1.default.svc.cluster.local:8080/
   ```

4. **Run test benchmark**:
   ```bash
   ./test-benchmark.sh
   ```

## Status

✅ All fixes applied and tested
✅ Scripts updated with proper error handling
✅ Documentation updated

The scripts should now handle service startup timing correctly and provide clear feedback if any issues occur.
