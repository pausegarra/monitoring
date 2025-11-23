help: ## Show this help.
	@awk 'BEGIN {FS = ":.*?## "} /[a-zA-Z_-]+:.*?## / {sub("\\\\n",sprintf("\n%22c"," "), $$2);printf " \033[36m%-20s\033[0m  %s\n", $$1, $$2}' $(MAKEFILE_LIST)

build-grafana: ## Build the grafana image
	docker build -t ghcr.io/pausegarra/grafana -f Dockerfile.grafana .

remove-grafana: ## Remove the grafana image
	docker rm -f grafana-local

run-grafana: build-grafana remove-grafana ## Run the grafana image
	docker run -d -p 3000:3000 --name grafana-local ghcr.io/pausegarra/grafana

build-prometheus: ## Build the prometheus image
	docker build -t ghcr.io/pausegarra/prometheus -f Dockerfile.prometheus .

remove-prometheus: ## Remove the prometheus image
	docker rm -f prometheus-local

run-prometheus: build-prometheus remove-prometheus ## Run the prometheus image
	docker run -d -p 9090:9090 --name prometheus-local ghcr.io/pausegarra/prometheus