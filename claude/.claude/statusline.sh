#!/usr/bin/env bash
# Claude Code status line.
#
# Line 1: model · git branch · effort · worktree
# Line 2: context-window bar · 5h and 7d rate limits
#
# Optional Linear integration — set both in ~/.locals to turn matching branch
# names into OSC-8 hyperlinks to the corresponding issue. Unset (the default),
# branches render as plain text and nothing else changes.
#
#   CLAUDE_STATUSLINE_LINEAR_ORG=acme        # linear.app/<org>
#   CLAUDE_STATUSLINE_TICKET_PREFIX=ACME     # branches like ACME-123

set -uo pipefail

LINEAR_ORG="${CLAUDE_STATUSLINE_LINEAR_ORG:-}"
TICKET_PREFIX="${CLAUDE_STATUSLINE_TICKET_PREFIX:-}"

# ---------- Guard: jq required ----------
if ! command -v jq >/dev/null 2>&1; then
  printf 'statusline: jq required\n'
  exit 0
fi

JSON="$(cat)"
if [[ -z "$JSON" ]]; then
  exit 0
fi

# ---------- ANSI ----------
RESET=$'\e[0m'
DIM=$'\e[90m'
GREEN=$'\e[32m'
YELLOW=$'\e[33m'
RED=$'\e[31m'

# ---------- Helpers ----------
pct_color() {
  local p="$1"
  if   (( p >= 80 )); then printf '%s' "$RED"
  elif (( p >= 20 )); then printf '%s' "$YELLOW"
  else                     printf '%s' "$GREEN"
  fi
}

render_bar() {
  local pct="$1" width="$2"
  local empty_str
  empty_str=$(printf '░%.0s' $(seq 1 "$width"))

  if [[ -z "$pct" || "$pct" == "null" || "$pct" == "-" ]]; then
    printf '[%s%s%s] --%%' "$DIM" "$empty_str" "$RESET"
    return
  fi

  # guard against non-numeric values
  if ! [[ "$pct" =~ ^-?[0-9]+(\.[0-9]+)?$ ]]; then
    printf '[%s%s%s] --%%' "$DIM" "$empty_str" "$RESET"
    return
  fi

  pct=$(printf '%.0f' "$pct")
  (( pct < 0 )) && pct=0
  (( pct > 100 )) && pct=100

  local filled=$(( pct * width / 100 ))
  local empty=$(( width - filled ))

  local color
  color=$(pct_color "$pct")

  local fill_str=""
  (( filled > 0 )) && fill_str=$(printf '█%.0s' $(seq 1 "$filled"))
  local empty_part=""
  (( empty > 0 )) && empty_part=$(printf '░%.0s' $(seq 1 "$empty"))

  printf '[%s%s%s%s%s%s] %d%%' \
    "$color" "$fill_str" "$RESET" \
    "$DIM" "$empty_part" "$RESET" \
    "$pct"
}

fmt_5h() {
  local secs="$1"
  (( secs < 0 )) && secs=0
  local h=$(( secs / 3600 ))
  local m=$(( (secs % 3600) / 60 ))
  if (( h > 0 )); then
    printf '%dh%02dm' "$h" "$m"
  else
    printf '%dm' "$m"
  fi
}

fmt_7d() {
  local secs="$1"
  (( secs < 0 )) && secs=0
  local d=$(( secs / 86400 ))
  local h=$(( (secs % 86400) / 3600 ))
  if (( d >= 1 )); then
    printf '%dd' "$d"
  else
    printf '%dh' "$h"
  fi
}

osc8() {
  local url="$1" text="$2"
  printf '\e]8;;%s\e\\%s\e]8;;\e\\' "$url" "$text"
}

linear_url() {
  local ticket="$1"
  printf 'https://linear.app/%s/issue/%s' "$LINEAR_ORG" "$ticket"
}

git_branch() {
  git symbolic-ref --short HEAD 2>/dev/null
}

join_chunks() {
  local sep="$1"; shift
  local first=1
  local c
  for c in "$@"; do
    if [[ $first -eq 1 ]]; then
      printf '%s' "$c"
      first=0
    else
      printf '%s%s' "$sep" "$c"
    fi
  done
}

# ---------- Extract fields ----------
# All 9 fields in one jq call; sentinel "-" for every missing value.
# Using "-" (non-empty) prevents IFS=$'\t' read from collapsing leading empty tokens.
IFS=$'\t' read -r MODEL_NAME MODEL_ID CTX_PCT EFFORT WORKTREE \
                   RL5_PCT RL5_RESETS RL7_PCT RL7_RESETS < <(
  jq -r '[
    (.model.display_name          // "-"),
    (.model.id                    // "-"),
    (.context_window.used_percentage // "-"),
    (.effort.level                // "-"),
    (.worktree.name               // "-"),
    (.rate_limits.five_hour.used_percentage // "-"),
    (.rate_limits.five_hour.resets_at       // "-"),
    (.rate_limits.seven_day.used_percentage // "-"),
    (.rate_limits.seven_day.resets_at       // "-")
  ] | @tsv' <<<"$JSON"
)

NOW=$(date +%s)

# ---------- Line 1: identity ----------
chunks1=()

model_display=""
if [[ "$MODEL_NAME" != "-" ]]; then
  model_display="$MODEL_NAME"
fi
if [[ "$MODEL_ID" == *"[1m]" ]]; then
  model_display+='[1M]'
fi
[[ -n "$model_display" ]] && chunks1+=("🤖 ${model_display}")

branch="$(git_branch)"
if [[ -n "$branch" ]]; then
  # Link the branch to its Linear issue only when both settings are present
  # and the branch looks like <PREFIX>-<number>; otherwise render it plain.
  if [[ -n "$LINEAR_ORG" && -n "$TICKET_PREFIX" \
        && "$branch" =~ ^"$TICKET_PREFIX"-[0-9]+$ ]]; then
    url="$(linear_url "$branch")"
    badge="$(osc8 "$url" "$branch")"
    chunks1+=("🌿 ${badge}")
  else
    chunks1+=("🌿 ${branch}")
  fi
fi

[[ -n "$EFFORT"   && "$EFFORT"   != "-" ]] && chunks1+=("🎯 ${EFFORT}")
[[ -n "$WORKTREE" && "$WORKTREE" != "-" ]] && chunks1+=("🌲 ${WORKTREE}")

# ---------- Line 2: usage ----------
chunks2=()
chunks2+=("$(render_bar "$CTX_PCT" 28)")

if [[ "$RL5_PCT" != "-" && "$RL5_RESETS" != "-" ]]; then
  pct=$(printf '%.0f' "$RL5_PCT")
  remain=$(( RL5_RESETS - NOW ))
  chunks2+=("⏳ 5h ${pct}% (resets $(fmt_5h "$remain"))")
fi

if [[ "$RL7_PCT" != "-" && "$RL7_RESETS" != "-" ]]; then
  pct=$(printf '%.0f' "$RL7_PCT")
  remain=$(( RL7_RESETS - NOW ))
  chunks2+=("📅 7d ${pct}% (resets $(fmt_7d "$remain"))")
fi

# ---------- Output ----------
join_chunks ' · ' "${chunks1[@]-}"
printf '\n'
join_chunks '  '  "${chunks2[@]-}"
printf '\n'
