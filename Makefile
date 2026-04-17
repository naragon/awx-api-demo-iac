.PHONY: all deps awx-ping bootstrap launch test-local ee-build ee-push ensure-image-args

all: ensure-image-args
	$(MAKE) deps
	$(MAKE) ee-build IMAGE_REPO=$(IMAGE_REPO) IMAGE_TAG=$(IMAGE_TAG)
	$(MAKE) ee-push IMAGE_REPO=$(IMAGE_REPO) IMAGE_TAG=$(IMAGE_TAG)
	$(MAKE) awx-ping
	uv run ansible-playbook -i inventories/localhost.ini playbooks/local/bootstrap_awx.yml \
	  -e awx_execution_environment_image=$(IMAGE_REPO):$(IMAGE_TAG)
	$(MAKE) launch

deps:
	uv sync
	uv run ansible-galaxy collection install -r requirements.yml

awx-ping:
	uv run ansible-playbook -i inventories/localhost.ini playbooks/local/awx_api_ping.yml

bootstrap:
	uv run ansible-playbook -i inventories/localhost.ini playbooks/local/bootstrap_awx.yml

launch:
	uv run ansible-playbook -i inventories/localhost.ini playbooks/local/launch_demo_job.yml

test-local:
	uv run ansible-playbook -i inventories/localhost.ini playbooks/local/test_collection_local.yml

ensure-image-args:
	@if [ -z "$(IMAGE_REPO)" ] || [ -z "$(IMAGE_TAG)" ]; then \
	  echo "Usage: make <ee-build|ee-push|all> IMAGE_REPO=docker.io/<user>/awx-ee-api-demo IMAGE_TAG=v1"; \
	  exit 1; \
	fi

ee-build: ensure-image-args
	./scripts/build_ee.sh $(IMAGE_REPO) $(IMAGE_TAG)

ee-push: ensure-image-args
	./scripts/push_ee.sh $(IMAGE_REPO) $(IMAGE_TAG)
