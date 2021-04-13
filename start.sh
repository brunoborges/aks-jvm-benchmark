#!/bin/sh
export CPU_SHARES=$(cat /sys/fs/cgroup/cpu/cpu.shares)
java $JAVA_OPTS -javaagent:/usr/local/example/applicationinsights-agent-3.0.2.jar -Dcpushares=$CPU_SHARES -jar /usr/local/example/example.jar
