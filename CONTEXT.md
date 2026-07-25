# Police Quest 2 繁中化 — 專案基線

## 已確認

- 遊戲：`Police Quest 2 - The Vengeance` DOS floppy，SCI0/EGA。
- ScummVM detector：`sci:pq2`。
- 原始資源：`RESOURCE.001`–`RESOURCE.006`、`RESOURCE.MAP`。
- 初始資源 dump：`font 5`、`pic 78`、`script 98`、`text 91`、`view 208`，共 480 個檔案。
- 初始抽字：`text/message` 3,809 則；修正 SCI bytecode 前綴處理並加入保守噪音過濾後，`script.*` 另抽 151 則；合併後 3,956 個候選 key。
- M2 實機驗證：`out/e2e/cht_parser.png` 曾確認中文旁白可見；更新字型與翻譯後需用修正過的 probe 再驗一次。
- M3：`translation/glossary.tsv` 建立警用術語；目前實際翻譯 3,936/3,956 則，另含 `batch/02-core.tsv` 至 `138-personnel-files.tsv`，均已合併並重烘；合併器已修正可接受以 `#1.` 開頭的遊戲鍵，建置器改用批次數字順序避免新譯文被舊批次覆蓋。
- M4：SCI 日誌確認 PQ2 標題為 `pic=46`，`game/pq2_title.ovl` 已由繁中「復仇記」生成；引擎 hook 與 patch 已同步。
- M5：Docker 實機截圖 `out/e2e-final/cht_skip_10.png`、`out/shots/idt_a.png` 顯示中文；不跳過 intro 的正常流程已在 100 秒後成功送入 parser，`out/e2e-debug/noesc_parser.png` 顯示繁中回應，`out/e2e-en-noesc/noesc_parser.png` 顯示英文原文回應。
- M6：主要三平台包裝腳本已改成 PQ2 名稱與資料路徑；公開中文資料已整理至 `dist-cht/`；Windows zip、Linux AppImage patch/full 與 GitHub Actions macOS universal `.app/.dmg` 已實際產出並檢查。
- 交付驗收：`dist-all/PQ2-CHT-win64-patch.zip`、`PQ2-CHT-win64.zip`、`PQ2-CHT-patch-x86_64.AppImage`、`PQ2-CHT-full-x86_64.AppImage` 均已產生；Windows binary 為 PE32+，Linux AppImage 解包後 patch 無 `RESOURCE.*`/ROM、full 含 8 個 `RESOURCE.*` 與 MT-32 ROM。
- macOS 交付驗收：GitHub Actions run [30163658485](https://github.com/wicanr2/police-quest2-cht/actions/runs/30163658485) 成功；`dist-all/PQ2-CHT-macos-universal.tar.gz` 與 `.dmg` 已下載。tar 內執行檔為 Mach-O universal（x86_64 + arm64），四個中文資料檔均在 app bundle 且與 `dist-cht/` 校驗一致。

## 方法約束

- GitHub repo 只放 ScummVM patch 與中文資料，不放 `RESOURCE.*`、`.DRV`、DOS executable 或 MT-32 ROM。
- SCI0 中文文字使用 `language=tw`、Big5 字型與執行期 key replacement。
- `script.*` 內嵌文字、選單 padding 空格、動態 `%s/%d`、硬換行都必須納入抽查。
- baked-art 先判斷是 `view` cel 還是 `pic` 向量指令，再決定是否重繪。
- 驗收以英文 reference 與正常玩家路徑實機對照，不以抽字覆蓋率單獨宣稱完成。

## 備註

本專案依 `CLAUDE-PQ2.md` 與 `retro-cht` 知識庫執行；指定的 `~/.code/knowledge-base/retro-cht` 在本環境不存在，實際採用等價的 `/home/anr2/.claude/knowledge-base/retro-cht`。
