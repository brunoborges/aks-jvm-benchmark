#!/bin/sh

time=${2:-"30"}
pid=$1

jcmd $pid JFR.start duration=${time}s filename=recording-$pid.jfr

sleep $time

jcmd $pid JFR.stop recording-$pid.jfr
