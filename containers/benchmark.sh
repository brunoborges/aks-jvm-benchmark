#!/bin/bash

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

. ./kcmds.sh

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

warmup
load
