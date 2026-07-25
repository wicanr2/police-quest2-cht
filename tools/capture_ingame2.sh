#!/bin/bash
# PQ2 用 Enter 溫和推進 crawl→逃生艙過場→遊戲，抓 in-game 中文 + F1 說明
set -e
export HOME=/tmp XDG_RUNTIME_DIR=/tmp DISPLAY=:99
Xvfb :99 -screen 0 640x480x24 >/tmp/xvfb.log 2>&1 &
sleep 2
cd /src
timeout 240 ./scummvm --path=/game --auto-detect --language=tw 2>/tmp/sv.log &
mkdir -p /out/shots
# 等到 crawl 停在等待頁 (~52s)
sleep 52
# 溫和推進：每次 Return 一下，等 5s，截圖。走過場對白框
for n in $(seq -w 1 18); do
  xdotool key Return 2>/dev/null || true
  sleep 5
  import -window root /out/shots/adv_${n}.png 2>/dev/null || true
done
# 到這裡應已在逃生艙可操作畫面。按 F1 說明框
xdotool key F1; sleep 3
import -window root /out/shots/f1_help_cht.png 2>/dev/null || true
xdotool key Return 2>/dev/null || true; sleep 2
# 觸發描述：type look
xdotool type --delay 80 "look"; sleep 1; xdotool key Return; sleep 3
import -window root /out/shots/ingame_look_01.png 2>/dev/null || true
xdotool key Return 2>/dev/null || true; sleep 2
import -window root /out/shots/ingame_look_02.png 2>/dev/null || true
# 再 F1 備援
xdotool key F1; sleep 3
import -window root /out/shots/f1_help_cht_b.png 2>/dev/null || true
pkill -f scummvm 2>/dev/null || true
echo "=== sv.log tail ==="; tail -6 /tmp/sv.log
echo "adv done"
