#!/bin/bash
# 被動探針：不送任何鍵，只每 3s 截圖，看 intro→逃生艙→遊戲 自然時間軸
set -e
export HOME=/tmp XDG_RUNTIME_DIR=/tmp DISPLAY=:99
Xvfb :99 -screen 0 640x480x24 >/tmp/xvfb.log 2>&1 &
sleep 2
cd /src
timeout 200 ./scummvm --path=/game --auto-detect --language=tw 2>/tmp/sv.log &
mkdir -p /out/shots
# 只在 crawl 之後偶爾送一次 Return 推進文字（第 60s 起每 15s 一次）
for t in $(seq -w 1 55); do
  import -window root /out/shots/pg_${t}.png 2>/dev/null || true
  sleep 3
done
pkill -f scummvm 2>/dev/null || true
echo "=== sv.log tail ==="; tail -8 /tmp/sv.log
echo "passive done"
