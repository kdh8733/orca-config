#!/usr/bin/env python3
"""~/.claude/settings.json 병합기 - Orca가 주입한 훅을 지우지 않고 repo 정책을 얹는다.

배경: Orca(com.stablyai.orca)는 앱 실행 중 자기 pane 상태 추적을 위해
      ~/.claude/settings.json 의 hooks 12종과 statusLine 을 직접 편집한다.
      Claude Code 자신도 플러그인 enable/disable 때 이 파일을 재작성한다.
      즉 이 파일은 repo가 단독 소유할 수 없다. 통째 복사로 배포하면 Orca가 깨진다.

소유권 규칙 (훅 커맨드 문자열로 판정):
  - '.orca/agent-hooks'  포함  -> Orca 소유. 절대 건드리지 않고 그대로 보존.
  - '.claude/hooks/'     포함  -> 이 repo 소유. 매번 repo 정의로 교체(제거도 반영).
  - 그 외                      -> 정체불명(수동 추가 등). 보존.
훅 이외의 최상위 키는 repo에 있으면 repo가 이기고, repo에 없으면 live 값을 보존한다
(예: Orca/Claude Code가 쓰는 theme, 사용자가 /config 로 바꾼 값).

사용:
  merge-settings.py <repo-settings.json> <live-settings.json>            # 병합 결과를 stdout
  merge-settings.py <repo-settings.json> <live-settings.json> --check    # 같으면 0, 다르면 1
"""
import json
import sys

ORCA_MARK = ".orca/agent-hooks"
REPO_MARK = ".claude/hooks/"


def load(path):
    try:
        with open(path) as fh:
            return json.load(fh)
    except (IOError, OSError):
        return {}


def owner(group):
    """훅 그룹 하나의 소유자를 판정한다. 커맨드가 섞여 있으면 Orca 쪽을 우선 보존한다."""
    cmds = [h.get("command", "") for h in group.get("hooks", [])]
    if any(ORCA_MARK in c for c in cmds):
        return "orca"
    if any(REPO_MARK in c for c in cmds):
        return "repo"
    return "unknown"


def merge_hooks(repo_hooks, live_hooks):
    merged = {}
    for event in set(list(repo_hooks.keys()) + list(live_hooks.keys())):
        kept = [g for g in live_hooks.get(event, []) if owner(g) != "repo"]
        merged_event = kept + repo_hooks.get(event, [])
        if merged_event:
            merged[event] = merged_event
    return merged


def merge(repo, live):
    out = json.loads(json.dumps(live))  # deep copy
    for key, value in repo.items():
        if key == "hooks":
            continue
        out[key] = value
    hooks = merge_hooks(repo.get("hooks", {}), live.get("hooks", {}))
    if hooks:
        out["hooks"] = hooks
    elif "hooks" in out:
        del out["hooks"]
    return out


def main():
    args = sys.argv[1:]
    check = "--check" in args
    args = [a for a in args if a != "--check"]
    if len(args) != 2:
        sys.stderr.write(__doc__)
        return 2

    repo, live = load(args[0]), load(args[1])
    result = merge(repo, live)

    if check:
        return 0 if result == live else 1

    sys.stdout.write(json.dumps(result, indent=2, sort_keys=True, ensure_ascii=False) + "\n")
    return 0


if __name__ == "__main__":
    sys.exit(main())
