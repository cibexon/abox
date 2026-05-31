# abox

> One command. Full AI infrastructure.

`make run` gives you a local Kubernetes cluster with everything an AI project needs: an AI-aware API gateway, an agent runtime, observability, distributed tracing, and an eval harness — ready to use.

## What's included

| Component | Role |
|---|---|
| **agentgateway v2.2.1** | AI-aware API gateway (Gateway API–native, MCP-aware) |
| **kagent** | Kubernetes-native AI agent framework |
| **fetch-mcp** | MCP server — fetches and returns web page content |
| **fetch-agent** | Declarative kagent agent that uses fetch-mcp via Gemini |
| **qdrant v1.18.0** | Vector database for semantic search and RAG |
| **mcp-security-governance** | Kubernetes-native MCP governance — scores MCP servers against security controls |
| **agentregistry (Inventory)** | Auto-discovers and catalogs AI resources (Agents, MCPServers, Models) across the cluster |
| **a2a-agent** | Minimal A2A-compliant agent — exposes Agent Card at `/.well-known/agent.json` |
| **Flux CD 2.x** | GitOps/GitLessOps operator — keeps the cluster in sync with OCI artifacts |
| **KinD** | Local Kubernetes (1 control-plane + 2 workers) - can be any k8s |
| **cloud-provider-kind** | LoadBalancer support so gateway gets a real IP for local development |

## Quickstart

```bash
make run
```

That's it. Installs OpenTofu and k9s, provisions the cluster, bootstraps Flux, and reconciles all components. When it finishes:

```bash
kubectl get gateway,httproute -A        # gateway is up
kubectl get agents -n kagent            # agent runtime is up
kubectl get svc -n agentgateway-system  # grab the LoadBalancer IP
```

Point your AI app at the gateway IP on port 80.

## How it works

```
make run  →  scripts/setup.sh
  → tofu apply (bootstrap/)
      → KinD cluster
      → Flux Operator + FluxInstance
      → ResourceSetInputProvider   polls oci://ghcr.io/cibexon/abox/releases
      → ResourceSet                creates OCIRepository + 2 Kustomizations
          → releases/crds/    gateway-api-crds, agentgateway-crds, kagent-crds
          → releases/         agentgateway (Gateway + GatewayClass)
                              kagent (agent runtime + HTTPRoute)
```

Everything after the cluster is **gitless GitOps via OCI**: no Git polling, no deploy keys. CI publishes `releases/` as an OCI artifact on every version tag. The cluster reconciles from that artifact automatically.

## Releasing

```bash
make push   # bumps patch version, tags, pushes → CI publishes OCI artifact → cluster reconciles
```

> **Note:** RSIP tag sorting is lexicographic. If the patch version would exceed 9, bump the minor instead: `git tag vX.Y+1.0`.

## Directory layout

| Path | Purpose |
|---|---|
| `bootstrap/` | OpenTofu: KinD + Flux bootstrap (operator, instance, RSIP, ResourceSet) |
| `releases/crds/` | CRD HelmReleases: gateway-api, agentgateway, kagent |
| `releases/` | App HelmReleases + Gateway + HTTPRoutes |
| `releases/mcp-fetch.yaml` | MCPServer CR (fetch-mcp) + Agent CR (fetch-agent) |
| `releases/qdrant.yaml` | Qdrant vector database HelmRelease |
| `releases/mcpg.yaml` | MCP Security Governance HelmRelease (GitRepository source) |
| `releases/inventory.yaml` | Agent Registry Inventory HelmRelease + DiscoveryConfig |
| `releases/a2a-agent.yaml` | A2A agent Deployment + Service |
| `apps/a2a-agent/` | A2A agent source code (FastAPI), Dockerfile |
| `scripts/setup.sh` | Full setup script (`make run`) |
| `.github/workflows/flux-push.yaml` | CI: publish `releases/` as OCI artifact on `v*` tags |
| `.github/workflows/a2a-agent-build.yaml` | CI: build and push a2a-agent Docker image to GHCR |

## Adding components

1. Put CRD charts in `releases/crds/` as HelmReleases.
2. Put app charts in `releases/` as HelmReleases.
3. Run `make push` — the cluster reconciles automatically.

The CRD kustomization runs first (`wait: true`), apps run after (`dependsOn: releases-crds`). This ordering is enforced by Flux and must be preserved.

## Contributing

See [CONTRIBUTING.md](./CONTRIBUTING.md).

## License

Apache 2.0 — see [LICENSE](./LICENSE).
