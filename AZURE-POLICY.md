# Azure Policy Compliance

This project is configured to work with AKS clusters that have Azure Policy restrictions on container registries.

## Overview

Many enterprise AKS clusters use Azure Policy to enforce security best practices, including:
- Restricting container images to approved registries (e.g., ACR, MCR)
- Requiring resource limits on containers
- Enforcing security contexts and other Kubernetes best practices

## Container Registry Strategy

All deployment manifests in this project use images from:
1. **Your Azure Container Registry (ACR)**: `techxchange2025acr.azurecr.io`
   - Application images: `sampleapp:latest`, `loadtest:latest`
   - Third-party images: `nginx:1.29.1`

2. **Microsoft Container Registry (MCR)**: `mcr.microsoft.com`
   - Development tools: `openjdk/jdk:21-ubuntu` (for debugging pod)

## Setup Instructions

### 1. Configure ACR Name

Update `cloud/azure/config` with your ACR name:
```bash
ACR_NAME=your-acr-name
```

### 2. Import External Images

Import required third-party images to your ACR:
```bash
cd cloud/azure
./import-images.sh
```

This will import:
- `nginx:1.29.1` from Docker Hub

### 3. Build Application Images

Build and push your application images:
```bash
cd cloud/azure
./build-and-push.sh
```

This will build and push:
- `sampleapp:latest`
- `loadtest:latest`

### 4. Verify Images

Check all images are in your ACR:
```bash
az acr repository list --name <your-acr-name> --output table
```

You should see:
- nginx
- sampleapp
- loadtest

## Resource Limits

All containers have resource requests and limits defined to comply with Azure Policy requirements:

### Application Pods
- **Ergonomics/G1GC/PGC variants**: 1 CPU, 512Mi RAM
- **Redistribution variants**: 1-3 CPUs, 1-3Gi RAM (varies by configuration)

### Infrastructure Pods
- **Nginx**: 250m-500m CPU, 128-256Mi RAM
- **LoadTest**: 2 CPU, 2Gi RAM
- **JDK Debug**: 500m-1 CPU, 128Mi RAM

## Common Policy Issues

### Issue: "Container image has not been allowed"
**Cause**: Image is from an unauthorized registry (e.g., Docker Hub)

**Solution**:
```bash
# Import the image to your ACR
az acr import --name <your-acr-name> \
  --source docker.io/library/<image>:<tag> \
  --image <image>:<tag>

# Update the deployment YAML to use ACR
# image: <your-acr-name>.azurecr.io/<image>:<tag>
```

### Issue: "One or more containers do not have resources"
**Cause**: Container missing resource requests/limits

**Solution**: Add resource specifications to your deployment:
```yaml
resources:
  requests:
    cpu: "250m"
    memory: "128Mi"
  limits:
    cpu: "500m"
    memory: "256Mi"
```

### Issue: "Privileged containers are not allowed"
**Cause**: Container has `privileged: true` security context

**Solution**: This is expected for the debug pod (`jdkdbg-deployment.yml`) which needs host access. You may need to exclude this deployment or request a policy exception.

## Checking Applied Policies

View policies applied to your AKS cluster:
```bash
# List all policy assignments
az policy assignment list \
  --query "[?contains(displayName, 'Kubernetes')].{Name:displayName, Policy:policyDefinitionId}" \
  -o table

# Check specific resource group policies
az policy assignment list \
  --resource-group <your-resource-group> \
  -o table
```

## Best Practices

1. **Always use ACR for custom images**: Build and push to your ACR
2. **Import third-party images**: Don't reference Docker Hub directly
3. **Use MCR when possible**: Microsoft's registry is typically pre-approved
4. **Define resource limits**: Always specify requests and limits
5. **Test in dev first**: Validate policy compliance before production
6. **Document exceptions**: If you need privileged access, document why

## Updating Images

### Update Application Code
```bash
# Make your code changes
git commit -am "Update application"

# Rebuild and push
cd cloud/azure
./build-and-push.sh
```

### Update Third-Party Images
```bash
# Update the version in deployment YAML files
# Then import the new version
cd cloud/azure
./import-images.sh  # Update script with new version first
```

### Force Pod Refresh
```bash
# Force deployments to pull latest images
kubectl rollout restart deployment/sampleapp-ergonomics
kubectl rollout restart deployment/sampleapp-g1gc
kubectl rollout restart deployment/sampleapp-pgc
kubectl rollout restart deployment/nginx
```

## Troubleshooting

### Pod stuck in ImagePullBackOff
```bash
# Check the exact error
kubectl describe pod <pod-name>

# Verify ACR access
az acr login --name <your-acr-name>

# Check if image exists
az acr repository show --name <your-acr-name> --image <image>:<tag>
```

### Policy Violation Events
```bash
# Check recent policy violations
kubectl get events --sort-by='.lastTimestamp' | grep -i policy

# Check pod events
kubectl describe pod <pod-name> | grep -i policy
```

## Additional Resources

- [Azure Policy for Kubernetes](https://docs.microsoft.com/azure/governance/policy/concepts/policy-for-kubernetes)
- [Azure Container Registry](https://docs.microsoft.com/azure/container-registry/)
- [Kubernetes Resource Management](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/)
