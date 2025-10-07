# Application Insights Configuration

## Overview
The Application Insights connection string is centralized in a Kubernetes ConfigMap to avoid duplication across all deployment files.

## Configuration File
- **ConfigMap**: `app-insights-config.yml`
- **Key**: `connection-string`
- **Value**: Application Insights connection string including InstrumentationKey, IngestionEndpoint, LiveEndpoint, and ApplicationId

## How It Works

### 1. ConfigMap Definition
The `app-insights-config.yml` file contains:
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-insights-config
  namespace: default
data:
  connection-string: "InstrumentationKey=...;IngestionEndpoint=...;LiveEndpoint=...;ApplicationId=..."
```

### 2. Deployment Reference
Each deployment file references the ConfigMap using `valueFrom`:
```yaml
env:
- name: APPLICATIONINSIGHTS_CONNECTION_STRING
  valueFrom:
    configMapKeyRef:
      name: app-insights-config
      key: connection-string
- name: APPLICATIONINSIGHTS_ROLE_NAME
  value: "2BY2"  # Unique per deployment
```

## Updating the Connection String

To update the Application Insights connection string:

1. Edit `app-insights-config.yml` and update the connection string
2. Apply the updated ConfigMap:
   ```bash
   kubectl apply -f kubernetes/redistribution/app-insights-config.yml
   ```
3. Restart the deployments to pick up the new value:
   ```bash
   kubectl rollout restart deployment/sampleapp-2by2
   kubectl rollout restart deployment/sampleapp-2by3
   kubectl rollout restart deployment/sampleapp-3by2
   kubectl rollout restart deployment/sampleapp-6by1
   ```

## Benefits
- ✅ **Single source of truth** - Update once, applies to all deployments
- ✅ **No duplication** - Connection string defined in one place
- ✅ **Easy maintenance** - Simple to update and track changes
- ✅ **Version control friendly** - Single file to track in git
- ✅ **Kubernetes native** - Uses standard ConfigMap pattern

## Deployment Order
The benchmark script (`run-redistribution-benchmark.sh`) automatically deploys the ConfigMap before any application deployments, ensuring it's always available.
