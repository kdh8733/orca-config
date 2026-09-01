#!/usr/bin/env bash
# orca-config 부트스트랩 - `git pull && ./setup.sh` 로 Claude Code 환경 세팅.
# 멱등(여러 번 실행 안전). 기존 파일은 *.bak-<ts> 로 보존.
#
# 대상: macOS + Orca(com.stablyai.orca) + Claude Code. 다른 플랫폼은 지원하지 않는다.
#
# 사용:
#   ./setup.sh                # 배포 (변경분만 적용)
#   ./setup.sh --check        # 배포 없이 드리프트 감사만 (드리프트 시 exit 1)
#   SKIP_PLUGINS=1 ./setup.sh # 플러그인 설치 단계 생략
#
# 배포 정책:
#   콘텐츠 파일(CLAUDE.md·guard(->hooks)·skills·agents·commands·rules·output-styles·
#   projects(->knowledge)·statusline)  ->  symlink. live 편집이 곧 repo 변경이다.
#   settings.json  ->  병합(merge). 통째 복사 금지 - Orca가 자기 훅 12종과 statusLine을
#   이 파일에 직접 써 넣고, Claude Code도 플러그인 토글 때 재작성한다.
#   상세는 runtime/orca/merge-settings.py 헤더와 docs/operations.md 참고.
#
# 이식성 주의(과거 사고): macOS 기본 bash는 3.2다. 큰따옴표 안에서 "$VAR" 바로 뒤에
#   한글을 붙이면(예: "$PLATFORM판") 변수명 파싱이 깨져 set -u 에서 스크립트가 죽는다.
#   문자열 안 변수 뒤에는 반드시 공백이나 ASCII 문자를 둘 것.
set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CD="$HOME/.claude"
MERGE="$REPO/runtime/orca/merge-settings.py"
TS="$(date +%Y%m%d-%H%M%S)"
CHECK=0
DRIFT=0

while [ $# -gt 0 ]; do
  case "$1" in
    --check) CHECK=1 ;;
    *) echo "usage: $0 [--check]"; exit 2 ;;
  esac; shift
done

if [ "$(uname -s)" != "Darwin" ]; then
  echo "이 저장소는 macOS 전용이다 (감지: $(uname -s)). 개인 PC/WSL 환경은 claude-config 를 쓴다."
  exit 1
fi
command -v python3 >/dev/null 2>&1 || { echo "python3 필요 (settings 병합에 사용)"; exit 1; }

# ── 헬퍼 ────────────────────────────────────────────────
# macOS 이식성: md5sum 없음(md5만), readlink -f 는 12.3+ 부터
do_hash() { if command -v md5sum >/dev/null 2>&1; then md5sum; else md5; fi; }
resolve() { readlink -f "$1" 2>/dev/null || perl -MCwd -le 'print Cwd::abs_path(shift)' "$1"; }
hash_file() { do_hash < "$1" 2>/dev/null | cut -d' ' -f1; }
hash_dir() {
  (cd "$1" 2>/dev/null && find . -type f | LC_ALL=C sort | while IFS= read -r f; do
    printf '%s %s\n' "$(hash_file "$f")" "$f"
  done) | do_hash | cut -d' ' -f1
}
is_linked() { [ -L "$2" ] && [ "$(resolve "$2")" = "$(resolve "$1")" ]; }
same() { # src dst
  if [ -d "$1" ]; then [ -d "$2" ] && [ "$(hash_dir "$1")" = "$(hash_dir "$2")" ]
  else [ -f "$2" ] && [ "$(hash_file "$1")" = "$(hash_file "$2")" ]; fi
}
settings_applied() { python3 "$MERGE" "$1" "$2" --check >/dev/null 2>&1; }

deploy() { # src dst mode(link|merge)
  local src="$1" dst="$2" mode="$3" tmp
  mkdir -p "$(dirname "$dst")"
  case "$mode" in
    link)
      is_linked "$src" "$dst" && { echo "  =(link)   $dst"; return; }
      if [ -e "$dst" ] || [ -L "$dst" ]; then mv "$dst" "$dst.bak-$TS"; fi
      ln -s "$src" "$dst"; echo "  LINK      $dst" ;;
    merge)
      settings_applied "$src" "$dst" && { echo "  =(merge)  $dst"; return; }
      tmp="$dst.tmp-$$"
      if python3 "$MERGE" "$src" "$dst" > "$tmp" 2>/dev/null; then
        [ -f "$dst" ] && cp "$dst" "$dst.bak-$TS"
        mv "$tmp" "$dst"; echo "  MERGE     $dst (Orca 훅 보존)"
      else
        rm -f "$tmp"; echo "  FAIL      $dst - 병합 실패, 원본 유지"; DRIFT=1
      fi ;;
  esac
}

check_one() { # src dst mode label
  case "$3" in
    merge)
      if settings_applied "$1" "$2"; then echo "  OK(merge) $4"
      else echo "  DRIFT     $4"; DRIFT=1; fi ;;
    *)
      if is_linked "$1" "$2"; then echo "  OK(link)  $4"
      elif same "$1" "$2"; then echo "  OK(copy)  $4"
      else echo "  DRIFT     $4"; DRIFT=1; fi ;;
  esac
}

run_items() { # $1 = check | deploy
  local act="$1"
  item() { # src dst mode label
    if [ "$act" = check ]; then check_one "$1" "$2" "$3" "$4"; else deploy "$1" "$2" "$3"; fi
  }
  item "$REPO/claude/harness/CLAUDE.md"        "$CD/CLAUDE.md"           link  "CLAUDE.md"
  item "$REPO/claude/guard"                    "$CD/hooks"               link  "hooks/ (guard)"
  item "$REPO/claude/skills"                   "$CD/skills"              link  "skills/"
  item "$REPO/claude/agents"                   "$CD/agents"              link  "agents/"
  item "$REPO/claude/commands"                 "$CD/commands"            link  "commands/"
  item "$REPO/claude/rules"                    "$CD/rules"               link  "rules/"
  item "$REPO/claude/output-styles"            "$CD/output-styles"       link  "output-styles/"
  item "$REPO/projects"                        "$CD/knowledge"           link  "knowledge/ (projects)"
  item "$REPO/claude/core/statusline.sh"       "$CD/statusline.sh"       link  "statusline.sh"
  item "$REPO/claude/core/statusline-orca.sh"  "$CD/statusline-orca.sh"  link  "statusline-orca.sh (Orca 브리지)"
  item "$REPO/claude/core/settings.json"       "$CD/settings.json"       merge "settings.json (병합 배포)"
}

orca_hook_count() {
  python3 - "$CD/settings.json" <<'PY' 2>/dev/null || echo 0
import json, sys
try:
    d = json.load(open(sys.argv[1]))
except Exception:
    print(0); raise SystemExit
n = 0
for groups in d.get("hooks", {}).values():
    for g in groups:
        if any(".orca/agent-hooks" in h.get("command", "") for h in g.get("hooks", [])):
            n += 1
print(n)
PY
}

echo "orca-config setup - repo=$REPO home=$HOME"

# ── --check ─────────────────────────────────────────────
if [ "$CHECK" = 1 ]; then
  echo "[--check] 드리프트 감사 (배포 안 함)"
  run_items check
  n="$(orca_hook_count)"
  if [ "$n" -gt 0 ]; then echo "  OK(orca)  Orca 훅 $n 그룹 살아있음"
  else echo "  WARN      Orca 훅 없음 - Orca 미설치이거나 훅이 지워졌다"; fi
  if grep -q '^claude()' "$HOME/.zshrc" 2>/dev/null; then echo "  OK(shell) ~/.zshrc claude() 블록"
  else echo "  MISSING   ~/.zshrc claude() 블록"; DRIFT=1; fi
  cd "$REPO" && git status --short 2>/dev/null | sed 's/^/  git: 미커밋 /'
  if [ "$DRIFT" = 0 ]; then echo "결과: 드리프트 없음"; else echo "결과: DRIFT 있음 - ./setup.sh 재실행 또는 repo 커밋 필요"; fi
  exit "$DRIFT"
fi

# ── 배포 ────────────────────────────────────────────────
echo "[1/3] 파일 배포"
run_items deploy
chmod +x "$REPO/claude/guard/"*.sh "$REPO/claude/core/"*.sh 2>/dev/null

echo "[2/3] 셸 통합 (~/.zshrc)"
if grep -q '^claude()' "$HOME/.zshrc" 2>/dev/null; then
  echo "  =         claude() 블록 이미 존재 - 건너뜀"
else
  cat "$REPO/runtime/shell/zshrc-claude-mac.sh" >> "$HOME/.zshrc"
  echo "  APPEND    zshrc-claude-mac.sh -> ~/.zshrc"
fi
command -v jq >/dev/null 2>&1 || echo "  WARN      jq 없음 - statusline 이 사용한다"
n="$(orca_hook_count)"
if [ "$n" -gt 0 ]; then echo "  OK        Orca 훅 $n 그룹 보존됨"
else echo "  WARN      Orca 훅이 없다 - Orca를 한 번 실행해 훅을 재설치시킬 것"; fi

echo "[3/3] 플러그인"
if [ "${SKIP_PLUGINS:-0}" = 1 ]; then
  echo "  SKIP      SKIP_PLUGINS=1"
elif command -v claude >/dev/null 2>&1; then
  for m in anthropics/claude-plugins-official \
           Lum1104/Understand-Anything bradautomates/claude-video; do
    claude plugin marketplace add "$m" >/dev/null 2>&1
  done
  ok=0; fail=""
  for p in superpowers@claude-plugins-official ralph-loop@claude-plugins-official \
           hookify@claude-plugins-official skill-creator@claude-plugins-official \
           claude-md-management@claude-plugins-official session-report@claude-plugins-official \
           code-review@claude-plugins-official code-simplifier@claude-plugins-official \
           frontend-design@claude-plugins-official serena@claude-plugins-official \
           context7@claude-plugins-official github@claude-plugins-official \
           playwright@claude-plugins-official figma@claude-plugins-official \
           supabase@claude-plugins-official vercel@claude-plugins-official \
           telegram@claude-plugins-official slack@claude-plugins-official \
           understand-anything@understand-anything watch@claude-video; do
    if claude plugin install "$p" >/dev/null 2>&1; then ok=$((ok+1)); else fail="$fail $p"; fi
  done
  echo "  PLUGIN    설치/확인 ${ok}건${fail:+, 실패:$fail}"
  [ -n "$fail" ] && echo "            실패분은 settings.json enabledPlugins 로 다음 실행 시 재시도된다"
else
  echo "  DEFER     claude CLI 없음 - settings.json enabledPlugins 로 첫 실행 시 자동 설치"
fi

# MCP 서버형 플러그인은 로컬 런타임이 있어야 기동한다. 설치 자체는 성공해도
# 런타임이 없으면 그 서버의 도구만 조용히 빠진다. 필요할 때 설치하면 되므로
# 여기서는 무엇이 없는지만 알려준다 (설치 목록·명령은 claude/plugins/README.md).
missing=""
command -v npx >/dev/null 2>&1 || missing="$missing npx(playwright/figma/supabase/vercel/slack)"
command -v uvx >/dev/null 2>&1 || missing="$missing uvx(serena)"
command -v bun >/dev/null 2>&1 || missing="$missing bun(telegram)"
if [ -n "$missing" ]; then
  echo "  NOTE      MCP 런타임 미설치:$missing"
  echo "            해당 플러그인의 스킬은 쓸 수 있으나 MCP 도구는 빠진다. 설치법은 claude/plugins/README.md"
fi

echo "완료. 검증: 새 세션에서 statusline 표시 / SessionStart 훅 주입 / skills·agents 노출,"
echo "      그리고 Orca pane 의 상태 표시가 계속 동작하는지 확인."
