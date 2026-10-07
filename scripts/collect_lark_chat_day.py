#!/usr/bin/env python3
import json
import os
import re
import subprocess
import sys
from datetime import datetime, timedelta
from pathlib import Path
from zoneinfo import ZoneInfo


def slugify(value):
    value = re.sub(r"[^\w\u4e00-\u9fff.-]+", "_", value.strip())
    return (re.sub(r"_+", "_", value).strip("_") or "lark_source")[:80]


def parse_sources(path):
    sources = []
    for raw in path.read_text(encoding="utf-8").splitlines():
        line = raw.strip()
        if not line.startswith("- "):
            continue
        parts = [part.strip() for part in line[2:].split("|")]
        if len(parts) >= 2 and re.fullmatch(r"oc_[0-9a-fA-F]{20,}", parts[1]):
            sources.append({"name": parts[0], "chat_id": parts[1], "purpose": parts[2] if len(parts) > 2 else ""})
    return sources


def run_page(chat_id, start_seconds, end_seconds, page_token=None):
    params = {
        "container_id_type": "chat",
        "container_id": chat_id,
        "start_time": str(start_seconds),
        "end_time": str(end_seconds),
        "sort_type": "ByCreateTimeAsc",
        "page_size": 50,
    }
    if page_token:
        params["page_token"] = page_token
    cmd = ["lark-cli", "api", "GET", "/open-apis/im/v1/messages", "--as", "user",
           "--params", json.dumps(params, ensure_ascii=False), "--format", "json"]
    result = subprocess.run(cmd, text=True, capture_output=True, check=False)
    if result.returncode:
        return {"ok": False, "error": result.stderr.strip() or result.stdout.strip()}
    try:
        return json.loads(result.stdout)
    except json.JSONDecodeError as exc:
        return {"ok": False, "error": f"invalid json: {exc}"}


def main():
    script_dir = Path(__file__).resolve().parent
    skill_dir = script_dir.parent
    sources_file = Path(sys.argv[3]) if len(sys.argv) > 3 else skill_dir / "references" / "lark-sources.md"
    sources = parse_sources(sources_file)
    if not sources:
        print(f"No Lark sources configured; skipped: {sources_file}")
        return 0
    if not shutil_which("lark-cli"):
        print("lark-cli not found in PATH", file=sys.stderr)
        return 1

    timezone_name = os.environ.get("REPORT_TIMEZONE", "Asia/Shanghai")
    tz = ZoneInfo(timezone_name)
    target = sys.argv[1] if len(sys.argv) > 1 else (datetime.now(tz).date() - timedelta(days=1)).isoformat()
    day = datetime.strptime(target, "%Y-%m-%d").date()
    start = datetime.combine(day, datetime.min.time(), tzinfo=tz)
    end = start + timedelta(days=1)
    report_root = os.environ.get("REPORT_ROOT", str(skill_dir / "output"))
    output_dir = Path(sys.argv[2]) if len(sys.argv) > 2 else Path(report_root) / "raw-lark" / target
    output_dir.mkdir(parents=True, exist_ok=True)

    failures = []
    for source in sources:
        messages, pages, token = [], [], None
        error = None
        while True:
            page = run_page(source["chat_id"], int(start.timestamp()), int(end.timestamp()), token)
            pages.append(page)
            if page.get("ok") is False or ("code" in page and page.get("code") != 0):
                error = page.get("error") or page
                failures.append(source["name"])
                break
            data = page.get("data") or {}
            messages.extend(data.get("items") or [])
            if not data.get("has_more"):
                break
            token = data.get("page_token")
            if not token:
                break
        payload = {"source": source, "date": target, "timezone": timezone_name,
                   "ok": error is None, "count": len(messages), "messages": messages,
                   "error": error, "raw_pages": pages}
        (output_dir / f"{slugify(source['name'])}.json").write_text(
            json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"Done: {output_dir}")
    return 1 if failures else 0


def shutil_which(command):
    from shutil import which
    return which(command)


if __name__ == "__main__":
    raise SystemExit(main())
