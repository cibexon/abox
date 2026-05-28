#!/bin/bash

kubectl port-forward -n kagent svc/kagent-ui 8080:8080 &

#Api key for LLM
kubectl create secret generic gemini-secret \
  --from-literal=Authorization=<key> \
  -n agentgateway-system

#Dummy kay for ModelConfig
kubectl create secret generic kagent-agentgw \
  --from-literal=AGENTGW_API_KEY=internal-token \
  -n kagent
