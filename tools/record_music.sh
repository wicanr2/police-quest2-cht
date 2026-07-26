#!/bin/bash
# 用 SDL disk-audio 錄 PQ2 開場的真實 MT-32(Munt)音樂輸出 → /out/cap.raw
set -e
export HOME=/tmp XDG_RUNTIME_DIR=/tmp DISPLAY=:99
export SDL_AUDIODRIVER=disk SDL_DISKAUDIOFILE=/out/cap.raw
[ -s /roms/MT32_CONTROL.ROM ] || { echo '缺少 /roms/MT32_CONTROL.ROM；請先用正確檔名掛載合法 ROM' >&2; exit 2; }
[ -s /roms/MT32_PCM.ROM ] || { echo '缺少 /roms/MT32_PCM.ROM；請先用正確檔名掛載合法 ROM' >&2; exit 2; }
Xvfb :99 -screen 0 640x480x24 >/tmp/xvfb.log 2>&1 &
sleep 2
cd /src
# MT-32 驅動 + ROM 在 /roms；音量開滿；auto-detect 進遊戲跑開場（有配樂）
timeout 115 ./scummvm --path=/game --auto-detect --language=tw \
  --music-driver=mt32 --extrapath=/roms --music-volume=255 --output-rate=44100 2>/tmp/sv.log &
# 讓它跑滿約 105 秒錄開場音樂
sleep 105
pkill -f scummvm 2>/dev/null || true
sleep 2
echo "=== raw 大小 ==="; ls -la /out/cap.raw 2>/dev/null
echo "=== MT32 log ==="; grep -iE "MT32|CM32|Falling back|cannot be used|munt" /tmp/sv.log | head -5
