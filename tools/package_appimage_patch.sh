#!/usr/bin/env bash
# 把 patched ScummVM + 中文化資料(translation.tsv + 兩個 .fnt + title .ovl)打包成
# **patch 版** AppImage——不含遊戲資源,玩家自備遊戲、AppRun 用第一參數當遊戲路徑。
# 上 GitHub Release(公開下載)。[HARD] 不得含 resource.*/.drv/sciv.exe。
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"          # /home/anr2/scummvm/police_quest2/workplace
REPO_ROOT="$(cd "$ROOT/.." && pwd)"                # /home/anr2/scummvm/police_quest2
source "$ROOT/tools/pkg_common.sh"

STAGE="$ROOT/build/appimg-patch"
DIST="$REPO_ROOT/dist-all"
APPDIR="$STAGE/AppDir"
OUT="$DIST/PQ2-CHT-patch-x86_64.AppImage"

mkdir -p "$DIST"
rm -rf "$APPDIR"; mkdir -p "$APPDIR/usr/bin" "$APPDIR/usr/lib" "$APPDIR/usr/share/scummvm-cht"

echo ">> 複製 scummvm + strip"
cp "$ROOT/scummvm-src/scummvm" "$APPDIR/usr/bin/scummvm"
docker run --rm --name pq2-pkg-patch-strip -v "$APPDIR/usr/bin:/b" pq2-build:latest strip /b/scummvm 2>/dev/null || true

echo ">> 收集共享庫(pq2-build 內 ldd,排除 glibc 核心)"
docker run --rm --name pq2-pkg-patch-libs \
  -v "$APPDIR/usr/bin/scummvm:/collect/bin:ro" \
  -v "$APPDIR/usr/lib:/collect/out" \
  -v "$ROOT/tools/pkg_collect_libs.py:/collect/collect.py:ro" \
  -w /collect pq2-build:latest python3 collect.py bin out
echo "   $(ls "$APPDIR/usr/lib" | wc -l) 個 .so"

echo ">> 放入中文化資料(patch-only,不含遊戲)"
DATA_DIR="$ROOT/dist-cht"
[ -f "$DATA_DIR/translation.tsv" ] || DATA_DIR="$ROOT/game"
cp "$DATA_DIR/translation.tsv" "$APPDIR/usr/share/scummvm-cht/"
cp "$DATA_DIR/qfg1_big5.fnt" "$APPDIR/usr/share/scummvm-cht/"
cp "$DATA_DIR/qfg1_big5_hi.fnt" "$APPDIR/usr/share/scummvm-cht/"
cp "$DATA_DIR/pq2_title.ovl" "$APPDIR/usr/share/scummvm-cht/"

# AppRun:patch 版玩家自備遊戲——第一參數當遊戲夾路徑,--extrapath 指向中文化資料。
cat > "$APPDIR/AppRun" <<'APPRUN'
#!/bin/bash
HERE="$(dirname "$(readlink -f "$0")")"
export LD_LIBRARY_PATH="$HERE/usr/lib:${LD_LIBRARY_PATH:-}"
if [ -z "${1:-}" ]; then
  echo "用法: $(basename "$0") <PQ2 遊戲資料夾路徑> [其他 scummvm 參數...]"
  echo "  範例: ./PQ2-CHT-patch-x86_64.AppImage ~/games/pq2"
  exit 1
fi
GAME="$1"; shift
exec "$HERE/usr/bin/scummvm" --path="$GAME" --extrapath="$HERE/usr/share/scummvm-cht" --language=tw --auto-detect "$@"
APPRUN
chmod +x "$APPDIR/AppRun"

cat > "$APPDIR/pq2-cht.desktop" <<DESK
[Desktop Entry]
Type=Application
Name=警察故事 2 復仇記（繁體中文版・patch）
Comment=Police Quest II: The Vengeance 繁體中文化 — ScummVM patch（需自備遊戲）
Exec=AppRun
Icon=pq2-cht
Categories=Game;
Terminal=false
DESK
cp "$ROOT/tools/assets/pq2-cht.png" "$APPDIR/pq2-cht.png"
ln -sf pq2-cht.png "$APPDIR/.DirIcon"

rm -f "$OUT"
echo ">> appimagetool 打包(--appimage-extract-and-run 免 FUSE)"
docker run --rm --name pq2-pkg-patch-appimagetool -v "$STAGE:/stage" -v "$ROOT/tools/.cache:/cache:ro" -e ARCH=x86_64 -w /stage \
  pq2-build:latest bash -c "apt-get update -qq >/dev/null && apt-get install -y -qq file >/dev/null && \
    /cache/appimagetool-x86_64.AppImage --appimage-extract-and-run 'AppDir' '/stage/$(basename "$OUT")'"
mv "$STAGE/$(basename "$OUT")" "$OUT"
chmod +x "$OUT"
echo ">> 完成: $OUT ($(du -h "$OUT" | cut -f1))"
