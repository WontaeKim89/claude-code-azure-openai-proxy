# Claude Code Azure OpenAI Proxy

Claude Code에서 Azure OpenAI의 OpenAI 계열 모델을 직접 연결하는 대신, LiteLLM을 Anthropic 호환 프록시로 두고 Claude Code가 그 프록시를 바라보게 하는 로컬 실행 템플릿입니다.

구조:

```text
Claude Code -> LiteLLM Anthropic-compatible endpoint -> Azure OpenAI deployment
```

## 전제

- Claude Code CLI가 설치되어 있어야 합니다.
- `uvx`가 설치되어 있어야 합니다.
- Azure OpenAI에 GPT-5.5 배포가 만들어져 있어야 합니다.
- Azure OpenAI의 API key, endpoint, API version, deployment name은 각자 `.env`에 입력합니다.

## 빠른 시작

```bash
cd /Users/gim-wontae/Desktop/Persnal_Project/claude-code-azure-openai-proxy
make setup
```

`.env`를 열고 아래 값을 채웁니다.

```bash
AZURE_API_KEY=
AZURE_API_BASE=https://your-resource-name.openai.azure.com
AZURE_API_VERSION=2025-04-01-preview
AZURE_DEPLOYMENT_NAME=your-gpt-55-deployment-name
```

터미널 1에서 LiteLLM 프록시를 실행합니다.

```bash
make proxy
```

터미널 2에서 프록시가 Anthropic 호환 요청을 처리하는지 테스트합니다.

```bash
make test
```

테스트가 통과하면 Claude Code를 프록시 경유로 실행합니다.

```bash
make claude
```

특정 프로젝트에서 시작하려면 해당 프로젝트 경로로 이동한 뒤 이 래퍼를 호출합니다.

```bash
cd /path/to/your/project
/Users/gim-wontae/Desktop/Persnal_Project/claude-code-azure-openai-proxy/scripts/claude-via-azure-openai.sh
```

## 상태 확인

```bash
make doctor
```

`make doctor`는 `claude`, `uvx`, `.env` 필수값을 확인합니다.

## 모델 적용 방식

`config/litellm.config.yaml`은 템플릿 파일입니다. `./scripts/start-proxy.sh`가 `.env` 값을 읽어 `.generated/litellm.config.yaml`을 만들고, Claude Code에 `gpt-5.5`라는 모델 별칭을 노출합니다.

```yaml
model_list:
  - model_name: __CLAUDE_CODE_MODEL_ALIAS__
    litellm_params:
      model: azure/__AZURE_DEPLOYMENT_NAME__
```

Azure 쪽 배포명이 바뀌어도 `.env`의 `AZURE_DEPLOYMENT_NAME`만 바꾸면 됩니다. Claude Code 쪽 모델명은 `CLAUDE_CODE_MODEL_ALIAS=gpt-5.5`로 유지됩니다.

## Claude Code에 적용되는 환경변수

`scripts/claude-via-azure-openai.sh`가 아래 값을 설정한 뒤 `claude`를 실행합니다.

```bash
ANTHROPIC_BASE_URL=http://127.0.0.1:4000
ANTHROPIC_AUTH_TOKEN=$LITELLM_MASTER_KEY
ANTHROPIC_API_KEY=$LITELLM_MASTER_KEY
ANTHROPIC_MODEL=gpt-5.5
ANTHROPIC_DEFAULT_SONNET_MODEL=gpt-5.5
ANTHROPIC_DEFAULT_HAIKU_MODEL=gpt-5.5
CLAUDE_CODE_SUBAGENT_MODEL=gpt-5.5
```

공유 프로젝트에 설정 파일로 넣고 싶다면 `.claude/settings.example.json`을 참고하되, 팀 공용 저장소에는 실제 키를 넣지 마세요. 이 레포의 기본 권장 방식은 래퍼 스크립트 실행입니다.

## 보안

- `.env`와 `.env.*`는 `.gitignore`에 포함되어 있습니다.
- GitHub에는 `.env.example`만 올립니다.
- `LITELLM_MASTER_KEY`는 로컬 프록시 접근용 키입니다. 기본값은 개발용이므로 팀/서버 공유 시 바꾸세요.
- 프록시는 기본적으로 `127.0.0.1`에만 바인딩됩니다. 외부 공유가 필요할 때만 `LITELLM_HOST=0.0.0.0`으로 바꾸고 방화벽과 인증을 별도로 관리하세요.

## 알려진 제한

이 구성은 Claude Code의 네이티브 OpenAI 지원이 아니라 Anthropic 호환 프록시 방식입니다. 따라서 Claude 모델 전용 동작, tool use 변환, thinking 관련 파라미터, 일부 베타 헤더는 모델과 LiteLLM 버전에 따라 다르게 동작할 수 있습니다.

문제가 생기면 먼저 `./scripts/test-proxy.sh`로 LiteLLM 레벨을 확인하고, 그 다음 Claude Code 실행을 확인하세요.

## 참고

- Anthropic Claude Code LLM Gateway: https://code.claude.com/docs/en/llm-gateway
- Anthropic Claude Code Settings: https://docs.anthropic.com/en/docs/claude-code/settings
- LiteLLM Proxy Server: https://docs.litellm.ai/
