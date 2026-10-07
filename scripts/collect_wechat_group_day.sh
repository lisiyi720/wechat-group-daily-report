#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  collect_wechat_group_day.sh [YYYY-MM-DD] [output_dir] [groups_file]

Defaults:
  date         Yesterday in REPORT_TIMEZONE
  output_dir   REPORT_ROOT/raw/YYYY-MM-DD
  groups_file  ../references/watched-groups.md
USAGE
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then usage; exit 0; fi

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
skill_dir="$(cd "$script_dir/.." && pwd)"
config_file="$skill_dir/config/report.env"

if [[ ! -f "$config_file" ]]; then
  echo "Missing config: $config_file" >&2
  echo "Run: bash scripts/init_config.sh" >&2
  exit 2
fi
# shellcheck disable=SC1090
source "$config_file"

: "${REPORT_ROOT:?REPORT_ROOT is required in config/report.env}"
report_timezone="${REPORT_TIMEZONE:-Asia/Shanghai}"
limit="${WECHAT_MESSAGE_LIMIT:-1000}"
groups_file="${3:-$skill_dir/references/watched-groups.md}"

target_date="${1:-}"
if [[ -z "$target_date" ]]; then
  target_date="$(python3 - "$report_timezone" <<'PY'
from datetime import datetime, timedelta
from zoneinfo import ZoneInfo
import sys
print((datetime.now(ZoneInfo(sys.argv[1])).date() - timedelta(days=1)).isoformat())
PY
)"
fi

next_date="$(python3 - "$target_date" <<'PY'
from datetime import datetime, timedelta
import sys
d = datetime.strptime(sys.argv[1], "%Y-%m-%d").date()
print((d + timedelta(days=1)).isoformat())
PY
)"
output_dir="${2:-$REPORT_ROOT/raw/$target_date}"

command -v wechat-cli >/dev/null 2>&1 || { echo "wechat-cli not found in PATH" >&2; exit 1; }
[[ -f "$groups_file" ]] || { echo "Groups file not found: $groups_file" >&2; exit 1; }

mapfile_cmd="$(command -v mapfile || true)"
groups=()
while IFS= read -r line; do
  [[ "$line" =~ ^[[:space:]]*-[[:space:]]+ ]] || continue
  group="${line#*- }"
  [[ -n "$group" ]] && groups+=("$group")
done < "$groups_file"

if [[ "${#groups[@]}" -eq 0 ]]; then
  echo "No WeChat groups configured in $groups_file" >&2
  echo "Run: bash scripts/init_config.sh" >&2
  exit 2
fi

mkdir -p "$output_dir"
slugify() {
  python3 - "$1" <<'PY'
import re, sys
s = re.sub(r"[^\w\u4e00-\u9fff.-]+", "_", sys.argv[1].strip())
print((re.sub(r"_+", "_", s).strip("_") or "group")[:80])
PY
}

echo "Collecting WeChat messages for $target_date ($report_timezone)"
for group in "${groups[@]}"; do
  file="$output_dir/$(slugify "$group").json"
  echo "-> $group"
  wechat-cli history "$group" \
    --start-time "$target_date 00:00:00" \
    --end-time "$next_date 00:00:00" \
    --format json --limit "$limit" --media > "$file"
done
echo "Done: $output_dir"

