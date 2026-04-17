# awx-api-demo-iac

Demo repository for:

1. Building a custom Ansible collection (`demo.api_demo`) with one API-calling module.
2. Building a custom AWX Execution Environment (EE).
3. Managing AWX resources as code via local Ansible playbooks that call AWX APIs (through `awx.awx` modules and `uri` where useful).

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
```

### 3) Build and push EE image

```bash
./scripts/build_ee.sh docker.io/<docker-user>/awx-ee-api-demo v1
./scripts/push_ee.sh docker.io/<docker-user>/awx-ee-api-demo v1

# or via make
make ee-build IMAGE_REPO=docker.io/<docker-user>/awx-ee-api-demo IMAGE_TAG=v1
make ee-push IMAGE_REPO=docker.io/<docker-user>/awx-ee-api-demo IMAGE_TAG=v1
```

Update `vars/awx_resources.yml` with the exact image URL/tag (or use `make all ...`, which injects it automatically for bootstrap).

### 4) Bootstrap AWX resources (Config as Code)

```bash
uv run ansible-playbook -i inventories/localhost.ini playbooks/local/bootstrap_awx.yml
```

### 5) Launch demo template from local machine

```bash
uv run ansible-playbook -i inventories/localhost.ini playbooks/local/launch_demo_job.yml
```

### One-command flow (build/push/bootstrap/launch)

```bash
make all IMAGE_REPO=docker.io/<docker-user>/awx-ee-api-demo IMAGE_TAG=v1
```

## AWX Resources created by bootstrap

- Organization: `Demo Org`
- Project: `API Demo Project`
- Execution Environment: `API Demo EE`
- Inventory: `Demo Inventory`
- Job Template: `API Echo Demo`

All names are configurable in `vars/awx_resources.yml`.

## Notes

- EE build uses `uv run ansible-builder` from the project-managed environment.
- For private repos/registries, add AWX credentials and reference them in vars.
- `playbooks/job_templates/api_echo_demo.yml` is the AWX-executed playbook that uses `demo.api_demo.api_echo`.
