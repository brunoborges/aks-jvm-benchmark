#!/bin/bash

# Verify Azure Policy Compliance
# This script checks if all images are properly configured for Azure Policy

set -e

echo "======================================"
echo "Azure Policy Compliance Verification"
echo "======================================"
echo ""

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

ERRORS=0
WARNINGS=0

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}❌ kubectl not found${NC}"
    exit 1
fi

echo "1. Checking Kubernetes connection..."
if kubectl cluster-info &> /dev/null; then
    echo -e "${GREEN}✅ Connected to cluster${NC}"
else
    echo -e "${RED}❌ Cannot connect to cluster${NC}"
    exit 1
fi

echo ""
echo "2. Scanning deployment YAML files for policy compliance..."
echo ""

# Check all YAML files for non-ACR/MCR images
echo "   Checking image sources..."
NON_COMPLIANT=$(grep -r "image:" kubernetes/ --include="*.yml" | \
    grep -v "techxchange2025acr.azurecr.io" | \
    grep -v "mcr.microsoft.com" | \
    grep -v "#" || true)

if [ -z "$NON_COMPLIANT" ]; then
    echo -e "   ${GREEN}✅ All images use ACR or MCR${NC}"
else
    echo -e "   ${RED}❌ Found non-compliant images:${NC}"
    echo "$NON_COMPLIANT"
    ((ERRORS++))
fi

echo ""
echo "   Checking resource limits..."
MISSING_RESOURCES=$(grep -r "containers:" kubernetes/ --include="*.yml" -A 10 | \
    grep -B 5 "image:" | \
    grep -v "resources:" | \
    grep "name:" | \
    grep -v "#" || true)

if [ -z "$MISSING_RESOURCES" ]; then
    echo -e "   ${GREEN}✅ All containers have resource limits${NC}"
else
    echo -e "   ${YELLOW}⚠️  Some containers may be missing resource limits${NC}"
    echo "   (This is a heuristic check - manually verify if unsure)"
    ((WARNINGS++))
fi

echo ""
echo "3. Checking if required images exist in ACR..."
echo ""

source cloud/azure/config

REQUIRED_IMAGES=("nginx:1.29.1" "sampleapp:latest" "loadtest:latest")

for IMAGE in "${REQUIRED_IMAGES[@]}"; do
    if az acr repository show --name $ACR_NAME --image $IMAGE &> /dev/null; then
        echo -e "   ${GREEN}✅ $IMAGE${NC}"
    else
        echo -e "   ${RED}❌ $IMAGE - NOT FOUND${NC}"
        echo "      Run: cd cloud/azure && ./import-images.sh or ./build-and-push.sh"
        ((ERRORS++))
    fi
done

# Check if there are any running pods
echo ""
echo "4. Checking deployed pods (if any)..."
echo ""

PODS=$(kubectl get pods -o json 2>/dev/null)

if [ "$PODS" == '{"items":[]}' ] || [ -z "$PODS" ]; then
    echo -e "   ${YELLOW}ℹ️  No pods currently deployed${NC}"
else
    # Check pod images
    echo "   Checking running pod images..."
    POD_IMAGES=$(kubectl get pods -o jsonpath='{range .items[*]}{.spec.containers[*].image}{"\n"}{end}' 2>/dev/null | sort -u)
    
    while IFS= read -r IMAGE; do
        if [[ "$IMAGE" == *"techxchange2025acr.azurecr.io"* ]] || [[ "$IMAGE" == *"mcr.microsoft.com"* ]]; then
            echo -e "   ${GREEN}✅ $IMAGE${NC}"
        elif [ -z "$IMAGE" ]; then
            continue
        else
            echo -e "   ${RED}❌ $IMAGE - Non-compliant image${NC}"
            ((ERRORS++))
        fi
    done <<< "$POD_IMAGES"
    
    # Check for policy violations
    echo ""
    echo "   Checking for policy violation events..."
    POLICY_EVENTS=$(kubectl get events --sort-by='.lastTimestamp' 2>/dev/null | grep -i "azurepolicy" | tail -5 || true)
    
    if [ -z "$POLICY_EVENTS" ]; then
        echo -e "   ${GREEN}✅ No policy violations found${NC}"
    else
        echo -e "   ${RED}❌ Found policy violations:${NC}"
        echo "$POLICY_EVENTS"
        ((ERRORS++))
    fi
fi

echo ""
echo "5. Checking Azure Policy assignments..."
echo ""

POLICIES=$(az policy assignment list --query "[?contains(displayName, 'Kubernetes')].displayName" -o tsv 2>/dev/null || true)

if [ -z "$POLICIES" ]; then
    echo -e "   ${YELLOW}ℹ️  No Kubernetes policies found (or unable to query)${NC}"
else
    echo "   Active Kubernetes policies:"
    echo "$POLICIES" | while read -r POLICY; do
        echo "   - $POLICY"
    done
fi

echo ""
echo "======================================"
echo "Summary"
echo "======================================"
echo ""

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}✅ All checks passed! Your setup is Azure Policy compliant.${NC}"
    exit 0
elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}⚠️  $WARNINGS warning(s) found. Review above.${NC}"
    exit 0
else
    echo -e "${RED}❌ $ERRORS error(s) and $WARNINGS warning(s) found.${NC}"
    echo ""
    echo "Common fixes:"
    echo "  1. Import external images: cd cloud/azure && ./import-images.sh"
    echo "  2. Build application images: cd cloud/azure && ./build-and-push.sh"
    echo "  3. Review AZURE-POLICY.md for detailed guidance"
    exit 1
fi
