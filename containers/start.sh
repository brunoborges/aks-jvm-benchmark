#!/bin/sh
export CPU_SHARES=$(cat /sys/fs/cgroup/cpu/cpu.shares)
java $JAVA_OPTS $JFR -Dcpushares=$CPU_SHARES -jar /usr/local/example/example.jar
