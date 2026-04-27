# Claude Code Azure OpenAI 프록시 사용 가이드

이 레포는 Claude Code를 Azure OpenAI 모델과 함께 쓰기 위한 로컬 실행 템플릿입니다.

Claude Code는 OpenAI/Azure OpenAI API 키를 직접 넣는 방식을 공식 지원하지 않습니다. 그래서 중간에 LiteLLM 프록시를 띄우고, Claude Code가 이 프록시를 Anthropic API처럼 바라보게 만듭니다.

```text
Claude Code -> LiteLLM 프록시 -> Azure OpenAI GPT-5.5 배포
```

## 한 번만 준비할 것

아래 프로그램이 설치되어 있어야 합니다.

- Claude Code CLI
- `uvx`
- Azure OpenAI GPT-5.5 배포

설치 여부는 아래 명령으로 확인합니다.

```bash
claude --version
uvx --version
```

## 처음 설정하기

레포 폴더로 이동합니다.

```bash
cd /Users/gim-wontae/Desktop/Persnal_Project/claude-code-azure-openai-proxy
```

`.env` 파일을 만듭니다.

```bash
make setup
```

`.env` 파일을 열고 Azure OpenAI 정보를 입력합니다.

```bash
AZURE_API_KEY=여기에_Azure_OpenAI_API_Key_입력
AZURE_API_BASE=https://your-resource-name.openai.azure.com
AZURE_API_VERSION=2025-03-01-preview
AZURE_DEPLOYMENT_NAME=your-gpt-55-deployment-name
```

주의할 점:

- `AZURE_API_BASE`는 Azure OpenAI 리소스의 endpoint입니다.
- `AZURE_DEPLOYMENT_NAME`은 모델 이름이 아니라 Azure에서 만든 deployment name입니다.
- `AZURE_API_VERSION`은 `2025-03-01-preview` 이상이어야 합니다.
- `.env`는 Git에 올라가지 않도록 무시 처리되어 있습니다.

설정이 맞는지 확인합니다.

```bash
make doctor
```

`env ok`가 나오면 준비가 끝난 것입니다.

## 매번 사용하는 방법

터미널을 2개 열어서 사용합니다.

### 터미널 1: 프록시 실행

```bash
cd /Users/gim-wontae/Desktop/Persnal_Project/claude-code-azure-openai-proxy
make proxy
```

이 터미널은 Claude Code를 쓰는 동안 계속 켜두세요. 닫으면 Claude Code가 Azure OpenAI로 요청을 보낼 수 없습니다.

### 터미널 2: 연결 테스트

처음 실행할 때는 프록시가 잘 동작하는지 확인합니다.

```bash
cd /Users/gim-wontae/Desktop/Persnal_Project/claude-code-azure-openai-proxy
make test
```

아래처럼 응답이 오면 성공입니다.

```json
{
  "model": "gpt-5.5",
  "content": [
    {
      "type": "text",
      "text": "The proxy works."
    }
  ]
}
```

### 터미널 2: Claude Code 실행

현재 레포에서 Claude Code를 실행하려면 아래 명령을 씁니다.

```bash
make claude
```

다른 프로젝트에서 Claude Code를 실행하려면, 먼저 그 프로젝트 폴더로 이동한 뒤 이 레포의 실행 스크립트를 호출합니다.

```bash
cd /path/to/your/project
/Users/gim-wontae/Desktop/Persnal_Project/claude-code-azure-openai-proxy/scripts/claude-via-azure-openai.sh
```

Claude Code 화면에서 API key 사용 여부를 물어보면 `Yes`를 선택하세요. 이 키는 실제 Anthropic 키가 아니라 로컬 LiteLLM 프록시에 접근하기 위한 키입니다.

이 실행 스크립트는 기본적으로 전역 Claude Code 설정을 쓰지 않고, 이 레포 안의 `.claude-runtime/`을 임시 설정 디렉터리로 사용합니다. 이렇게 하면 개인 PC의 전역 훅, 플러그인, 메모리 도구가 붙어서 OpenAI 계열 모델에 불필요한 컨텍스트가 들어가는 문제를 줄일 수 있습니다.

전역 Claude Code 설정을 그대로 쓰고 싶다면 `.env`에서 아래 값을 바꾸세요.

```bash
CLAUDE_CODE_USE_CLEAN_CONFIG=0
```

## 종료 방법

Claude Code는 Claude Code 화면에서 종료합니다.

```text
/exit
```

프록시는 `make proxy`가 실행 중인 터미널에서 `Ctrl-C`로 종료합니다.

터미널을 잃어버렸거나 예전 프록시가 계속 살아 있으면 아래 명령으로 4000번 포트의 프록시를 종료할 수 있습니다.

```bash
make stop
```

프록시를 완전히 재시작하려면 아래 명령을 씁니다.

```bash
make restart
```

## 내부 동작 방식

`scripts/claude-via-azure-openai.sh`는 Claude Code 실행 전에 아래 환경변수를 설정합니다.

```bash
ANTHROPIC_BASE_URL=http://127.0.0.1:4000
ANTHROPIC_AUTH_TOKEN=$LITELLM_MASTER_KEY
ANTHROPIC_MODEL=gpt-5.5
ANTHROPIC_DEFAULT_SONNET_MODEL=gpt-5.5
ANTHROPIC_DEFAULT_HAIKU_MODEL=gpt-5.5
CLAUDE_CODE_SUBAGENT_MODEL=gpt-5.5
CLAUDE_CONFIG_DIR=/path/to/this-repo/.claude-runtime
```

Claude Code 입장에서는 `http://127.0.0.1:4000`에 있는 Anthropic 호환 API를 호출합니다. 실제로는 LiteLLM이 이 요청을 Azure OpenAI 요청으로 변환합니다.

모델 연결은 `config/litellm.config.yaml` 템플릿을 사용합니다.

```yaml
model_list:
  - model_name: __CLAUDE_CODE_MODEL_ALIAS__
    litellm_params:
      model: azure/__AZURE_DEPLOYMENT_NAME__
```

`make proxy`를 실행하면 `.env` 값을 읽어서 `.generated/litellm.config.yaml`을 만들고 LiteLLM을 실행합니다.

## 연결은 됐는데 이상한 답변이 나오는 경우

프록시 로그에 아래처럼 `200 OK`가 보이면 연결 자체는 된 것입니다.

```text
POST /v1/messages?beta=true HTTP/1.1" 200 OK
```

그런데 단순 인사에도 `I'm sorry, but I cannot assist with that request.` 같은 답변이 나오면 보통 연결 문제가 아니라 Claude Code의 전역 훅/플러그인/메모리 컨텍스트가 OpenAI 계열 모델과 맞지 않게 섞인 상태입니다.

이 레포의 기본 실행 방식은 `.claude-runtime/` 격리 설정을 사용하므로, 아래 순서로 새 세션을 다시 여세요.

```bash
make restart
make claude
```

이미 열려 있는 Claude Code 화면에서는 `/exit`로 종료한 뒤 다시 실행하는 것이 가장 깔끔합니다.

## 자주 나는 오류

### 1. Azure Responses API version 오류

오류 메시지:

```text
Azure OpenAI Responses API is enabled only for api-version 2025-03-01-preview and later
```

해결:

`.env`에서 `AZURE_API_VERSION`을 `2025-03-01-preview` 이상으로 바꿉니다.

```bash
AZURE_API_VERSION=2025-03-01-preview
```

그 다음 프록시를 재시작합니다.

```bash
make restart
```

### 2. Auth conflict 경고

오류 메시지:

```text
Auth conflict: Both a token (ANTHROPIC_AUTH_TOKEN) and an API key (ANTHROPIC_API_KEY) are set.
```

해결:

최신 스크립트는 `ANTHROPIC_API_KEY`를 사용하지 않고 `ANTHROPIC_AUTH_TOKEN`만 사용합니다. 아래 명령으로 최신 변경을 받은 뒤 다시 실행하세요.

```bash
git pull
make claude
```

로컬 셸에 `ANTHROPIC_API_KEY`가 직접 설정되어 있다면 해제합니다.

```bash
unset ANTHROPIC_API_KEY
```

### 3. 프록시 연결 실패

오류 예시:

```text
Connection refused
Could not connect to 127.0.0.1:4000
```

해결:

프록시가 켜져 있는지 확인합니다.

```bash
make proxy
```

프록시는 Claude Code를 쓰는 동안 계속 실행되어 있어야 합니다.

### 4. 모델 또는 deployment 오류

오류 예시:

```text
DeploymentNotFound
The API deployment for this resource does not exist
```

해결:

`.env`의 `AZURE_DEPLOYMENT_NAME`이 Azure OpenAI Studio의 deployment name과 정확히 같은지 확인하세요.

```bash
AZURE_DEPLOYMENT_NAME=your-gpt-55-deployment-name
```

## 팀 공유 시 주의사항

- `.env`는 절대 GitHub에 올리지 않습니다.
- 팀원은 각자 `.env.example`을 복사해서 자신의 `.env`를 만듭니다.
- `LITELLM_MASTER_KEY`는 로컬 프록시 접근용 키입니다. 개인 로컬 사용이면 기본값을 써도 됩니다.
- 여러 명이 공용 서버에서 프록시를 공유한다면 `LITELLM_MASTER_KEY`를 반드시 바꾸고 접근 제어를 따로 설정하세요.
- 기본 프록시 주소는 `127.0.0.1`입니다. 외부 접속을 열어야 하는 상황이 아니라면 변경하지 마세요.

## GitHub에 올리는 방법

처음 원격 저장소를 만들 때:

```bash
gh repo create claude-code-azure-openai-proxy --private --source=. --remote=origin --push
```

이미 원격 저장소가 있다면:

```bash
git remote add origin <github-repo-url>
git push -u origin main
```

## 참고 문서

- Claude Code LLM Gateway: https://code.claude.com/docs/en/llm-gateway
- Claude Code Settings: https://docs.anthropic.com/en/docs/claude-code/settings
- LiteLLM Docs: https://docs.litellm.ai/
