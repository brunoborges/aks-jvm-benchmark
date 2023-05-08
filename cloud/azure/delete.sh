#!/bin/sh

source config

# Delete the resource group
az group delete --name $RESOURCE_GROUP --yes --no-wait

