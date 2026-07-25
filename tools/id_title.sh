set -e
export HOME=/tmp XDG_RUNTIME_DIR=/tmp DISPLAY=:99
Xvfb :99 -screen 0 640x480x24 >/tmp/xvfb.log 2>&1 &
sleep 2
fluxbox >/tmp/fluxbox.log 2>&1 &
sleep 1
cd /src
mkdir -p /out/picdump
SCI_LOG_GFX=1 SCI_DUMP_PIC=/out/picdump SCI_DUMP_VIEW=/out/picdump \
  timeout 45 ./scummvm --path=/game --auto-detect --language=tw 2>/tmp/gfx.log &
SV=$!
sleep 12
WID="$(xdotool search --onlyvisible --class scummvm 2>/dev/null | tail -1 || true)"
if [ -n "$WID" ]; then
  xdotool windowactivate --sync "$WID" 2>/dev/null || true
  xdotool type --window "$WID" --delay 100 "BOBALU"; sleep 1
  xdotool key --window "$WID" Return
else
  xdotool type --delay 100 "BOBALU"; sleep 1; xdotool key Return
fi
sleep 3
import -window root /out/shots/idt_a.png 2>/dev/null || true   # 標題
xdotool key --window "${WID:-}" Return 2>/dev/null || xdotool key Return; sleep 3
import -window root /out/shots/idt_b.png 2>/dev/null || true   # credits
kill $SV 2>/dev/null || true
echo "=== drawPicture / view 記錄（過防拷後）==="
grep "SCI_LOG_GFX" /tmp/gfx.log | tail -25
echo "=== dump 出的 pic/view ==="
ls /out/picdump/ 2>/dev/null | head -30
