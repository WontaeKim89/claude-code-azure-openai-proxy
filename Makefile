.PHONY: setup proxy stop stop-force status restart test test-lifecycle claude alias doctor

setup:
	@if [ ! -f .env ]; then cp .env.example .env; echo "Created .env. Fill Azure OpenAI values before running proxy."; else echo ".env already exists."; fi

proxy:
	./scripts/start-proxy.sh

stop:
	./scripts/proxy-runtime.sh stop

stop-force:
	./scripts/proxy-runtime.sh stop --force

status:
	./scripts/proxy-runtime.sh status

restart: stop
	$(MAKE) proxy

test:
	./scripts/test-proxy.sh

test-lifecycle:
	./tests/test-lifecycle.sh

claude:
	./scripts/claude-via-azure-openai.sh

alias:
	./scripts/install-alias.sh

doctor:
	@command -v claude >/dev/null && claude --version || (echo "claude CLI not found" && exit 1)
	@command -v uvx >/dev/null && uvx --version || (echo "uvx not found" && exit 1)
	@echo "Checking local .env..."
	@./scripts/ensure-env.sh >/dev/null && echo "env ok"
