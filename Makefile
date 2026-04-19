.PHONY: all deps awx-ping awx-preflight bootstrap bootstrap-api deploy-ee launch test-local ee-build ee-push ensure-image-args ensure-org-id

all: ensure-image-args ensure-org-id
	$(MAKE) deps
	$(MAKE) ee-build IMAGE_REPO=$(IMAGE_REPO) IMAGE_TAG=$(IMAGE_TAG) EE_PLATFORM=$(EE_PLATFORM)
	$(MAKE) ee-push IMAGE_REPO=$(IMAGE_REPO) IMAGE_TAG=$(IMAGE_TAG)
	$(MAKE) awx-ping
	uv run ansible-playbook -i inventories/localhost.ini playbooks/local/bootstrap_awx_api.yml \
	  -e awx_org_id=$(AWX_ORG_ID) \
	  -e awx_manage_organization=false \
	  -e awx_manage_execution_environment=false \
	  -e awx_job_template_execution_environment="" \
	  -e awx_execution_environment_image=$(IMAGE_REPO):$(IMAGE_TAG)
	$(MAKE) deploy-ee EXTRA_VARS="-e awx_org_id=$(AWX_ORG_ID) -e awx_execution_environment_image=$(IMAGE_REPO):$(IMAGE_TAG)"
	$(MAKE) launch EXTRA_VARS="-e awx_org_id=$(AWX_ORG_ID)"

deps:
	uv sync
	uv run ansible-galaxy collection install -r requirements.yml

awx-ping:
	uv run ansible-playbook -i inventories/localhost.ini playbooks/local/awx_api_ping.yml

awx-preflight:
	uv run ansible-playbook -i inventories/localhost.ini playbooks/local/awx_rbac_preflight.yml

bootstrap:
	uv run ansible-playbook -i inventories/localhost.ini playbooks/local/bootstrap_awx.yml $(EXTRA_VARS)

bootstrap-api:
	uv run ansible-playbook -i inventories/localhost.ini playbooks/local/bootstrap_awx_api.yml $(EXTRA_VARS)

deploy-ee:
	uv run ansible-playbook -i inventories/localhost.ini playbooks/local/deploy_ee_and_patch_jt.yml $(EXTRA_VARS)

launch:
	uv run ansible-playbook -i inventories/localhost.ini playbooks/local/launch_demo_job.yml $(EXTRA_VARS)

test-local:
	uv run ansible-playbook -i inventories/localhost.ini playbooks/local/test_collection_local.yml

ensure-image-args:
	@if [ -z "$(IMAGE_REPO)" ] || [ -z "$(IMAGE_TAG)" ]; then \
	  echo "Usage: make <ee-build|ee-push|all> IMAGE_REPO=docker.io/<user>/awx-ee-api-demo IMAGE_TAG=v1"; \
	  exit 1; \
	fi

ensure-org-id:
	@if [ -z "$(AWX_ORG_ID)" ]; then \
	  echo "Usage: make all ... AWX_ORG_ID=<organization-id>"; \
	  exit 1; \
	fi

ee-build: ensure-image-args
	./scripts/build_ee.sh $(IMAGE_REPO) $(IMAGE_TAG) $(if $(EE_PLATFORM),$(EE_PLATFORM),linux/arm64)

ee-push: ensure-image-args
	./scripts/push_ee.sh $(IMAGE_REPO) $(IMAGE_TAG)
