.PHONY: setup proxy test claude doctor

setup:
	@if [ ! -f .env ]; then cp .env.example .env; echo "Created .env. Fill Azure OpenAI values before running proxy."; else echo ".env already exists."; fi

proxy:
	./scripts/start-proxy.sh

test:
	./scripts/test-proxy.sh

claude:
	./scripts/claude-via-azure-openai.sh

doctor:
	@command -v claude >/dev/null && claude --version || (echo "claude CLI not found" && exit 1)
	@command -v uvx >/dev/null && uvx --version || (echo "uvx not found" && exit 1)
	@echo "Checking local .env..."
	@./scripts/ensure-env.sh >/dev/null && echo "env ok"

