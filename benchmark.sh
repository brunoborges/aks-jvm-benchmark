#!/bin/sh
ip=20.47.120.26
url=http://$ip/json
threads=6
conns=40
durw="10s"
dur="60s"
timeout="2s"

kwait() {
  kubectl rollout status deployment/springboot
}

ksetenv() {
  kubectl set env deployment/springboot JAVA_OPTS=${1}
  kwait
}

kreplicas() {
  kubectl scale --replicas=${1} -f deployment.yml
  kwait
}

kscalecpu() {
  kubectl patch deployment springboot --type='json' -p='[{"op": "replace", "path": "/spec/template/spec/containers/0/resources/limits/cpu", "value":"'${1}'"}, {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value":"'${1}'"}]'
  kwait
}

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
