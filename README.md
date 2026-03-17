# Quilter Platform Engineer Take-Home

A containerized Python API deployed to local Kubernetes with Terraform, wrapped in a developer CLI.

## Architecture

```
┌─────────────┐     ┌───────────────┐     ┌──────────────────┐
│  ./dev CLI  │────▶│  Docker Build │────▶│  k3s Cluster     │
│  (bash)     │     │  + Image Load │     │  ┌──────────────┐│
│             │     └───────────────┘     │  │ quilter-demo ││
│             │     ┌───────────────┐     │  │  namespace   ││
│             │────▶│  Terraform    │────▶│  │              ││
│             │     │  Apply        │     │  │  Deployment  ││
│             │     └───────────────┘     │  │  (2 replicas)││
│             │                           │  │              ││
│             │────port-forward──────────▶│  │  ClusterIP   ││
│             │                           │  │  Service     ││
└─────────────┘                           │  └──────────────┘│
                                          └──────────────────┘
```

**API Endpoints:**
- `GET /healthz` — Health check (`{"status": "healthy"}`)
- `GET /version` — App version (`{"version": "1.0.0"}`)

## Prerequisites

- Docker
- Terraform (>= 1.0)
- kubectl
- A local Kubernetes cluster (k3s, kind, or minikube)

## Quick Start

```bash
# Deploy everything (build, load image, terraform apply)
VERSION=1.0.0 ./dev up

# Smoke test (starts port-forward automatically)
./dev test

# Rolling update to a new version
VERSION=2.0.0 ./dev up

# Tear down
./dev down
```

## CLI Reference

| Command | Description |
|---------|-------------|
| `./dev up` | Full lifecycle: preflight → build → deploy |
| `./dev down` | Destroy all Terraform-managed resources |
| `./dev build` | Build Docker image and load into cluster |
| `./dev deploy` | Run `terraform apply` |
| `./dev status` | Show nodes, pods, services, deployed version |
| `./dev logs` | Tail pod logs |
| `./dev url` | Port-forward service to `localhost:8080` |
| `./dev test` | Smoke test `/healthz` and `/version` (manages port-forward automatically) |
| `./dev preflight` | Verify docker, terraform, kubectl are installed |

Set the version with the `VERSION` environment variable (default: `latest`). Use `LOCAL_PORT` to change the port-forward port (default: `8080`).

## Design Decisions

| Choice | Why |
|--------|-----|
| Flask over FastAPI | Two simple GET endpoints don't need async or OpenAPI generation. Fewer dependencies, faster startup. |
| gunicorn | Production WSGI server with proper signal handling for Kubernetes rolling updates. |
| k3s with `image_pull_policy = Never` | Images loaded directly into containerd via `docker save \| k3s ctr images import`. No registry needed. Works equally well with kind (`kind load`) or minikube (`minikube image load`). |
| ClusterIP + port-forward | Cluster-agnostic. No assumptions about LoadBalancer support or ingress controllers. |
| APP_VERSION via env var | Same image artifact, different config per environment. Standard twelve-factor pattern. |
| Bash CLI | Zero external dependencies. Platform engineers live in the terminal. |
| Terraform (not Helm) | Declarative, reviewable, and appropriate for this scope. Helm adds complexity without benefit here. |

## Project Structure

```
├── app/
│   ├── main.py              # Flask API
│   ├── requirements.txt     # Pinned Python dependencies
│   └── test_main.py         # pytest unit tests
├── terraform/
│   ├── versions.tf          # Provider constraints
│   ├── variables.tf         # Configurable inputs
│   ├── main.tf              # Namespace, Deployment, Service
│   └── outputs.tf           # Deployment metadata
├── Dockerfile               # python:3.12-slim, non-root, gunicorn
├── dev                      # Developer CLI
└── README.md
```

## Running Tests

```bash
cd app
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt pytest
python -m pytest test_main.py -v
```

## Adapting to Other Clusters

The CLI is built for k3s but can be adapted to kind or minikube by changing the image loading step in `cmd_build()`:

```bash
# kind
docker build -t quilter-api:$VERSION .
kind load docker-image quilter-api:$VERSION

# minikube
eval $(minikube docker-env)
docker build -t quilter-api:$VERSION .
```

Everything else (Terraform, port-forward, smoke tests) works the same.

For multi-node k3s clusters, set `WORKER_SSH_USER` to distribute images to all nodes:

```bash
WORKER_SSH_USER=core VERSION=1.0.0 ./dev up
```

## Production Considerations

This project is scoped for local development. In a production setting, I'd add:

- **Remote state** — Terraform state in S3/GCS with locking (DynamoDB/GCS), not local
- **Container registry** — Push images to ECR/GCR/GHCR instead of loading directly into containerd
- **CI/CD** — GitHub Actions pipeline: lint, test, build, push image, deploy
- **Ingress** — Replace port-forward with an ingress controller and proper DNS
- **Secrets management** — External secrets operator or Vault, not env vars for sensitive config
- **Observability** — Structured logging, Prometheus metrics, health check dashboards
