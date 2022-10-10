#!/bin/bash

cpus=${1:-1}
memory=${2:-'128m'}

echo "Starting evaluation with $cpus CPUs and $memory memory."

image='mcr.microsoft.com/openjdk/jdk:17-mariner'

# Test Default Heap Size
# See source: https://github.com/openjdk/jdk/blob/46e6e41b9a35c8665eb31be2f8c36bbdcc90564a/src/hotspot/share/runtime/arguments.cpp#L1745
echo "# Default Heap Size:"
docker run --memory=$memory --cpus=$cpus -v `pwd`:/app $image 2>/dev/null \
    java -XX:+PrintFlagsFinal -cp /app Hello | grep 'MaxHeapSize'

# Test Default Garbage Collector
echo "# Default Garbage Collector:"
docker run --memory=$memory --cpus=$cpus -v `pwd`:/app $image 2>/dev/null \
    java -XX:+PrintFlagsFinal -cp /app Hello | grep 'UseSerial\|UseG1\|UseParallel'

