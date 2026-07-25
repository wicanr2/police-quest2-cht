# 警察故事 2《復仇記》繁體中文化

本專案目標是以 ScummVM patch-only 方式，為 Sierra 的 `Police Quest II: The Vengeance` DOS SCI0/EGA 版本加入繁體中文支援。

目前已完成 SCI0/EGA 引擎中文繪字、標題疊圖、全文翻譯批次與 Docker 實機畫面驗收；原始遊戲資料只供本機測試，公開版本不包含遊戲資源。

## 本機重建

```bash
bash tools/build_translation.sh
```

這會合併 `translation/full_skeleton.tsv` 與數字排序的 `translation/batch/*.tsv`，產生 `game/translation.tsv`、倚天 Big5 字型與 `game/pq2_title.ovl`。

引擎需在 Docker 中執行（主機可能缺少 `libjpeg.so.62`）：

```bash
docker run --rm --name pq2-make \
  -v "$PWD/scummvm-src:/src" -w /src pq2-build \
  bash -c 'make -j$(nproc)'
```

公開中文資料位於 `dist-cht/`（翻譯表、兩顆 Big5 字型、PQ2 標題疊圖），可由
Windows/Linux patch 包與 macOS CI workflow 直接注入；原始遊戲資源仍不在其中。

驗收探針：

```bash
docker run --rm --name pq2-e2e \
  -v "$PWD/scummvm-src:/src" -v "$PWD/game:/game" \
  -v "$PWD/out/e2e:/out" -v "$PWD/tools:/tools" pq2-capture \
  bash /tools/probe_parser.sh
```

`out/e2e/cht_skip_10.png` 可確認繁中對白與「復仇記」標題疊圖；英文回歸使用 `LANG_ARG=--language=en`。

正常流程 parser 驗收使用不跳過 intro 的探針，約 100 秒後送入測試指令：

```bash
docker run --rm --name pq2-e2e-noesc \
  -v "$PWD/scummvm-src:/src" -v "$PWD/game:/game" \
  -v "$PWD/out/e2e-debug:/out" -v "$PWD/tools:/tools" pq2-capture \
  bash /tools/probe_parser_noesc.sh
```

繁中應看到「抱歉，邦茲，你得做得更好！」；以 `LANG_ARG=--language=en` 執行則應看到英文原文。

原始遊戲資源與 MT-32 ROM 僅限本機使用，patch/full 包裝腳本不將其提交至公開版本。

詳見 [`WORKLIST.md`](WORKLIST.md) 與 [`CONTEXT.md`](CONTEXT.md)。
