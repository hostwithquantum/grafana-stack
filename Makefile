IMAGE?=quantum-grafana:dev

.PHONY: build
build:
	docker build --platform linux/amd64 -t $(IMAGE) -f Dockerfile .

.PHONY: lint
lint:
	@for f in dashboards/*.json; do \
		jq empty $$f || exit 1; \
	done
	@echo "dashboards: ok"

.PHONY: test
test: lint build
	IMAGE=$(IMAGE) ./test.sh

.PHONY: run-dev
run-dev: build
	docker run --rm \
		--platform linux/amd64 \
		-p 3000:3000 \
		-e INITIAL_ADMIN_PASSWORD=admin \
		$(IMAGE)

.PHONY: manual-push
manual-push:
	docker build -t quay.io/pngmbh/quantum-grafana:next -f Dockerfile .
	docker push quay.io/pngmbh/quantum-grafana:next
