#!/bin/sh

ARGS=""

while (( "$#" )); do
  case "$1" in
#    -a|--my-boolean-flag)
#      MY_FLAG=0
#      shift
#      ;;
    -u|--url)
      if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
        URL=$2
        shift 2
      else
        echo "Error: Argument for $1 is missing" >&2
        exit 1
      fi
      ;;
    -t|--threads)
      if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
        THREADS=$2
        shift 2
      else
        echo "Error: Argument for $1 is missing" >&2
        exit 1
      fi
      ;;
    -c|--connections)
      if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
        CONNECTIONS=$2
        shift 2
      else
        echo "Error: Argument for $1 is missing" >&2
        exit 1
      fi
      ;;
    -w|--warmup)
      if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
        WARMUP=$2
        shift 2
      else
        echo "Error: Argument for $1 is missing" >&2
        exit 1
      fi
      ;;
    -d|--duration)
      if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
        DURATION=$2
        shift 2
      else
        echo "Error: Argument for $1 is missing" >&2
        exit 1
      fi
      ;;
    -o|--timeout)
      if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
        TIMEOUT=$2
        shift 2
      else
        echo "Error: Argument for $1 is missing" >&2
        exit 1
      fi
      ;;
    -*|--*=) # unsupported flags
      echo "Error: Unsupported flag $1" >&2
      exit 1
      ;;
    *) # preserve positional arguments
      ARGS="$ARGS $1"
      shift
      ;;
  esac
done

# set positional arguments in their proper place
eval set -- "$ARGS"

url=$URL # http://$ip/json
threads=$THREADS
conns=$CONNECTIONS
durw=${WARMUP:-"10s"}
dur=${DURATION:-"60s"}
timeout=${TIMEOUT:-"2s"}

. kcmds.sh

warmup() {
  echo "WARMUP-BEGIN Warming up for $durw..."
  wrk -t$threads -c$conns -d$durw --timeout $timeout --latency $url > /dev/null
  echo "WARMUP-END Done warming up"
}

load() {
  echo "---"
  echo "BENCH-BEGIN Benchmark for $dur..."
  echo ""

  # Bench 5 minutes
  wrk -t$threads -c$conns -d$dur --timeout $timeout --latency $url

  echo "BENCH-END Done benchmarking."
  echo "---"
}

benchmark() {
  echo "Waiting for 10 seconds before starting benchmark..."
  sleep 10
  echo "Done."
  warmup
  load
}

kdeploy() {
  kubectl delete -f deployment.yml
  kubectl apply -f deployment.yml
  kwait
}

# Deploy App
kdeploy

echo "# SCENARIO A: 1 Instance // 1 CPU"
echo "## BENCHMARK RESULTS"
benchmark

echo "# SCENARIO B: 2 Instances // 1 CPU"
kreplicas "2"
echo "## BENCHMARK RESULTS"
benchmark

echo "# SCENARIO C: 1 Instance // 2 CPUs"
kreplicas 1
kscalecpu "2000m"
echo "## BENCHMARK RESULTS"
benchmark

echo "# SCENARIO D: 2 Instances // 2 CPUs"
kreplicas 2
echo "## BENCHMARK RESULTS"
benchmark
