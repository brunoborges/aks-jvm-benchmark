#!/bin/sh
source cloud/azure/config

az aks get-credentials -n $AKS_NAME --admin
