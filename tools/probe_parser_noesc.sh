#!/bin/bash
# 不跳過 intro 的 parser 驗證：避免連續 Esc 把 SCI0 流程送過頭。
set -u
export HOME=/tmp XDG_RUNTIME_DIR=/tmp DISPLAY=:99
Xvfb :99 -screen 0 640x480x24 >/tmp/xvfb.log 2>&1 &
XVFB=$!
sleep 2
fluxbox >/tmp/fluxbox.log 2>&1 &
FLUX=$!
sleep 1
cd /src
mkdir -p /out
LANG_ARG="${LANG_ARG:---language=tw}"
timeout 165 ./scummvm --path=/game --auto-detect $LANG_ARG >/tmp/sv.log 2>&1 &
SV=$!

window_id() {
  xdotool search --onlyvisible --class scummvm 2>/dev/null | tail -1
}
send_text() {
  local wid="$1"
  xdotool windowactivate --sync "$wid" 2>/dev/null || true
  xdotool type --window "$wid" --delay 70 "frobnicate the wibble" 2>/dev/null || true
}
send_return() {
  local wid="$1"
  xdotool windowactivate --sync "$wid" 2>/dev/null || true
  xdotool key --window "$wid" --clearmodifiers Return 2>/dev/null || true
}

# 開場不送鍵，先留存幾個時間點；SCI0 PQ2 約 80 秒後進入遊戲。
for t in 20 50 80 100; do
  sleep $((t - ${last_t:-0}))
  last_t="$t"
  import -window root "/out/noesc_${t}s.png" 2>/dev/null || true
done

WID="$(window_id)"
if [ -n "$WID" ]; then
  xdotool getwindowname "$WID" >/out/window-name.txt 2>&1 || true
  send_text "$WID"
  sleep 1
  import -window root /out/noesc_typed.png 2>/dev/null || true
  send_return "$WID"
  sleep 3
  import -window root /out/noesc_parser.png 2>/dev/null || true
fi

kill "$SV" "$FLUX" "$XVFB" 2>/dev/null || true
echo "=== window ==="; cat /out/window-name.txt 2>/dev/null || true
echo "=== stderr tail ==="; tail -20 /tmp/sv.log
