# 운영 가이드 (배포 모델 · Orca 공존 · 시크릿)

> README는 구조와 철학만 담는다. 배포·운영의 상세는 이 문서가 원천.

## 대상 환경

| 항목 | 값 | 확인일 |
|---|---|---|
| OS | macOS 26.6.2 (Darwin 25.6.0, arm64) | 2026-09-01 |
| 셸 | zsh (`~/.zshrc`), 스크립트는 `/bin/bash` = **bash 3.2** | 2026-09-01 |
| 터미널/세션 관리 | Orca 1.4.194 (`com.stablyai.orca`) | 2026-09-01 |
| Claude Code | 2.1.252 (`~/.local/bin/claude`, 네이티브 설치) | 2026-09-01 |
| 있는 도구 | jq · python3 · git · gh · crontab | 2026-09-01 |
| 없는 도구 | node · npx · bun · uv/uvx · brew · tmux | 2026-09-01 |

플러그인 20종은 전부 설치한다. MCP 서버형은 로컬 런타임(npx·uvx·bun)이 있어야 서버가
기동하지만, 없어도 스킬은 그대로 쓸 수 있고 그 서버의 도구만 빠진다. 그래서 런타임을
미리 깔지 않고 필요해진 시점에 설치한다 - `./setup.sh` 가 매번 무엇이 없는지 NOTE 로
알려주고, 설치 명령은 `claude/plugins/README.md` 의 "런타임 설치" 표에 있다.

macOS 전용이다. 다른 플랫폼에서 실행하면 `setup.sh` 가 거부한다.
개인 PC(WSL2 + aoe) 환경은 별도 저장소 `claude-config` 가 담당하며, 두 저장소를
합치지 않는다 - 세션 매니저(aoe vs Orca)가 settings.json 을 다루는 방식이 다르다.

### bash 3.2 주의 (실제 사고)

macOS 기본 bash 는 3.2다. 큰따옴표 안에서 `"$VAR"` 바로 뒤에 한글을 붙이면
(`"$PLATFORM판"`) 변수명 파싱이 깨져 `set -u` 에서 스크립트가 죽는다.
개인 PC의 `claude-config/setup.sh` 는 이 이유로 맥에서 한 번도 완주하지 못했다
(`line 134: PLATFORM판: unbound variable`). 문자열 안 변수 뒤에는 공백이나
ASCII 문자를 둘 것.

## 사용법

```bash
./setup.sh                  # 배포 (멱등 - 변경분만 적용)
./setup.sh --check          # 드리프트 감사. 변경 없음, 드리프트 발견 시 exit 1
SKIP_PLUGINS=1 ./setup.sh   # 플러그인 설치 단계 생략
```

## 배포 모델

| 대상 | 방식 | 근거 |
|---|---|---|
| 콘텐츠 파일¹ | symlink | live 편집이 곧 repo 변경 - 동기화 단계가 구조적으로 제거된다 |
| `claude/core/settings.json` | **병합(merge)** | Orca와 Claude Code가 같은 파일을 쓴다. 복사하면 Orca가 깨진다 |
| `runtime/shell/zshrc-claude-mac.sh` | `~/.zshrc` 에 1회 append | `claude()` 블록 존재 여부로 멱등 |

¹ `harness/CLAUDE.md` · `core/statusline.sh` · `core/statusline-orca.sh` · `guard/`(→hooks)
· `skills/` · `agents/` · `commands/` · `rules/` · `output-styles/` · `projects/`(→knowledge)

기존 파일은 덮어쓰기 전에 `*.bak-<타임스탬프>` 로 보존한다.

## Orca 공존 (이 저장소의 핵심 제약)

Orca 는 `~/.claude/settings.json` 에 hook 12 이벤트(SessionStart · UserPromptSubmit ·
Stop · StopFailure · SubagentStart · SubagentStop · TeammateIdle · PreToolUse ·
PostToolUse · PostToolUseFailure · PermissionRequest · PostCompact)와 statusLine 을
주입한다. 전부 `~/.orca/agent-hooks/claude-hook.sh` 를 호출해 pane 상태를
`127.0.0.1` 로컬 서버로 전송하는 구조다. 이게 죽으면 Orca UI 의 pane 상태 표시와
사용량 표시가 멈춘다.

- **절대 하지 말 것**: `~/.claude/settings.json` 을 통째로 덮어쓰기.
- 병합 규칙은 `runtime/orca/merge-settings.py` 헤더에 있다. 요약하면 훅 커맨드에
  `.orca/agent-hooks` 가 있으면 보존, `.claude/hooks/` 가 있으면 repo 정의로 교체,
  나머지는 보존. 훅 이외 최상위 키는 repo에 있으면 repo가 이기고 없으면 live 보존.
- **한계(정직)**: repo 에서 훅을 지우면 live 에서도 지워지지만(`.claude/hooks/` 마커
  기준), 정체불명 훅은 자동으로 정리하지 않는다. 수동 확인이 필요하다.
- Orca 가 나중에 statusLine 을 자기 것으로 되돌리면 `--check` 가 DRIFT 로 잡고
  `./setup.sh` 재실행이 브리지로 복구한다. Orca 훅 자체는 그대로 살아남는다.

### statusLine 브리지

슬롯은 하나인데 소비자가 둘이라 `claude/core/statusline-orca.sh` 가 중계한다:
stdin payload 를 받아 ① Orca 의 `claude-statusline.sh` 에 먹이고(화면 출력 없음,
15초 스로틀 + curl 0.5/1.5s 타임아웃) ② `statusline.sh` 로 터미널에 렌더한다.
Orca 가 없으면 ②만 수행한다. 측정 결과 브리지 왕복은 0.2초 수준이다.

## 드리프트 감사

```bash
./setup.sh --check
```

repo ↔ live 배포 대상을 비교해 `OK(link) / OK(merge) / DRIFT / MISSING` 으로 보고하고,
Orca 훅 생존 개수와 `~/.zshrc` 통합 여부, 커밋되지 않은 repo 변경을 함께 표시한다.
대화형 감사가 필요하면 `env-auditor` 서브에이전트를 쓴다(읽기 전용).

## Secrets

이 저장소는 시크릿을 포함하지 않는다. `.gitignore` 가 토큰·credentials 패턴을 막는다.

| 시크릿 | 위치 | 확보 방법 |
|---|---|---|
| Claude Code 자격증명 | macOS 키체인(`Claude Code-credentials`) 또는 `~/.claude/.credentials.json` | `claude` 첫 실행 시 로그인 |
| Context7 API 키 | 환경변수 `CONTEXT7_API_KEY` | context7 MCP 도구를 실제로 쓸 때 |
| GitHub PAT | 환경변수 `GITHUB_PERSONAL_ACCESS_TOKEN` | github MCP 도구를 실제로 쓸 때. 업무 계정 정책 확인 필요 |

## 검토 대기 항목

- **권한 모드**: 개인 PC 설정에는 `permissions.defaultMode = bypassPermissions` 와
  `skipDangerousModePermissionPrompt = true` 가 있었다. 업무용 머신이라 기본값으로
  두었다. 필요하면 `claude/core/settings.json` 에 아래를 넣고 재배포한다.
  ```json
  "permissions": { "defaultMode": "bypassPermissions" },
  "skipDangerousModePermissionPrompt": true
  ```
- **원격 저장소**: 아직 로컬 git 저장소만 있다. 업무 코드/설정을 어디에 올릴지
  (회사 GitHub Enterprise vs 개인 계정 private) 결정 후 remote 를 붙인다.

## 변경 워크플로

```
live 편집(= symlink 라 repo가 바뀜) 또는 repo 직접 편집
  → ./setup.sh --check 로 확인
  → git commit
  → (원격이 생기면) push
```
