# Azure Policy Compliance - Changes Summary

## Overview
This document summarizes all changes made to ensure the project complies with Azure Policy restrictions on AKS clusters.

## Changes Made

### 1. Container Images - Updated to Use ACR

All Kubernetes deployment manifests now use Azure Container Registry (ACR) instead of public registries:

#### Nginx Deployments
- **Files Changed**:
  - `kubernetes/two-tier-lb/nginx-deployment-redistribution.yml`
  - `kubernetes/two-tier-lb/nginx-deployment-gcbench.yml`
- **Change**: `nginx:1.27.0` → `techxchange2025acr.azurecr.io/nginx:1.29.1`
- **Added**: Resource limits (250m-500m CPU, 128-256Mi RAM)

#### Application Deployments
Already using ACR ✅:
- `kubernetes/deployments/app-deployment-*.yml`
- `kubernetes/redistribution/app-deployment-*.yml`
- `kubernetes/loadtest-deployment.yml`

#### Debug Tools
Already using Microsoft Container Registry (MCR) ✅:
- `kubernetes/jdkdbg-deployment.yml` uses `mcr.microsoft.com/openjdk/jdk:21-ubuntu`

### 2. Resource Limits Added

All containers now have proper resource requests and limits:

| Container Type | CPU Request | CPU Limit | Memory Request | Memory Limit |
|---------------|-------------|-----------|----------------|--------------|
| Nginx | 250m | 500m | 128Mi | 256Mi |
| Sample App (1 CPU) | 1000m | 1000m | 512Mi | 512Mi |
| Sample App (2 CPU) | 2000m | 2000m | 1-2Gi | 1-2Gi |
| Sample App (3 CPU) | 3000m | 3000m | 3Gi | 3Gi |
| Load Test | 2000m | 2000m | 2Gi | 2Gi |
| JDK Debug | 500m | 1000m | 128Mi | 128Mi |

### 3. New Scripts Created

#### `cloud/azure/import-images.sh`
- Imports external images (nginx) to ACR
- Ensures compliance before deployment
- Run this once during setup

#### `cloud/azure/build-and-push.sh`
- Builds and pushes application images (sampleapp, loadtest)
- Uses `az acr build` for efficient cloud builds
- Run this when application code changes

### 4. Documentation Added

#### `AZURE-POLICY.md`
Comprehensive guide covering:
- Azure Policy overview
- Container registry strategy
- Setup instructions
- Common policy issues and solutions
- Troubleshooting guide

#### `README.md` - Updated
- Added quick start section
- References to new documentation
- Setup prerequisites

#### `DEMO-FLOW.md` - Updated
- Updated pre-demo checklist
- Removed inline policy workarounds
- Added reference to AZURE-POLICY.md
- Cleaner troubleshooting section

## Benefits

### 1. Security & Compliance ✅
- All images from trusted sources (ACR/MCR)
- Complies with enterprise Azure Policy requirements
- No policy violations during deployment

### 2. Repeatability ✅
- Scripts ensure consistent setup
- No manual image imports during demo
- Works out-of-the-box on policy-restricted clusters

### 3. Resource Management ✅
- All containers have proper resource limits
- Prevents "noisy neighbor" issues
- Better capacity planning

### 4. Developer Experience ✅
- Clear documentation
- Easy-to-use scripts
- Troubleshooting guides

## Migration Checklist

If you're updating an existing deployment:

- [ ] Update `cloud/azure/config` with your ACR name
- [ ] Run `cloud/azure/import-images.sh` to import nginx
- [ ] Run `cloud/azure/build-and-push.sh` to build application images
- [ ] Verify images in ACR: `az acr repository list --name <your-acr-name>`
- [ ] Apply updated deployments:
  ```bash
  cd kubernetes/deployments
  ./deploy-all.sh
  
  cd ../two-tier-lb
  kubectl apply -f nginx-config-redistribution.yml
  kubectl apply -f nginx-deployment-redistribution.yml
  ```
- [ ] Verify no policy violations: `kubectl get events | grep -i policy`
- [ ] Test the full demo flow

## Future Considerations

### Image Updates
When updating to newer versions:
1. Update version in `import-images.sh`
2. Update version in deployment YAML files
3. Run `import-images.sh` to pull new version
4. Apply deployments

### New External Images
If adding new third-party images:
1. Add import command to `import-images.sh`
2. Update deployment YAML to use ACR path
3. Document in `AZURE-POLICY.md`

### Policy Changes
If Azure Policy requirements change:
- Review `AZURE-POLICY.md` for affected areas
- Update resource limits if needed
- Test in development cluster first

## Verification

### Check Policy Compliance
```bash
# No policy violations
kubectl get events --sort-by='.lastTimestamp' | grep -i policy

# All pods running
kubectl get pods

# All images from ACR/MCR
kubectl get pods -o jsonpath='{range .items[*]}{.spec.containers[*].image}{"\n"}{end}' | sort -u
```

Expected output - all images should be from:
- `techxchange2025acr.azurecr.io/*`
- `mcr.microsoft.com/*`

### Test Deployment
```bash
# Deploy everything
cd kubernetes/deployments
./deploy-all.sh

# Check for errors
kubectl get pods
kubectl get events --sort-by='.lastTimestamp' | tail -20

# Clean up
./undeploy-all.sh
```

## Support

For issues or questions:
1. Check `AZURE-POLICY.md` for troubleshooting
2. Check `DEMO-FLOW.md` for step-by-step guidance
3. Review Azure Policy assignments: `az policy assignment list`

---

**Status**: ✅ All changes implemented and tested
**Last Updated**: October 7, 2025
