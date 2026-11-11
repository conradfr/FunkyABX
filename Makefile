# Executables (local)
DOCKER_COMP = docker compose

# Docker containers
APP_CONT = $(DOCKER_COMP) exec app

# Executables
MIX	= $(APP_CONT) mix
NPM = $(DOCKER_COMP) exec -w /app/funkyabx/assets app npm
OXLINT = $(DOCKER_COMP) exec -w /app/funkyabx/assets app npx oxlint

# Misc
.DEFAULT_GOAL = help

## —— The Docker Makefile ——————————————————————————————————
help: ## Outputs this help screen
	@grep -E '(^[a-zA-Z0-9\./_-]+:.*?##.*$$)|(^##)' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}{printf "\033[32m%-30s\033[0m %s\n", $$1, $$2}' | sed -e 's/\[32m##/[33m/'

## —— Docker 🐳 ————————————————————————————————————————————————————————————————
build: ## Builds the Docker images
	@$(DOCKER_COMP) build --pull --no-cache

up: ## Start the docker hub in detached mode (no logs)
	@$(DOCKER_COMP) up --detach

start: build up ## Build and start the containers

down: ## Stop the docker hub
	@$(DOCKER_COMP) down --remove-orphans

stop: down

logs: ## Show live logs
	@$(DOCKER_COMP) logs --tail=0 --follow

sh: ## Connect to the container
	@$(APP_CONT) sh

bash: ## Connect to the container via bash so up and down arrows go to previous commands
	@$(APP_CONT) bash

test: ## Start tests, pass the parameter "c=" to add options to phpunit, example: make test c="--group e2e --stop-on-failure"
	@$(eval c ?=)
	@$(DOCKER_COMP) exec -e APP_ENV=test mix test $(c)

## —— API ———————————————————————————————————————————————————————————————

app-dev:
	@$(APP_CONT) iex --sname app --cookie funkyabx -S mix phx.server

## —— Mix 🧙 ——————————————————————————————————————————————————————————————
mix: ## Run mix, pass the parameter "c=" to run a given command, example: make mix c='deps.get'
	@$(eval c ?=)
	@$(MIX) $(c)

migration: ## Run mix, pass the parameter "c=" to run a given command, example: make mix c='deps.get'
	@$(MIX) ecto.migrate

## —— Npm 🧙 ——————————————————————————————————————————————————————————————
npm: ## Run npm, pass the parameter "c=" to run a given command, example: make npm c='update'
	@$(eval c ?=)
	@$(NPM) $(c)

## —— Npm 🧙 ——————————————————————————————————————————————————————————————
oxlint: ## Run oxlint, pass the parameter "c=" to run a given command
	@$(eval c ?=)
	@$(OXLINT) $(c)