# aks-jvm-benchmark

[![Java CI with Maven](https://github.com/brunoborges/aks-jvm-benchmark/actions/workflows/maven.yml/badge.svg)](https://github.com/brunoborges/aks-jvm-benchmark/actions/workflows/maven.yml)

This project is used as an exercise for evaluating different deployment styles (horizontal scaling versus vertical scaling) of JVM workloads on Kubernetes.


## Generate HdrHistogram chart
See: http://hdrhistogram.github.io/HdrHistogram/plotFiles.html


### Demo script

First we show difference between GCs and Heap config with the same resource limits (1 CPU, 1 GB RAM).

Then we use the Load Balancer and fire up wrk against them.

#### Comparing different JVM settings

Start the benchmark with this script:

```bash
wrk -t10 -c50 -d5m -R3000 -L http://internal-sampleapp-all.default.svc.cluster.local/json
```

Wait with Prime Factor:

```bash
wrk -t10 -c50 -d5m -R3000 -L  http://internal-sampleapp-all.default.svc.cluster.local/waitWithPrimeFactor?duration=50\&number=927398173993974
```



#### Comparing different resource configurations

Because the k8s Load Balancer only round robin against pods, we must use Nginx for a two-tier load balancing approach.

Delete the gc-related pods, and deploy the `redistribution` pods, followed by `nginx` pod.



Start the benchmark with this script:

```bash
wrk -t10 -c50 -d5m -R3000 -L http://internal-nginx.default.svc.cluster.local/json
```

Wait with Prime Factor:

```bash
wrk -t10 -c50 -d5m -R3000 -L  http://internal-nginx.default.svc.cluster.local/waitWithPrimeFactor?duration=50\&number=927398173993974
```

