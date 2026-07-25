#!/bin/bash
# PQ2 進遊戲 + F1 說明框擷取
set -e
export HOME=/tmp XDG_RUNTIME_DIR=/tmp DISPLAY=:99
Xvfb :99 -screen 0 640x480x24 >/tmp/xvfb.log 2>&1 &
sleep 2
cd /src
timeout 180 ./scummvm --path=/game --auto-detect --language=tw 2>/tmp/sv.log &
mkdir -p /out/shots
# 前 14s 讓 logo/標題跑；然後狂送 Esc/Return 跳過標題+credits+crawl
sleep 14
for i in $(seq 1 20); do
  xdotool key Escape 2>/dev/null || true
  xdotool key Return 2>/dev/null || true
  sleep 1
done
# 到這裡 (~34s) 應已過標題/credits，crawl 可能仍在或剛進遊戲；繼續猛跳
for i in $(seq 1 30); do
  xdotool key Escape 2>/dev/null || true
  sleep 1
  import -window root /out/shots/skip_$(printf %02d $i).png 2>/dev/null || true
done
# 現在 ~64s，應已在逃生艙遊戲畫面。先按 F1 說明
xdotool key F1; sleep 2
import -window root /out/shots/f1_help_cht.png 2>/dev/null || true
xdotool key Return; sleep 1   # 關掉說明框
# 觸發描述：type look + Return
for n in 1 2 3 4 5; do
  xdotool key Escape 2>/dev/null || true
  sleep 1
  xdotool type --delay 80 "look"; xdotool key Return; sleep 2
  import -window root /out/shots/ingame_cht_$(printf %02d $n).png 2>/dev/null || true
  xdotool key Return 2>/dev/null || true
  sleep 1
  # 動一下：往左/右走再 look
  xdotool key Left 2>/dev/null || true; sleep 1
done
# 再按一次 F1 備援
xdotool key F1; sleep 2
import -window root /out/shots/f1_help_cht_b.png 2>/dev/null || true
pkill -f scummvm 2>/dev/null || true
echo "=== sv.log tail ==="; tail -15 /tmp/sv.log
echo "ingame done"
