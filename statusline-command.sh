#!/bin/bash
input=$(cat)

cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // ""')
model=$(echo "$input" | jq -r '.model.display_name // ""')
ctx_size=$(echo "$input" | jq -r '.context_window.context_window_size // 0')
input_tokens=$(echo "$input" | jq -r '.context_window.total_input_tokens // 0')
output_tokens=$(echo "$input" | jq -r '.context_window.total_output_tokens // 0')
cost_usd=$(echo "$input" | jq -r '.cost.total_cost_usd // 0')
transcript=$(echo "$input" | jq -r '.transcript_path // ""')
duration_ms=$(echo "$input" | jq -r '.cost.total_duration_ms // 0')
lines_add=$(echo "$input" | jq -r '.cost.total_lines_added // 0')
lines_del=$(echo "$input" | jq -r '.cost.total_lines_removed // 0')
ctx_used=$(echo "$input" | jq -r '.context_window.used_percentage // 0')
rl_5h=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
rl_5h_reset=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
rl_7d=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
rl_7d_reset=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // empty')

dir=$(basename "$cwd")
branch=$(GIT_OPTIONAL_LOCKS=0 git -C "$cwd" symbolic-ref --short HEAD 2>/dev/null || GIT_OPTIONAL_LOCKS=0 git -C "$cwd" rev-parse --short HEAD 2>/dev/null)
remote_url=$(GIT_OPTIONAL_LOCKS=0 git -C "$cwd" remote get-url origin 2>/dev/null)
repo_url=""
if [ -n "$remote_url" ]; then
  repo_url=$(echo "$remote_url" | sed -e 's|^git@\([^:]*\):|https://\1/|' -e 's|\.git$||')
fi

venv=""
if [ -n "$VIRTUAL_ENV" ]; then
  venv=" ($(basename "$VIRTUAL_ENV"))"
fi

total=$((input_tokens + output_tokens))
if [ "$total" -ge 1000000 ]; then
  tokens=$(printf "%.1fM" "$(echo "$total / 1000000" | bc -l)")
elif [ "$total" -ge 1000 ]; then
  tokens=$(printf "%.1fk" "$(echo "$total / 1000" | bc -l)")
else
  tokens="${total}"
fi

# Platform-aware date formatting (macOS: date -r, Linux: date -d @)
ts_date() {
  if date -r 0 +%s >/dev/null 2>&1; then
    date -r "$1" +"$2" 2>/dev/null || echo ""
  else
    date -d "@$1" +"$2" 2>/dev/null || echo ""
  fi
}

fmt_reset() {
  if [ -n "$1" ] && [ "$1" != "null" ]; then
    _hour=$(ts_date "$1" "%-H")
    [ -z "$_hour" ] && _hour=0
    _h=$(( _hour % 12 ))
    [ "$_h" -eq 0 ] && _h=12
    i_clock=$(printf '\xEE\x8E'"$(printf '\\x%02x' $(( 0x80 + _h )))")
    ts_date "$1" "%-d/%-m ${i_clock}%Hh"
  fi
}

# Remote path translation (set CLAUDE_SSH_HOST=fedora-vm on remote)
make_vscode_url() {
  if [ -n "$CLAUDE_SSH_HOST" ]; then
    echo "vscode://vscode-remote/ssh-remote+${CLAUDE_SSH_HOST}$1"
  else
    echo "vscode://file$1"
  fi
}

make_folder_url() {
  if [ -n "$CLAUDE_SSH_HOST" ]; then
    echo "vscode://vscode-remote/ssh-remote+${CLAUDE_SSH_HOST}$1"
  else
    echo "file://$1"
  fi
}

# Nerd Font icons
i_folder=$(printf '\xEF\x81\xBB')
i_git=$(printf '\xEE\x9C\xA5')
i_tokens=$(printf '\xEF\x8B\x9B')
i_model=$(printf '\xEF\x84\xB5')
i_ctx=$(printf '\xEF\x87\x80')
i_rate=$(printf '\xEF\x80\x83')

# Powerline round glyphs
lc=$(printf '\xEE\x82\xB6')
rc=$(printf '\xEE\x82\xB4')

# OSC 8 link helpers (raw bytes via printf)
osc_open() { printf '\033]8;;%s\033\\' "$1"; }
osc_close() { printf '\033]8;;\033\\'; }

prev_bg=""
out=""

seg() {
  _bg="$1"; _fg="$2"; _txt="$3"; _url="${4:-}"
  if [ -n "$_url" ]; then
    _txt="$(osc_open "$_url")${_txt}$(osc_close)"
  fi
  if [ -z "$prev_bg" ]; then
    out="${out}$(printf '\033[38;2;%sm%s\033[1m\033[48;2;%sm\033[38;2;%sm %s ' "$_bg" "$lc" "$_bg" "$_fg" "$_txt")"
  else
    out="${out}$(printf '\033[22m\033[38;2;%sm\033[48;2;%sm%s\033[1m\033[38;2;%sm %s ' "$prev_bg" "$_bg" "$rc" "$_fg" "$_txt")"
  fi
  prev_bg="$_bg"
}

endcap() {
  out="${out}$(printf '\033[22m\033[0m\033[38;2;%sm%s\033[0m' "$prev_bg" "$rc")"
}

# Line 1
seg "88;91;112" "205;214;244" "${i_folder} ${dir}" "$(make_folder_url "$cwd")"

if [ -n "$branch" ]; then
  branch_url=""
  if [ -n "$repo_url" ]; then
    case "$repo_url" in
      *github.com*) branch_url="${repo_url}/tree/${branch}" ;;
      *)            branch_url="${repo_url}/-/tree/${branch}" ;;
    esac
  fi
  diff_info=""
  if [ "$lines_add" -gt 0 ] 2>/dev/null || [ "$lines_del" -gt 0 ] 2>/dev/null; then
    diff_info=" (+${lines_add} -${lines_del})"
  fi
  seg "203;166;247" "30;30;46" "${i_git} ${branch}${venv}${diff_info}" "$branch_url"
fi

if [ "$total" -gt 0 ]; then
  cost_fmt=$(printf '$%.2f' "$cost_usd" 2>/dev/null || echo '$0.00')
  dur_s=$((duration_ms / 1000))
  dur_m=$((dur_s / 60))
  dur_h=$((dur_m / 60))
  if [ "$dur_h" -gt 0 ]; then
    dur_fmt="${dur_h}h$((dur_m % 60))m"
  elif [ "$dur_m" -gt 0 ]; then
    dur_fmt="${dur_m}m$((dur_s % 60))s"
  else
    dur_fmt="${dur_s}s"
  fi
  seg "116;199;236" "30;30;46" "${i_tokens} ${tokens} ${cost_fmt} ${dur_fmt}"
fi

if [ -n "$model" ]; then
  model_name=$(echo "$model" | sed 's/ (.*//')
  if [ "$ctx_size" -ge 1000000 ] 2>/dev/null; then
    ctx_fmt="$(echo "$ctx_size / 1000000" | bc)M"
  elif [ "$ctx_size" -ge 1000 ] 2>/dev/null; then
    ctx_fmt="$(echo "$ctx_size / 1000" | bc)k"
  else
    ctx_fmt=""
  fi
  if [ -n "$ctx_fmt" ]; then
    seg "166;227;161" "30;30;46" "${i_model} ${model_name} (${i_tokens}${ctx_fmt})"
  else
    seg "166;227;161" "30;30;46" "${i_model} ${model_name}"
  fi
fi

ctx_int=$(printf '%.0f' "$ctx_used" 2>/dev/null || echo "0")
if [ "$ctx_int" -gt 0 ] 2>/dev/null; then
  seg "249;226;175" "30;30;46" "${i_ctx} ${ctx_int}%"
fi

endcap

# Claude account (cached per session)
session_id=$(echo "$input" | jq -r '.session_id // ""')
cache_file="/tmp/cc-auth-${session_id}"
if [ -n "$session_id" ] && [ -f "$cache_file" ]; then
  claude_email=$(cat "$cache_file")
elif [ -n "$session_id" ]; then
  claude_email=$(claude auth status 2>/dev/null | jq -r '.email // empty' 2>/dev/null)
  [ -n "$claude_email" ] && echo "$claude_email" > "$cache_file"
fi

# Line 2: IDE + remote indicator + account + rate limits
prev_bg=""
out="${out}
"
i_vscode=$(printf '\xEE\xA3\x9A')   # U+E8DA vscode icon
seg "30;136;229" "255;255;255" "${i_vscode} VSC" "$(make_vscode_url "$cwd")"

# Remote host indicator
if [ -n "$CLAUDE_SSH_HOST" ]; then
  i_remote=$(printf '\xEF\x82\xA0')   # U+F0A0 nf-fa-hdd_o
  seg "250;179;135" "30;30;46" "${i_remote} ${CLAUDE_SSH_HOST}"
fi

if [ -n "$claude_email" ]; then
  i_user=$(printf '\xEF\x80\x87')   # U+F007 nf-fa-user
  seg "88;91;112" "205;214;244" "${i_user} ${claude_email}" "https://claude.ai/settings/profile"
fi

if [ -n "$rl_5h" ]; then
  rl5_int=$(printf '%.0f' "$rl_5h" 2>/dev/null || echo "0")
  rl5_reset=$(fmt_reset "$rl_5h_reset")
  arrow=$(printf '\xe2\x86\x92')
  rl5_txt="5h ${rl5_int}%"
  [ -n "$rl5_reset" ] && rl5_txt="${rl5_txt} ${arrow}${rl5_reset}"
  seg "243;139;168" "30;30;46" "${i_rate} ${rl5_txt}" "https://claude.ai/settings/usage"

  if [ -n "$rl_7d" ]; then
    rl7_int=$(printf '%.0f' "$rl_7d" 2>/dev/null || echo "0")
    rl7_reset=$(fmt_reset "$rl_7d_reset")
    rl7_txt="7d ${rl7_int}%"
    [ -n "$rl7_reset" ] && rl7_txt="${rl7_txt} ${arrow}${rl7_reset}"
    seg "210;110;130" "30;30;46" "${i_rate} ${rl7_txt}" "https://claude.ai/settings/usage"
  fi

fi

if [ -n "$transcript" ]; then
  i_transcript=$(printf '\xEF\x81\x85')   # U+F045 nf-fa-pencil_square_o
  seg "88;91;112" "205;214;244" "${i_transcript} transcript" "$(make_vscode_url "$transcript")"
fi

endcap

printf '%s' "$out"
