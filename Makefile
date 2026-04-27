.PHONY: setup proxy stop restart test claude doctor purge-claude-mem

setup:
	@if [ ! -f .env ]; then cp .env.example .env; echo "Created .env. Fill Azure OpenAI values before running proxy."; else echo ".env already exists."; fi

proxy:
	./scripts/start-proxy.sh

stop:
	@PIDS=$$(lsof -tiTCP:$${LITELLM_PORT:-4000} -sTCP:LISTEN 2>/dev/null || true); \
	if [ -z "$$PIDS" ]; then \
		echo "No LiteLLM proxy is listening on port $${LITELLM_PORT:-4000}."; \
	else \
		echo "Stopping processes on port $${LITELLM_PORT:-4000}: $$PIDS"; \
		kill $$PIDS; \
	fi

restart: stop
	$(MAKE) proxy

test:
	./scripts/test-proxy.sh

claude:
	./scripts/claude-via-azure-openai.sh

doctor:
	@command -v claude >/dev/null && claude --version || (echo "claude CLI not found" && exit 1)
	@command -v uvx >/dev/null && uvx --version || (echo "uvx not found" && exit 1)
	@echo "Checking local .env..."
	@./scripts/ensure-env.sh >/dev/null && echo "env ok"

purge-claude-mem:
	./scripts/purge-claude-mem.sh
