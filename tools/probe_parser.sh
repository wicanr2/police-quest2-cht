#!/bin/bash
# 端到端中文驗證探針：跳過 intro → 打一句 parser 不懂的指令 → 截「請換個說法」回應。
# 該句已由姊妹專案預填譯文覆蓋，故只要中文顯示路徑通，畫面就會出中文。
set -e
export HOME=/tmp XDG_RUNTIME_DIR=/tmp DISPLAY=:99
Xvfb :99 -screen 0 640x480x24 >/tmp/xvfb.log 2>&1 &
sleep 2
fluxbox >/tmp/fluxbox.log 2>&1 &
sleep 1
cd /src
LANG_ARG="${LANG_ARG:---language=tw}"
PREFIX="${PREFIX:-cht}"
timeout 150 ./scummvm --path=/game --auto-detect $LANG_ARG 2>/tmp/sv.log &
SV=$!
mkdir -p /out
window_id() {
  xdotool search --onlyvisible --class scummvm 2>/dev/null | tail -1
}
send_key() {
  local wid; wid="$(window_id)"
  if [ -n "$wid" ]; then
    xdotool windowactivate --sync "$wid" 2>/dev/null || true
    xdotool key --window "$wid" --clearmodifiers "$1" 2>/dev/null || true
  fi
}
send_text() {
  local wid; wid="$(window_id)"
  if [ -n "$wid" ]; then
    xdotool windowactivate --sync "$wid" 2>/dev/null || true
    xdotool type --window "$wid" --delay 60 "$1" 2>/dev/null || true
  fi
}
# 1) 狂送 Esc 跳過 Sierra logo / credits / intro（intro 很長，約 60s 才進遊戲）
for i in $(seq 1 40); do
  send_key Escape
  sleep 2
  case $i in 10|20|30|40) import -window root /out/${PREFIX}_skip_${i}.png 2>/dev/null || true ;;
  esac
done
# 2) 打一句 parser 不認得的指令，觸發「請換個說法」
send_text "frobnicate the wibble"
sleep 1
import -window root /out/${PREFIX}_typed.png 2>/dev/null || true
send_key Return
sleep 2
import -window root /out/${PREFIX}_parser.png 2>/dev/null || true
sleep 2
import -window root /out/${PREFIX}_parser2.png 2>/dev/null || true
kill "$SV" 2>/dev/null || true
pkill -f scummvm 2>/dev/null || true
echo "=== stderr tail ==="; tail -15 /tmp/sv.log
