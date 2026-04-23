#!/bin/bash
set -euo pipefail

ROOT="/Users/a1234/Desktop/Python_Math"
GENERATOR="$ROOT/generate_makeup_three_page_report.py"
OUTPUT="$ROOT/Output/latest.html"

if [[ $# -lt 1 ]]; then
  echo "用法: ./publish_makeup_latest.sh <excel路径> [--no-push]"
  exit 1
fi

INPUT_PATH="$1"
PUSH_ENABLED="true"
if [[ "${2:-}" == "--no-push" ]]; then
  PUSH_ENABLED="false"
fi

if [[ ! -f "$INPUT_PATH" ]]; then
  echo "未找到 Excel 文件: $INPUT_PATH"
  exit 1
fi

python3 "$GENERATOR" --input "$INPUT_PATH" --output "$OUTPUT"
rm -f "$ROOT"/Output/完课催补率组长动作版_*.html

if [[ ! -f "$OUTPUT" ]]; then
  echo "latest.html 生成失败"
  exit 1
fi

cd "$ROOT"
git add index.html Output/latest.html .gitignore publish_makeup_latest.sh

if ! git diff --cached --quiet; then
  FILE_DATE=$(python3 - <<'PY' "$INPUT_PATH"
import re, sys, pandas as pd
from pathlib import Path
p = Path(sys.argv[1])
m = re.search(r"(20\d{6})", p.stem)
if m:
    dt = pd.to_datetime(m.group(1), format="%Y%m%d", errors="coerce")
    if pd.notna(dt):
        print(dt.strftime("%Y-%m-%d"))
        raise SystemExit
print("latest")
PY
)
  git commit -m "$(cat <<EOF
Update latest makeup report.

Refresh GitHub Pages output with the newest report build for ${FILE_DATE}.
EOF
)"
else
  echo "没有新的发布改动，跳过提交。"
fi

if [[ "$PUSH_ENABLED" == "true" ]]; then
  git push origin main
  echo "已推送到 GitHub Pages 仓库。"
else
  echo "已完成 latest.html 更新和本地提交，未执行 push。"
fi
