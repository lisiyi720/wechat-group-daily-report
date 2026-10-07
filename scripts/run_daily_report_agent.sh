#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
skill_dir="$(cd "$script_dir/.." && pwd)"
config_file="$skill_dir/config/report.env"

[[ -f "$config_file" ]] || { echo "Run bash scripts/init_config.sh first." >&2; exit 2; }
# shellcheck disable=SC1090
source "$config_file"
: "${REPORT_ROOT:?REPORT_ROOT is required}"
export REPORT_ROOT REPORT_TIMEZONE="${REPORT_TIMEZONE:-Asia/Shanghai}"

target_date="${1:-}"
if [[ -z "$target_date" ]]; then
  target_date="$(python3 - "$REPORT_TIMEZONE" <<'PY'
from datetime import datetime, timedelta
from zoneinfo import ZoneInfo
import sys
print((datetime.now(ZoneInfo(sys.argv[1])).date() - timedelta(days=1)).isoformat())
PY
)"
fi

report_file="$REPORT_ROOT/${target_date}-微信群日报.md"
mkdir -p "$REPORT_ROOT/logs"

"$script_dir/collect_wechat_group_day.sh" "$target_date"
python3 "$script_dir/collect_lark_chat_day.py" "$target_date"

prompt_file="$(mktemp "${TMPDIR:-/tmp}/group-daily-report.XXXXXX.md")"
trap 'rm -f "$prompt_file"' EXIT
cat > "$prompt_file" <<EOF
Use the skill at $skill_dir/SKILL.md to generate the group-message daily report for $target_date.

Read these collected sources:
- $REPORT_ROOT/raw/$target_date
- $REPORT_ROOT/raw-lark/$target_date (if present)

Save the final Markdown exactly to: $report_file
Follow references/report-format.md. Preserve original URLs, mark unresolved CLI links, include useful message_app_link values, and keep at most 3 high-value attachments/files/images/links. Do not invent missing facts or links. Verify the final file exists and is non-empty.
EOF

codex_args=(exec --cd "$skill_dir" --output-last-message "$REPORT_ROOT/logs/${target_date}-codex-final.txt")
[[ -n "${CODEX_MODEL:-}" ]] && codex_args+=(--model "$CODEX_MODEL")
codex "${codex_args[@]}" - < "$prompt_file"

[[ -s "$report_file" ]] || { echo "Report missing or empty: $report_file" >&2; exit 1; }
echo "Report generated: $report_file"

