#!/bin/bash


kubectl patch ocirepository releases -n flux-system --type merge -p '{"spec":{"ref":{"tag":"latest"}}}' && kubectl annotate ocirepository releases -n flux-system reconcile.fluxcd.io/requestedAt="$(date +%s)" --overwrite
kubectl get ocirepository releases -n flux-system -w

kubectl port-forward -n kagent svc/kagent-ui 8080:8080 &
kubectl port-forward -n agentregistry svc/agentregistry-api 8085:8080 &

#Api key for LLM
kubectl create secret generic gemini-secret \
  --from-literal=Authorization=<key> \
  -n agentgateway-system

#Dummy kay for ModelConfig
kubectl create secret generic kagent-agentgw \
  --from-literal=AGENTGW_API_KEY=internal-token \
  -n kagent
