#!/bin/bash

# Script to benchmark URLs using wget
# Usage: ./benchmark-url.sh -u URL -n NUMBER [-c CONCURRENCY] [-o OUTPUT_FILE] [-t TIMEOUT]

# Default values
URL=""
ITERATIONS=10
CONCURRENCY=1
OUTPUT_FILE="benchmark-results.log"
TIMEOUT=10
VERBOSE=false

# Function to display usage information
usage() {
    echo "Usage: $0 -u URL -n NUMBER [-c CONCURRENCY] [-o OUTPUT_FILE] [-t TIMEOUT] [-v]"
    echo "  -u URL          : The URL to benchmark (required)"
    echo "  -n NUMBER       : Number of requests to make (default: 10)"
    echo "  -c CONCURRENCY  : Number of concurrent requests (default: 1)"
    echo "  -o OUTPUT_FILE  : File to save results (default: benchmark-results.log)"
    echo "  -t TIMEOUT      : Timeout in seconds for each request (default: 10)"
    echo "  -v              : Verbose output"
    echo "  -h              : Display this help message"
    exit 1
}

# Parse command line arguments
while getopts "u:n:c:o:t:vh" opt; do
    case $opt in
        u) URL="$OPTARG" ;;
        n) ITERATIONS="$OPTARG" ;;
        c) CONCURRENCY="$OPTARG" ;;
        o) OUTPUT_FILE="$OPTARG" ;;
        t) TIMEOUT="$OPTARG" ;;
        v) VERBOSE=true ;;
        h) usage ;;
        \?) echo "Invalid option: -$OPTARG" >&2; usage ;;
    esac
done

# Check if URL is provided
if [ -z "$URL" ]; then
    echo "Error: URL is required" >&2
    usage
fi

# Validate numeric inputs
if ! [[ "$ITERATIONS" =~ ^[0-9]+$ ]]; then
    echo "Error: Number of iterations must be a positive integer" >&2
    usage
fi

if ! [[ "$CONCURRENCY" =~ ^[0-9]+$ ]]; then
    echo "Error: Concurrency must be a positive integer" >&2
    usage
fi

if ! [[ "$TIMEOUT" =~ ^[0-9]+$ ]]; then
    echo "Error: Timeout must be a positive integer" >&2
    usage
fi

echo "Starting benchmark of $URL"
echo "Making $ITERATIONS requests with concurrency $CONCURRENCY"
echo "Results will be saved to $OUTPUT_FILE"
echo "Timeout set to $TIMEOUT seconds"
echo

# Clear output file if it exists
> "$OUTPUT_FILE"

# Function to run a single test
run_test() {
    local req_num=$1
    local start_time=$(date +%s.%N)
    
    if $VERBOSE; then
        echo "Request $req_num: Starting..."
    fi
    
    # Run wget with timeout and silent mode
    output=$(wget -q --timeout="$TIMEOUT" --tries=1 -O - "$URL" 2>&1)
    local status=$?
    
    local end_time=$(date +%s.%N)
    local elapsed=$(echo "$end_time - $start_time" | bc)
    
    # Record result
    if [ $status -eq 0 ]; then
        echo "Request $req_num: Success - Time: $elapsed seconds" >> "$OUTPUT_FILE"
        if $VERBOSE; then
            echo "Request $req_num: Success - Time: $elapsed seconds"
        fi
    else
        echo "Request $req_num: Failed with status $status - Time: $elapsed seconds" >> "$OUTPUT_FILE"
        if $VERBOSE; then
            echo "Request $req_num: Failed with status $status - Time: $elapsed seconds"
        fi
    fi
}

# Run tests based on concurrency
start_total=$(date +%s.%N)

if [ "$CONCURRENCY" -eq 1 ]; then
    # Sequential execution
    for ((i=1; i<=$ITERATIONS; i++)); do
        run_test "$i"
    done
else
    # Parallel execution using GNU Parallel if available
    if command -v parallel &> /dev/null; then
        export -f run_test
        export VERBOSE OUTPUT_FILE URL TIMEOUT
        seq 1 "$ITERATIONS" | parallel -j "$CONCURRENCY" run_test
    else
        # Fallback to background processes
        for ((i=1; i<=$ITERATIONS; i++)); do
            run_test "$i" &
            
            # Control concurrency
            if (( i % CONCURRENCY == 0 )); then
                wait
            fi
        done
        # Wait for any remaining processes
        wait
    fi
fi

end_total=$(date +%s.%N)
total_time=$(echo "$end_total - $start_total" | bc)

# Calculate and display statistics
successes=$(grep -c "Success" "$OUTPUT_FILE")
failures=$(grep -c "Failed" "$OUTPUT_FILE")
avg_time=$(grep "Time:" "$OUTPUT_FILE" | awk -F': ' '{print $NF}' | awk '{gsub("seconds", ""); sum+=$1; count++} END {if(count>0) print sum/count; else print 0}')
min_time=$(grep "Time:" "$OUTPUT_FILE" | awk -F': ' '{print $NF}' | awk '{gsub("seconds", ""); if(min=="" || $1<min) min=$1} END {print min}')
max_time=$(grep "Time:" "$OUTPUT_FILE" | awk -F': ' '{print $NF}' | awk '{gsub("seconds", ""); if(max=="" || $1>max) max=$1} END {print max}')

# Write summary to file and display
echo -e "\n--- SUMMARY ---" | tee -a "$OUTPUT_FILE"
echo "Total requests: $ITERATIONS" | tee -a "$OUTPUT_FILE"
echo "Successful requests: $successes" | tee -a "$OUTPUT_FILE"
echo "Failed requests: $failures" | tee -a "$OUTPUT_FILE"
echo "Total time: $total_time seconds" | tee -a "$OUTPUT_FILE"
echo "Average response time: $avg_time seconds" | tee -a "$OUTPUT_FILE"
echo "Minimum response time: $min_time seconds" | tee -a "$OUTPUT_FILE"
echo "Maximum response time: $max_time seconds" | tee -a "$OUTPUT_FILE"

# Calculate requests per second
if [ "$total_time" != "0" ]; then
    requests_per_sec=$(echo "$ITERATIONS / $total_time" | bc -l)
    echo "Requests per second: $(printf "%.2f" $requests_per_sec)" | tee -a "$OUTPUT_FILE"
fi

echo -e "\nBenchmark completed. Full results saved to $OUTPUT_FILE"