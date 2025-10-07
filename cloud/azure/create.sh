#!/bin/sh

source config

# Create a resource group
az group create --name $RESOURCE_GROUP --location eastus

# Create an Azure Container Registry
az acr create --resource-group $RESOURCE_GROUP --name $ACR_NAME --sku Basic

# Create an Azure Kubernetes Service cluster
az aks create --resource-group $RESOURCE_GROUP --name $AKS_NAME --node-count $AKS_NODE_COUNT --node-vm-size $AKS_NODE_VM_SIZE --node-osdisk-size $AKS_NODE_DISK_SIZE --generate-ssh-keys

# Get the id of the service principal configured for AKS
CLIENT_ID=$(az aks show --resource-group $RESOURCE_GROUP --name $AKS_NAME --query "servicePrincipalProfile.clientId" --output tsv)
