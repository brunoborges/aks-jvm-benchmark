#!/bin/bash

# Automated Redistribution Benchmark Suite
# This script runs benchmarks against all four redistribution scenarios
# and generates HdrHistogram charts for visualization

set -e

# Configuration
RESULTS_DIR="benchmark-results/$(date +%Y%m%d-%H%M%S)"
THREADS=10
CONNECTIONS=50
WARMUP_DURATION="30s"
BENCH_DURATION="3m"
RATE=8000
TIMEOUT="5s"

# Endpoints to test
ENDPOINT_SIMPLE="/json"
ENDPOINT_CPU="/waitWithPrimeFactor?duration=50&number=927398173993974"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configurations to test
CONFIGS=("6by1" "3by2" "2by3" "2by2")

# Test types to run
# TEST_TYPES=("simple" "cpu")
TEST_TYPES=("simple")

echo "======================================"
echo "Redistribution Benchmark Suite"
echo "======================================"
echo ""
echo "📊 Configuration:"
echo "   - Threads: $THREADS"
echo "   - Connections: $CONNECTIONS"
echo "   - Warmup: $WARMUP_DURATION"
echo "   - Duration: $BENCH_DURATION"
echo "   - Rate limit: $RATE req/s"
echo "   - Results directory: $RESULTS_DIR"
echo "   - Test types: Simple JSON, CPU-Intensive"
echo ""

# Create results directory
mkdir -p "$RESULTS_DIR"

# Function to wait for pods to be ready
wait_for_pods() {
    local label=$1
    local expected=$2
    echo -n "   Waiting for pods to be ready..."
    
    for i in {1..60}; do
        READY=$(kubectl get pods -l "version=$label" -o jsonpath='{.items[*].status.containerStatuses[*].ready}' | grep -o "true" | wc -l | tr -d ' ')
        if [ "$READY" -eq "$expected" ]; then
            echo -e " ${GREEN}✅ $READY/$expected ready${NC}"
            break
        fi
        echo -n "."
        sleep 5
    done
    
    if [ "$READY" -ne "$expected" ]; then
        echo -e " ${RED}❌ Timeout${NC}"
        return 1
    fi
    
    # Wait for service to be ready
    echo -n "   Waiting for service to be ready..."
    for i in {1..60}; do
        # Check if service endpoints are available
        ENDPOINTS=$(kubectl get endpoints "internal-sampleapp-$label" -o jsonpath='{.subsets[*].addresses[*].ip}' 2>/dev/null | wc -w | tr -d ' ')
        if [ "$ENDPOINTS" -ge "1" ]; then
            echo -e " ${GREEN}✅ Service ready${NC}"
            sleep 10  # Extra time for services to stabilize
            return 0
        fi
        echo -n "."
        sleep 5
    done
    
    echo -e " ${RED}❌ Service timeout${NC}"
    return 1
}

# Function to run warmup
run_warmup() {
    local url=$1
    echo -e "   ${YELLOW}🔥 Warming up for $WARMUP_DURATION...${NC}"
    kubectl exec -it deployment/loadtest -- wrk \
        -t$THREADS \
        -c$CONNECTIONS \
        -d$WARMUP_DURATION \
        --timeout $TIMEOUT \
        -R$RATE \
        "$url" > /dev/null 2>&1 || true
    echo -e "   ${GREEN}✅ Warmup complete${NC}"
}

# Function to run benchmark
run_benchmark() {
    local config=$1
    local endpoint=$2
    local url=$3
    local output_file=$4
    
    echo -e "   ${BLUE}📊 Running benchmark...${NC}"
    
    # Run wrk2 with HdrHistogram output
    kubectl exec -it deployment/loadtest -- wrk \
        -t$THREADS \
        -c$CONNECTIONS \
        -d$BENCH_DURATION \
        --timeout $TIMEOUT \
        -R$RATE \
        -L \
        "$url" | tee "$output_file"
    
    echo -e "   ${GREEN}✅ Benchmark complete${NC}"
    echo ""
}

# Function to extract HdrHistogram data from wrk output
extract_hdr_data() {
    local input_file=$1
    local output_file=$2
    
    # Create HdrHistogram header (CSV format expected by HdrHistogram plotter)
    echo "#[StartTime: 0 (seconds), $(date +%s)]" > "$output_file"
    echo "#[BaseTime: 0.0 (seconds)]" >> "$output_file"
    echo "Value,Percentile,TotalCount,1/(1-Percentile)" >> "$output_file"
    
    # Extract the latency distribution section from wrk -L output
    # wrk outputs: Value Percentile TotalCount 1/(1-Percentile)
    # Values are already in milliseconds
    awk '/Detailed Percentile spectrum:/,/#\[Mean/{
        if ($1 ~ /^[0-9]+\.[0-9]+$/ && NF == 4) {
            printf "%s,%s,%s,%s\n", $1, $2, $3, $4
        }
    }' "$input_file" >> "$output_file" 2>/dev/null || true
    
    # Check if we got data
    if [ $(wc -l < "$output_file") -le 3 ]; then
        echo "# No detailed histogram data available" > "$output_file"
        return 1
    fi
    
    return 0
}

# Main benchmark loop - iterate by test type, then by configuration
for TEST_TYPE in "${TEST_TYPES[@]}"; do
    echo ""
    echo "======================================"
    TEST_TYPE_UPPER=$(echo "$TEST_TYPE" | tr '[:lower:]' '[:upper:]')
    echo -e "${YELLOW}🎯 TEST TYPE: ${TEST_TYPE_UPPER}${NC}"
    echo "======================================"
    
    # Set endpoint based on test type
    if [ "$TEST_TYPE" = "simple" ]; then
        ENDPOINT="$ENDPOINT_SIMPLE"
        echo "   Endpoint: /json (Simple JSON response)"
    else
        ENDPOINT="$ENDPOINT_CPU"
        echo "   Endpoint: /waitWithPrimeFactor (CPU-Intensive)"
    fi
    echo ""
    
    for CONFIG in "${CONFIGS[@]}"; do
        echo ""
        echo "======================================"
        echo -e "${BLUE}Testing Configuration: $CONFIG${NC}"
        echo "======================================"
        echo ""
        
        # Determine pod count based on config
        case $CONFIG in
            "6by1") POD_COUNT=6 ;;
            "3by2") POD_COUNT=3 ;;
            "2by3") POD_COUNT=2 ;;
            "2by2") POD_COUNT=2 ;;
        esac
        
        # Deploy the configuration
        echo "1. Deploying $CONFIG configuration..."
        kubectl apply -f "kubernetes/redistribution/app-deployment-$CONFIG.yml"
        
        # Wait for pods to be ready
        if ! wait_for_pods "$CONFIG" "$POD_COUNT"; then
            echo -e "${RED}❌ Failed to deploy $CONFIG, skipping...${NC}"
            continue
        fi
        
        echo ""
        echo "2. Running $TEST_TYPE benchmark for $CONFIG..."
        
        # Service URL (using port 8080 as defined in the service)
        SERVICE_URL="http://internal-sampleapp-$CONFIG.default.svc.cluster.local:8080"
        
        # Verify service is accessible
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
        
        # Run the benchmark for this test type
        echo ""
        echo "   Running $TEST_TYPE test..."
        run_warmup "$SERVICE_URL$ENDPOINT"
        run_benchmark "$CONFIG" "$TEST_TYPE" "$SERVICE_URL$ENDPOINT" "$RESULTS_DIR/${CONFIG}_${TEST_TYPE}.txt"
        extract_hdr_data "$RESULTS_DIR/${CONFIG}_${TEST_TYPE}.txt" "$RESULTS_DIR/${CONFIG}_${TEST_TYPE}.hdr"
        
        # Check resource utilization
        echo ""
        echo "3. Resource utilization for $CONFIG ($TEST_TYPE):"
        kubectl top pods -l "version=$CONFIG" | tee "$RESULTS_DIR/${CONFIG}_${TEST_TYPE}_resources.txt"
        
        echo ""
        echo -e "${GREEN}✅ Completed $TEST_TYPE benchmark for $CONFIG${NC}"
        echo ""
        
        # Clean up this deployment before next one
        echo "4. Cleaning up $CONFIG deployment..."
        kubectl delete -f "kubernetes/redistribution/app-deployment-$CONFIG.yml"
        sleep 10
    done
done

echo ""
echo "======================================"
echo "Benchmark Suite Complete!"
echo "======================================"
echo ""
echo "📁 Results saved to: $RESULTS_DIR"
echo ""
echo "📊 Summary:"
echo ""
for TEST_TYPE in "${TEST_TYPES[@]}"; do
    TEST_TYPE_UPPER=$(echo "$TEST_TYPE" | tr '[:lower:]' '[:upper:]')
    echo "  ${TEST_TYPE_UPPER} ENDPOINT:"
    for CONFIG in "${CONFIGS[@]}"; do
        if [ -f "$RESULTS_DIR/${CONFIG}_${TEST_TYPE}.txt" ]; then
            echo "    $CONFIG:"
            grep "Requests/sec:" "$RESULTS_DIR/${CONFIG}_${TEST_TYPE}.txt" | sed 's/^/      /' || true
            grep "Latency.*99%" "$RESULTS_DIR/${CONFIG}_${TEST_TYPE}.txt" | head -1 | sed 's/^/      /' || true
        fi
    done
    echo ""
done

echo "🎨 Next step: Generate HdrHistogram charts"
echo "   Run: ./generate-charts.sh $RESULTS_DIR"
echo ""
