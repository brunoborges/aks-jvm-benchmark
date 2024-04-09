# aks-jvm-benchmark

[![Java CI with Maven](https://github.com/brunoborges/aks-jvm-benchmark/actions/workflows/maven.yml/badge.svg)](https://github.com/brunoborges/aks-jvm-benchmark/actions/workflows/maven.yml)

This project is used as an exercise for evaluating different deployment styles (horizontal scaling versus vertical scaling) of JVM workloads on Kubernetes.


## Generate HdrHistogram chart
See: http://hdrhistogram.github.io/HdrHistogram/plotFiles.html


### Script

#### Comparing different JVM settings

Start the benchmark with this script:

```bash
wrk -t10 -c50 -d5m -R3000 -L http://internal-nginx.default.svc.cluster.local/json
```


#### Comparing different resource configurations

Start the benchmark with this script:

```bash
wrk -t10 -c50 -d5m -R3000 -L http://internal-nginx.default.svc.cluster.local/json
```
