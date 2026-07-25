#!/bin/bash
# 探針：跑 PQ2 開場，沿路截圖看流程（無防拷碼，PQ2 直接進 intro）
set -e
export HOME=/tmp XDG_RUNTIME_DIR=/tmp DISPLAY=:99
Xvfb :99 -screen 0 640x480x24 >/tmp/xvfb.log 2>&1 &
sleep 2
cd /src
timeout 80 ./scummvm --path=/game --auto-detect --language=tw 2>/tmp/sv.log &
SV=$!
# 每 2 秒截一張，共 ~30 張，看開場到標題到 intro 的節奏
for t in $(seq -w 1 30); do
  import -window root /out/probe_${t}.png 2>/dev/null || true
  sleep 2
done
kill $SV 2>/dev/null || true
pkill -f scummvm 2>/dev/null || true
echo "probe done"
