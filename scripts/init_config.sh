#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
skill_dir="$(cd "$script_dir/.." && pwd)"
config_dir="$skill_dir/config"
config_file="$config_dir/report.env"
groups_file="$skill_dir/references/watched-groups.md"

mkdir -p "$config_dir"

if [[ -f "$config_file" ]]; then
  printf '配置已存在：%s\n是否覆盖？输入 yes 继续：' "$config_file"
  read -r answer
  [[ "$answer" == "yes" ]] || { echo "已取消。"; exit 0; }
fi

printf '日报保存目录（请输入绝对路径）：'
read -r report_root
if [[ "$report_root" != /* ]]; then
  echo "必须填写绝对路径。" >&2
  exit 2
fi

printf '时区 [Asia/Shanghai]：'
read -r timezone
timezone="${timezone:-Asia/Shanghai}"

tmp_groups="$(mktemp "${TMPDIR:-/tmp}/watched-groups.XXXXXX")"
trap 'rm -f "$tmp_groups"' EXIT
printf '# 重点关注微信群\n\n' > "$tmp_groups"

echo "逐个输入要关注的微信群准确名称；直接回车结束。"
count=0
while true; do
  printf '群名：'
  read -r group_name
  [[ -n "$group_name" ]] || break
  printf -- '- %s\n' "$group_name" >> "$tmp_groups"
  count=$((count + 1))
done

if [[ "$count" -eq 0 ]]; then
  echo "未录入任何微信群，配置未写入。" >&2
  exit 2
fi

escaped_root="${report_root//\"/\\\"}"
escaped_timezone="${timezone//\"/\\\"}"
printf 'REPORT_ROOT="%s"\nREPORT_TIMEZONE="%s"\nWECHAT_MESSAGE_LIMIT="1000"\nCODEX_MODEL=""\nLARK_NOTIFY_CHAT_ID=""\nLARK_NOTIFY_AS="user"\n' \
  "$escaped_root" "$escaped_timezone" > "$config_file"
cp "$tmp_groups" "$groups_file"

echo "配置完成。"
echo "关注群数量：$count"
echo "日报目录：$report_root"
echo "下一步可运行：bash scripts/collect_wechat_group_day.sh YYYY-MM-DD"

