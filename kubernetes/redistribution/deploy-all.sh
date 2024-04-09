#!/bin/sh

for file in ./*.yml; do kubectl apply -f "$file"; done
