#!/bin/bash
# 合併所有譯文 batch → 烘 16px + hi-res 字型 + runtime tsv。可重跑。
set -e
cd "$(dirname "$0")/.."
SKEL=translation/full_skeleton.tsv
OUT_UTF8=translation/translation_utf8.tsv
# 收集所有譯文來源：預填 + 已完成批
# Sort by the numeric batch prefix.  Plain `ls`/locale ordering can place
# batch 136 before batch 14, allowing an older batch to overwrite newer work.
mapfile -t BATCHES < <(find translation/batch -maxdepth 1 \( -name '*.tsv' -o -name '*.done' \) -print | sort -V)
python3 tools/merge_translations.py "$SKEL" "$OUT_UTF8" "${BATCHES[@]}"
# 對全部譯文(含預填)套全域收斂
python3 - "$OUT_UTF8" <<PYEOF
import sys
conv=[]
for l in open('translation/converge.tsv',encoding='utf-8'):
    if l.startswith('#') or '\t' not in l: continue
    a,b=l.rstrip('\n').split('\t',1); conv.append((a,b))
p=sys.argv[1]; lines=open(p,encoding='utf-8').read().split('\n')
out=[]
for ln in lines:
    if '\t' in ln:
        en,zh=ln.split('\t',1)
        for a,b in conv: zh=zh.replace(a,b)
        out.append(en+'\t'+zh)
    else: out.append(ln)
open(p,'w',encoding='utf-8').write('\n'.join(out))
PYEOF
# 統計覆蓋
python3 - <<PY
import re
n=t=0
for l in open("$OUT_UTF8",encoding='utf-8'):
    if '\t' not in l: continue
    en,zh=l.rstrip('\n').split('\t',1); t+=1
    if zh.strip()!=en.strip(): n+=1
print(f"覆蓋: {n}/{t} ({100*n//t}%) 已譯")
PY
# runtime Big5 tsv(順帶烘一份 TTF 版 16px 字型,下一步會被倚天版覆蓋)
python3 tools/build_cht.py "$OUT_UTF8" game --size 14
# [HARD] 字形來源用倚天點陣字(ETEN),不是 TTF rasterize(CLAUDE-PQ2 ④-S)。
# 低解析 16×15 + hi-res 24×24 都是倚天原生尺寸,不縮放;引擎常數 kBig5Width=12 /
# kHiW=kHiH=24 必須與此對齊,否則 bytesPerGlyph 對不上 → hi-res 亂碼。
python3 tools/build_eten_font.py "$OUT_UTF8" game --prefix qfg1
# Title overlay is generated alongside the runtime data so package scripts do not
# depend on a manually copied artifact.  Set CHT_OVERLAY_FONT when the host uses
# a different installed CJK font.
OVERLAY_FONT="${CHT_OVERLAY_FONT:-/usr/share/fonts/truetype/arphic/uming.ttc}"
if [ -f "$OVERLAY_FONT" ]; then
  python3 tools/build_title_overlay.py game/pq2_title.ovl --font "$OVERLAY_FONT" --face 2
else
  echo "!! 找不到標題疊圖中文字型 $OVERLAY_FONT（略過 pq2_title.ovl）" >&2
fi
echo "=== 產物 ==="
ls -la game/translation.tsv game/qfg1_big5.fnt game/qfg1_big5_hi.fnt game/pq2_title.ovl 2>/dev/null || true
