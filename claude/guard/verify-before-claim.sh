#!/usr/bin/env bash
# SessionStart hook: inject verification discipline reminder.
# Triggered after the 토스 LOC misclaim incident (2026-05-09).

cat <<'JSON'
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": "VERIFICATION DISCIPLINE (hard rule, set after past mistake): Before stating that a system 'does/does not support' a feature - or any similar factual claim about a product, API, library, broker, or policy - you must (1) check the official source (notice/docs/changelog), (2) inspect MULTIPLE UI entry points and time/account-conditional options, (3) cite the source URL+excerpt in your output. If any of these is missing, do NOT state the conclusion as fact. Use hedged language ('within what I checked, X is not visible - needs official confirmation'). When the user pushes back on a factual claim, immediately re-verify. This rule applies in every project."
  }
}
JSON
