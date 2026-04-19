# awx-api-demo-iac

Demo repository for:

1. Building a custom Ansible collection (`demo.api_demo`) with one API-calling module.
2. Building a custom AWX Execution Environment (EE).
3. Managing AWX resources as code via local Ansible playbooks that call AWX APIs (`uri`-first workflow, with `awx.awx` module examples retained as optional).

## Repository Layout

- `collections/ansible_collections/demo/api_demo/` - Custom collection source.
- `ee/` - Execution environment build definition.
- `playbooks/local/` - Local control-plane playbooks that configure AWX.
- `playbooks/job_templates/` - Playbooks intended to run inside AWX jobs.
- `inventories/` - Local inventory and vars for bootstrap playbooks.
- `vars/awx_resources.yml` - AWX object definitions (organization/project/EE/template).
- `scripts/` - Convenience wrappers.

## Prerequisites

- `uv` (Python environment and dependency management)
- Docker with access to build and push image tags
- Running AWX instance (awx-operator on k3s)
- AWX Personal Access Token

## Quick Start

### 1) Install local dependencies

```bash
cd ~/projects/awx-api-demo-iac
uv sync
uv run ansible-galaxy collection install -r requirements.yml
```

### 2) Configure AWX connection vars

Copy and edit inventory vars:

```bash
cp inventories/group_vars/all/awx.example.yml inventories/group_vars/all/awx.yml
```

Set environment variables (recommended):

```bash
export AWX_HOST="https://<your-awx-host>"
export AWX_OAUTH_TOKEN="<your-token>"
export AWX_PROJECT_SCM_URL="https://github.com/<your-user>/awx-api-demo-iac.git"
```

### 3) Build and push EE image

```bash
# Build for k3s arm64 nodes
./scripts/build_ee.sh docker.io/<docker-user>/awx-ee-api-demo v1 linux/arm64
./scripts/push_ee.sh docker.io/<docker-user>/awx-ee-api-demo v1

# or via make (defaults to linux/arm64)
make ee-build IMAGE_REPO=docker.io/<docker-user>/awx-ee-api-demo IMAGE_TAG=v1 EE_PLATFORM=linux/arm64
make ee-push IMAGE_REPO=docker.io/<docker-user>/awx-ee-api-demo IMAGE_TAG=v1
```

Update `vars/awx_resources.yml` with the exact image URL/tag (or use `make all ...`, which injects it automatically for bootstrap).

### 4) Optional RBAC/API preflight

```bash
make awx-preflight
```

This checks your token access to key AWX endpoints and prints an HTTP status matrix.

### 5) Bootstrap AWX resources (API-first)

Recommended bootstrap path (direct AWX API via `uri`):

```bash
uv run ansible-playbook -i inventories/localhost.ini playbooks/local/bootstrap_awx_api.yml \
  -e awx_org_id=1 \
  -e awx_manage_organization=false \
  -e awx_manage_execution_environment=false \
  -e awx_job_template_execution_environment=""
```

Optional/experimental module-based path (`awx.awx`):

```bash
uv run ansible-playbook -i inventories/localhost.ini playbooks/local/bootstrap_awx.yml
```

### 6) Deploy custom EE and patch Job Template to use it

```bash
uv run ansible-playbook -i inventories/localhost.ini playbooks/local/deploy_ee_and_patch_jt.yml -e awx_org_id=1
# or
make deploy-ee EXTRA_VARS="-e awx_org_id=1"
```

### 7) Launch demo template from local machine

```bash
uv run ansible-playbook -i inventories/localhost.ini playbooks/local/launch_demo_job.yml -e awx_org_id=1
```

### One-command flow (build/push/bootstrap/deploy-ee/launch)

```bash
make all IMAGE_REPO=docker.io/<docker-user>/awx-ee-api-demo IMAGE_TAG=v1 AWX_ORG_ID=1 EE_PLATFORM=linux/arm64
```

## AWX Resources created by bootstrap

- Organization: `Demo Org`
- Project: `API Demo Project`
- Execution Environment: `API Demo EE`
- Inventory: `Demo Inventory`
- Job Template: `API Echo Demo`

All names are configurable in `vars/awx_resources.yml`.

## Runbook (repeatable re-deploy)

```bash
# 0) auth/env
export AWX_HOST="https://<your-awx-host>"
export AWX_OAUTH_TOKEN="<your-token>"
export AWX_PROJECT_SCM_URL="https://github.com/<your-user>/awx-api-demo-iac.git"

# 1) dependencies
make deps

# 2) optional preflight
make awx-preflight

# 3) full pipeline
make all IMAGE_REPO=docker.io/<docker-user>/awx-ee-api-demo IMAGE_TAG=v1 AWX_ORG_ID=1 EE_PLATFORM=linux/arm64
```

## Notes

- EE build defaults to `linux/arm64` to match this k3s cluster; override with `EE_PLATFORM=...` when needed.
- For private repos/registries, add AWX credentials and reference them in vars.
- `playbooks/job_templates/api_echo_demo.yml` is the AWX-executed playbook that uses `demo.api_demo.api_echo`.
- API-first playbooks are the default in this repository because they were validated in this AWX environment.
