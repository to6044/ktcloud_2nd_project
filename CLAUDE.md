# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

KT Cloud Team7 hybrid cloud infrastructure application. Full-stack web app for managing/monitoring a hybrid cloud setup, deployed on a single-node k3s cluster via Ansible automation.

**Stack**: React 19 + Vite (frontend) → FastAPI (backend) → PostgreSQL (database), with Prometheus + Grafana monitoring, all orchestrated via Helm on k3s.

## Build & Run Commands

### Backend
```bash
cd application/backend
python3 -m venv venv && source venv/bin/activate
pip install -r requirements.txt
uvicorn main:app --host 0.0.0.0 --port 8000
```
Environment variables: `DB_USER`, `DB_PASSWORD`, `DB_HOST`, `DB_NAME` (defaults: postgres/postgres/local-db-postgresql.db.svc.cluster.local/hybrid_db)

### Frontend
```bash
cd application/frontend
npm install
npm run dev       # development server
npm run build     # production build (outputs to dist/)
npm run preview   # preview production build
npm run lint      # ESLint check
```

### Container Image Build
```bash
# Uses BuildKit (buildctl), targets k3s containerd namespace
cd application
bash build_backend.sh
```
Images: `docker.io/ktcloud7/backend:v1.0.4`, `docker.io/ktcloud7/frontend:v1.0.5`

### Full Infrastructure Provisioning (Ansible)
```bash
cd ansible
ansible-playbook -i inventory playbook.yml
```
Runs roles in order: prerequisites → k3s → database → monitoring → app_deploy

### Kubernetes Deployment
```bash
cd k8s-manifests
bash apply.sh          # applies ingress.yml and monitoring.yml
```
Helm chart at `application/app-chart/` is deployed by the Ansible `app_deploy` role as release `my-app` in namespace `ktcloud7`.

### Load Testing (k6)
```bash
k6 run application/k6/smoke-test.js    # 1 VU, 30s
k6 run application/k6/load-test.js     # 10→50 VUs, 5min staged
k6 run application/k6/stress-test.js   # up to 400 VUs, staged escalation
```
All tests target `POST /api/data`.

### Local Backend Testing
```bash
cd application/backend
bash test.sh   # port-forwards k8s PostgreSQL, activates venv, starts server
```

## Architecture

### Request Flow
```
Client → Traefik Ingress (api.hybrid-test.local)
         ├── /api/* → backend-svc:8000 (FastAPI)
         └── /*     → frontend-svc:80  (nginx serving React build)
```

### Kubernetes Namespaces
- `ktcloud7`: Application (backend + frontend deployments)
- `db`: PostgreSQL (Bitnami Helm chart, release `local-db`)
- `monitoring`: kube-prometheus-stack (Grafana + Prometheus)

### Backend API Endpoints
- `GET /api/health` — DB health check with latency metrics
- `POST /api/data` — Write dummy record to PostgreSQL
- `GET /api/data` — Read last 5 records
- `GET /metrics` — Prometheus metrics (custom DB latency histogram)

### Monitoring Pipeline
Backend exposes `/metrics` → ServiceMonitor (`k8s-manifests/monitoring.yml`) scrapes from `monitoring` namespace → Prometheus → Grafana (admin/admin)

### Ansible Roles (ansible/roles/)
Each role is self-contained with tasks/main.yml:
- **prerequisites**: System packages, Helm 3, Node.js 20, BuildKit v0.12.5, Python k8s modules
- **k3s**: Single-node k3s install, kubeconfig setup
- **database**: PostgreSQL via Bitnami Helm chart
- **monitoring**: kube-prometheus-stack via Helm
- **app_deploy**: Copies app-chart to /tmp, deploys via Helm (atomic, wait)

### Dockerfiles
Both use multi-stage builds for minimal images:
- **Backend**: python:3.10-slim builder → runtime with uvicorn
- **Frontend**: node:20-alpine builder (Vite build) → nginx:alpine serving static files
