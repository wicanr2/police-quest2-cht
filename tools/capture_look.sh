#!/bin/bash
# 快速抓 in-game look 描述框：進遊戲後打 look 指令，密集短間隔截圖
set -e
export HOME=/tmp XDG_RUNTIME_DIR=/tmp DISPLAY=:99
Xvfb :99 -screen 0 640x480x24 >/tmp/xvfb.log 2>&1 &
sleep 2
cd /src
timeout 200 ./scummvm --path=/game --auto-detect --language=tw 2>/tmp/sv.log &
mkdir -p /out/shots/look
sleep 52
# 推進 crawl→過場→遊戲（Enter，別 Escape）
for n in $(seq 1 14); do xdotool key Return 2>/dev/null || true; sleep 5; done
# 應已在遊戲。清掉殘留框
xdotool key Return 2>/dev/null || true; sleep 2
# 嘗試多組 look 指令，每次打完密集截圖抓描述框
try_cmd() {
  local tag="$1"; shift
  xdotool type --delay 60 "$1"; sleep 1; xdotool key Return;
  for k in 1 2 3 4; do
    import -window root /out/shots/look/${tag}_${k}.png 2>/dev/null || true
    sleep 1
  done
  xdotool key Return 2>/dev/null || true; sleep 1
}
try_cmd look "look"
try_cmd lookpod "look at pod"
try_cmd lookroom "look around"
try_cmd getchip "look at chip"
pkill -f scummvm 2>/dev/null || true
echo "look done"
