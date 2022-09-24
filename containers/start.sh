#!/bin/sh
export CPU_SHARES=$(cat /sys/fs/cgroup/cpu/cpu.shares)
JFR="-XX:StartFlightRecording=name=sampleapprecording,maxage=5m,filename=sampleapprecording.jfr"
java $JAVA_OPTS $JFR -Dcpushares=$CPU_SHARES -jar /usr/local/example/example.jar
