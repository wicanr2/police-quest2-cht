#!/bin/bash
# PQ2 收尾入口：逐批驗證目前 master batches，再重建翻譯表、字型與標題疊圖。
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

mapfile -t batch_files < <(find translation/batch -maxdepth 1 -type f -name '*.tsv' -print | sort -V)
echo "===== 逐批 validate（${#batch_files[@]} batches）====="
for batch in "${batch_files[@]}"; do
  python3 tools/validate_batch.py "$batch" "$batch" >/dev/null
done
echo "===== rebuild translation/font/title ====="
bash tools/build_translation.sh
echo "===== 完成：${#batch_files[@]} 個批次 ====="
