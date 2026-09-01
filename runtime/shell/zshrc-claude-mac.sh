
# ── claude-config(orca-config) 셸 통합 ─────────────────────────────
# 무인자로 치면 현재 디렉토리의 최근 세션을 재개한다. 인자가 있으면 그대로 넘긴다.
# Orca가 띄운 pane 안에서는 Orca가 세션/워크트리를 직접 관리하므로 --continue 를
# 붙이지 않는다 (붙이면 Orca가 의도한 세션과 다른 세션이 열릴 수 있다).
claude() {
    if [ -n "$ORCA_PANE_KEY" ] || [ $# -gt 0 ]; then
        command claude "$@"
    else
        command claude --continue || command claude
    fi
}
