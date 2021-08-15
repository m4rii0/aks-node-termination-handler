KUBECONFIG=$(HOME)/.kube/azure-dev

build:
	goreleaser build --rm-dist --skip-validate --snapshot
	mv ./dist/aks-node-termination-handler_linux_amd64/aks-node-termination-handler aks-node-termination-handler
	docker build --pull . -t paskalmaksim/aks-node-termination-handler:dev

push:
	docker push paskalmaksim/aks-node-termination-handler:dev

deploy:
	helm uninstall aks-node-termination-handler --namespace aks-node-termination-handler || true
	helm upgrade aks-node-termination-handler --install --create-namespace --namespace aks-node-termination-handler ./chart

clean:
	kubectl delete ns aks-node-termination-handler

run:
	go run --race ./cmd \
	-config=config.yaml \
	-kubeconfig=kubeconfig \
	-node=aks-spotcpu2-24406641-vmss00000e \
	-log.level=DEBUG \
	-log.prety \
	-endpoint=http://localhost:28080/pkg/types/testdata/ScheduledEventsType.json

run-mock:
	go run --race ./mock

test:
	go mod tidy
	go fmt ./cmd/... ./pkg/...
	CONFIG=testdata/config_test.yaml go test --race ./cmd/... ./pkg/...
	golangci-lint run -v

test-release:
	goreleaser release --snapshot --skip-publish --rm-dist

upgrade:
	go get -v -u k8s.io/api@v0.20.9 || true
	go get -v -u k8s.io/apimachinery@v0.20.9
	go get -v -u k8s.io/client-go@v0.20.9
	go mod tidy