#!/bin/bash

# Initialize k3s
sudo k3s server &

# Wait for k3s to be ready
sleep 30

# Deploy submodule1 to k3s
kubectl apply -f /workspace/be_Builder/k8s/deployment.yaml
kubectl apply -f /workspace/be_Builder/k8s/service.yaml

# Deploy submodule1 to k3s
kubectl apply -f /workspace/be_Sequencer/k8s/deployment.yaml
kubectl apply -f /workspace/be_Sequencer/k8s/service.yaml

# Deploy submodule1 to k3s
kubectl apply -f /workspace/be_Socket/k8s/deployment.yaml
kubectl apply -f /workspace/be_Socket/k8s/service.yaml

# Deploy submodule1 to k3s
kubectl apply -f /workspace/be_Processor/k8s/deployment.yaml
kubectl apply -f /workspace/be_Processor/k8s/service.yaml

# Deploy submodule1 to k3s
kubectl apply -f /workspace/fe_Catalog/k8s/deployment.yaml
kubectl apply -f /workspace/fe_Catalog/k8s/service.yaml