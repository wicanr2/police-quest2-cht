#!/usr/bin/env bash
set -eu
# ===== 設計 token（PQ2 科幻太空：深藍黑 + EGA 青綠 + 琥珀金 + 海盜紅）=====
BGD='#040814'; BGD2='#0a1630'; GOLD='#e0b048'; GOLDSH='#6e5010'; CYAN='#3fc8c0'; BLOOD='#c23a2a'; CREAM='#eef2ea'
FB='/usr/share/fonts/opentype/noto/NotoSerifCJK-Bold.ttc'
FR='/usr/share/fonts/opentype/noto/NotoSerifCJK-Regular.ttc'
W=1280; H=720; FPS=25; SHOT=/shots; MUS=/music; OUT=/out; TMP=/tmp/c; mkdir -p "$TMP" "$OUT"

card(){ # $1 out $2 中標 $3 英標 $4 副標
  convert -size ${W}x${H} "radial-gradient:${BGD2}-${BGD}" -font "$FB" -gravity center \
    -fill "$GOLDSH" -pointsize 92 -annotate +4+4 "$3" -fill "$GOLD" -pointsize 92 -annotate +0+0 "$3" \
    -fill "$CREAM" -pointsize 58 -annotate +0+94 "$2" \
    -fill "$CYAN" -font "$FR" -pointsize 30 -annotate +0+172 "$4" "$1"; }
slide(){ # $1 out $2 screenshot $3 字幕
  convert -size ${W}x${H} "gradient:${BGD2}-${BGD}" "$TMP/bg.png"
  convert "$SHOT/$2" -resize x582 -bordercolor "$GOLD" -border 2 "$TMP/sc.png"
  convert "$TMP/bg.png" \( "$TMP/sc.png" \) -gravity north -geometry +0+18 -composite \
    -fill "#000000aa" -draw "rectangle 0,642 ${W},720" \
    -font "$FR" -fill "$CREAM" -gravity south -pointsize 34 -annotate +0+28 "$3" "$1"; }
compare(){ # $1 out $2 en.png $3 cht.png $4 字幕 —— 左英右中對照
  convert "$SHOT/$2" -resize 512x384 -bordercolor '#888' -border 2 "$TMP/l.png"
  convert "$SHOT/$3" -resize 512x384 -bordercolor "$GOLD" -border 2 "$TMP/r.png"
  convert "$TMP/l.png" -gravity north -background '#00000000' -splice 0x34 -font "$FR" -fill '#cfcfcf' -pointsize 26 -annotate +0+4 '英文原版' "$TMP/l2.png"
  convert "$TMP/r.png" -gravity north -background '#00000000' -splice 0x34 -font "$FR" -fill "$GOLD" -pointsize 26 -annotate +0+4 '繁體中文化' "$TMP/r2.png"
  convert "$TMP/l2.png" "$TMP/r2.png" +append "$TMP/lr.png"
  convert -size ${W}x${H} "gradient:${BGD2}-${BGD}" \( "$TMP/lr.png" \) -gravity center -geometry +0-28 -composite \
    -font "$FR" -fill "$CREAM" -gravity south -pointsize 36 -annotate +0+40 "$4" "$1"; }
kb(){ # $1 png $2 mp4 $3 秒 —— 靜態 + fade（不用 zoompan，省 CPU）
  local FO; FO=$(awk "BEGIN{print $3-0.6}")
  ffmpeg -y -loglevel error -loop 1 -i "$1" -t "$3" -r $FPS \
    -vf "fade=t=in:st=0:d=0.6,fade=t=out:st=$FO:d=0.6,format=yuv420p" \
    -threads 2 -c:v libx264 -preset veryfast -pix_fmt yuv420p "$2"; }

# ===== 分鏡（只納入存在的截圖）=====
ORDER=(); declare -A SEC
add(){ ORDER+=("$1"); SEC[$1]=$2; }

card "$TMP/00.png" '警察故事 2：復仇記' "POLICE QUEST II" 'Sierra 1987 · SCI0 EGA · 繁體中文化'
add 00 5

# 標題中文副標疊圖
if [ -f "$SHOT/title_cht.png" ]; then slide "$TMP/01.png" title_cht.png '經典 POLICE QUEST 標題下，疊上中文副標'; add 01 5; fi
# 開場中文旁白 crawl（最亮點：hi-res 銳利中文）
if [ -f "$SHOT/intro_crawl_cht.png" ]; then slide "$TMP/02.png" intro_crawl_cht.png '開場旁白全中文 —— 清潔工羅傑的星際逃亡'; add 02 7; fi
# 遊戲內中文對白
if [ -f "$SHOT/ingame_cht_01.png" ]; then slide "$TMP/03.png" ingame_cht_01.png '遊戲內對白中文化，台式在地化改寫笑點'; add 03 6; fi
# F1 中文操作說明
if [ -f "$SHOT/f1_help_cht.png" ]; then slide "$TMP/04.png" f1_help_cht.png '按 F1 顯示繁中操作說明，新手也上手'; add 04 6; fi
# Sierra logo / credits 補充
if [ -f "$SHOT/credits.png" ]; then slide "$TMP/05.png" credits.png 'Jim Walls 的警察冒險經典'; add 05 5; fi

card "$TMP/99.png" '可見文字繁中化 · 3936 則' 'THE VENGEANCE' 'github.com/wicanr2 · 致敬 Jim Walls'
add 99 7

# ===== concat =====
LIST="$TMP/list.txt"; : > "$LIST"
for f in "${ORDER[@]}"; do kb "$TMP/$f.png" "$TMP/s_$f.mp4" "${SEC[$f]}"; echo "file '$TMP/s_$f.mp4'" >> "$LIST"; done
ffmpeg -y -loglevel error -f concat -safe 0 -i "$LIST" -threads 2 -c:v libx264 -preset veryfast -pix_fmt yuv420p "$TMP/silent.mp4"
DUR=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$TMP/silent.mp4"); FO=$(awk "BEGIN{print $DUR-3}")
# ===== 鋪原版 MT-32 配樂（aloop 循環，不用 -shortest，見 kb 慘雷）=====
ffmpeg -y -loglevel error -i "$TMP/silent.mp4" -i "$MUS/pq2_bgm.wav" \
  -filter_complex "[1:a]aloop=loop=-1:size=2000000000,atrim=0:$DUR,afade=t=in:st=0:d=2,afade=t=out:st=$FO:d=3[a]" \
  -map 0:v -map "[a]" -threads 2 -c:v libx264 -preset veryfast -c:a aac -b:a 192k -movflags +faststart \
  "$OUT/pq2_cht_promo.mp4"
echo "=== 完成 ==="; ffprobe -v error -show_entries format=duration -of csv=p=0 "$OUT/pq2_cht_promo.mp4"
echo "分鏡: ${ORDER[*]}"
