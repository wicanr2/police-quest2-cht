#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
OUT="$ROOT/docs/promo/pq2-cht-promo.mp4"
FONT=/usr/share/fonts/opentype/noto/NotoSansCJK-Bold.ttc
MUSIC_RAW="${PROMO_MUSIC_RAW:-$ROOT/out/promo-audio/cap.raw}"

mkdir -p "$(dirname "$OUT")"

ffmpeg -y -loglevel error \
  -loop 1 -t 6 -i "$ROOT/docs/screenshots/manual-preface.jpg" \
  -loop 1 -t 5 -i "$ROOT/docs/screenshots/01-character-file-cht.png" \
  -loop 1 -t 5 -i "$ROOT/docs/screenshots/02-opening-briefing-cht.png" \
  -loop 1 -t 5 -i "$ROOT/docs/screenshots/03-parser-response-cht.png" \
  -loop 1 -t 5 -i "$ROOT/docs/screenshots/manual-cover-back.jpg" \
  -loop 1 -t 4 -i "$ROOT/docs/screenshots/04-credits.png" \
  -filter_complex "\
[0:v]scale=1280:720:force_original_aspect_ratio=decrease,pad=1280:720:(ow-iw)/2:(oh-ih)/2:black,setsar=1,drawbox=x=0:y=580:w=1280:h=140:color=black@0.65:t=fill,drawtext=fontfile=$FONT:text='夜半時分 冷面殺手潛伏在陰暗巷弄':fontcolor=white:fontsize=38:x=55:y=620[v0];\
[1:v]scale=1280:720:force_original_aspect_ratio=decrease,pad=1280:720:(ow-iw)/2:(oh-ih)/2:black,setsar=1,drawbox=x=0:y=580:w=1280:h=140:color=black@0.65:t=fill,drawtext=fontfile=$FONT:text='案件資料 通緝犯名單 繁體中文化':fontcolor=white:fontsize=38:x=55:y=620[v1];\
[2:v]scale=1280:720:force_original_aspect_ratio=decrease,pad=1280:720:(ow-iw)/2:(oh-ih)/2:black,setsar=1,drawbox=x=0:y=580:w=1280:h=140:color=black@0.65:t=fill,drawtext=fontfile=$FONT:text='警察故事 2 復仇記 開場旁白':fontcolor=white:fontsize=38:x=55:y=620[v2];\
[3:v]scale=1280:720:force_original_aspect_ratio=decrease,pad=1280:720:(ow-iw)/2:(oh-ih)/2:black,setsar=1,drawbox=x=0:y=580:w=1280:h=140:color=black@0.65:t=fill,drawtext=fontfile=$FONT:text='文字指令 也能以繁體中文閱讀':fontcolor=white:fontsize=38:x=55:y=620[v3];\
[4:v]scale=1280:720:force_original_aspect_ratio=decrease,pad=1280:720:(ow-iw)/2:(oh-ih)/2:black,setsar=1,drawbox=x=0:y=580:w=1280:h=140:color=black@0.65:t=fill,drawtext=fontfile=$FONT:text='重新踏上 Lytton 市的辦案旅程':fontcolor=white:fontsize=38:x=55:y=620[v4];\
[5:v]scale=1280:720:force_original_aspect_ratio=decrease,pad=1280:720:(ow-iw)/2:(oh-ih)/2:black,setsar=1,drawbox=x=0:y=580:w=1280:h=140:color=black@0.65:t=fill,drawtext=fontfile=$FONT:text='SCI0 EGA 繁中化 由 ScummVM 驅動':fontcolor=white:fontsize=38:x=55:y=620[v5];\
[v0][v1][v2][v3][v4][v5]concat=n=6:v=1:a=0,format=yuv420p[v]" \
  -map "[v]" -t 30 -r 24 -an -c:v libx264 -preset ultrafast -crf 25 \
  -movflags +faststart "$OUT"

test -s "$MUSIC_RAW" || {
  echo "找不到原版音軌：$MUSIC_RAW" >&2
  echo "請先以 tools/record_music.sh 錄製 cap.raw，不能產生無聲推廣片。" >&2
  exit 2
}

# cap.raw 是 44.1 kHz、雙聲道、signed 16-bit little-endian 的 MT-32 disk-audio。
# 影片較短時裁切並淡出，保留原版音色，不加入自製或無版權不明的配樂。
DURATION=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$OUT")
FADE_START=$(awk "BEGIN {print $DURATION - 3}")
TMP_VIDEO="${OUT%.mp4}.silent.mp4"
mv "$OUT" "$TMP_VIDEO"
ffmpeg -y -loglevel error \
  -i "$TMP_VIDEO" \
  -f s16le -ar 44100 -ac 2 -i "$MUSIC_RAW" \
  -filter_complex "[1:a]atrim=duration=$DURATION,afade=t=in:st=0:d=1.5,afade=t=out:st=$FADE_START:d=3,aresample=async=1[a]" \
  -map 0:v -map "[a]" -t "$DURATION" \
  -c:v copy -c:a aac -b:a 192k -movflags +faststart "$OUT"
rm -f "$TMP_VIDEO"

ffprobe -v error -show_entries format=duration:stream=codec_name,width,height \
  -of default=noprint_wrappers=1 "$OUT"
