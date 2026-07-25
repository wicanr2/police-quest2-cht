# PQ2 繁中化 — 交接說明（Claude session → codex，2026-07-25）

接手者請先讀 `../CLAUDE-PQ2.md`（總規格）與本檔。本檔記錄「這一輪改了什麼、驗到哪、下一步跑什麼」。
**斷言任何一項「已完成」前請查 code / 產物本身，別只信本檔**（rulebook 63）。

## 1. 使用者已拍板的四個決策

| 項目 | 決定 |
|---|---|
| 交付範圍 | **做到 M6**：引擎 patch → 全文翻譯 → baked-art → 實機驗收 → 三平台 patch+full 雙軌打包 + README/中文攻略 |
| 工具鏈 | **改用 SQ3/KQ4 成熟工具鏈**（已搬完），codex 前一輪自寫的三支腳本移到 `tools/legacy-codex/` 作廢保留 |
| 翻譯調性 | **正經寫實 + 台灣警用術語**（非台式搞笑）。警用程序、10-code 無線電代碼、犯罪現場術語對到台灣警界慣用語；專有名詞可附原文對照 |
| 翻譯執行 | **允許派 sonnet subagent 批次 fan-out**，須附統一譯名表防漂移，合併後做一致性掃描 |

## 2. 這一輪實際做了什麼

### 2.1 工具鏈搬移（M2-A，完成）

從 `~/scummvm/space_quest3/workplace`（v6 模板、同為 SCI0 EGA、最近完工）整套複製並改名：

- `tools/`（全部）、`docker/`（build/capture/mingw 三個 Dockerfile）、`patches/`、`.github/workflows/`
- 名稱替換：`sq3-*` → `pq2-*`、docker image `qfg1-build` → `pq2-build`、`kq4-mingw` → `pq2-mingw`
- **未改**：`qfg1_big5.fnt` / `qfg1_big5_hi.fnt`（引擎寫死的檔名，跨專案沿用，不要改）
- 打包腳本裡的中文遊戲名仍是「宇宙傳奇 III」→ **M6 打包時要改成《警察故事 2 復仇記》**（`tools/package_*.sh`、`.github/workflows/build-macos.yml`）

引擎 patch `patches/0001-sci-cht-zh_twn.patch`（819 行 + `fontchinese.{h,cpp}` 整檔，pinned upstream `3d408ec`）
已改名：`sq3_title.ovl` → `pq2_title.ovl`、`SQ3_CHT_HELP` → `PQ2_CHT_HELP`。
**標題疊圖 hook 的 pic id 還是 SQ3 的 `926`（`paint16.cpp`），M4 要換成 PQ2 真正的標題 pic id**（用 `SCI_LOG_GFX=1` 找）。

### 2.2 引擎已編出來（M2-B，完成）

```
scummvm-src/          ← 從 ~/scummvm/qfg2-ega-cht 的本機 git 複製，checkout 3d408ec（無需連網）
scummvm-src/scummvm   ← 已編好的 patched binary（22MB）
```

- `tools/apply_patches.sh scummvm-src` 乾淨套用，14 檔 modified + fontchinese 兩個新檔
- configure：`--disable-all-engines --enable-engine=sci --disable-detection-full`，**未帶 `--disable-mt32emu`**，
  `grep USE_MT32EMU config.h` → `#define USE_MT32EMU` ✅（⑤ [HARD]）
- docker image **`pq2-build`**、**`pq2-capture`** 已建好（`qfg1-*` 那批舊 image 本機已不存在）
- binary 缺 `libjpeg.so.62` 無法在 host 直跑，**一律在 docker 內執行**

重編指令：
```bash
cd ~/scummvm/police_quest2/workplace
docker run --rm --name pq2-make -v "$PWD/scummvm-src:/src" -w /src pq2-build \
  bash -c "make -j\$(nproc) 2>&1 | tail -5"
```

### 2.3 抽字管線（M2-C，完成）

`extract/dump/`（480 資源，前一輪 dump 的）→

| 產物 | 內容 |
|---|---|
| `translation/text_skeleton.tsv` | text/message 3,809 則 |
| `translation/script_strings.json` | script 內嵌 147 則 |
| `translation/full_skeleton.tsv` | **3,956 列**，每列恰好 2 欄（已驗無拆裂） |
| `translation/script_multiline.json` | 6 則含硬 `\n` 的原文（供 crawl 對照） |

兩處值得知道的修正：

1. **`tools/extract_ega_scripts.py` 用的是 codex 前一輪改良版**（不是 SQ3 版）。SQ3/KQ4/QFG2 共用的那版「含控制碼就整條跳過」，
   會漏掉黏前導 bytecode 的對白 —— 這正是 CLAUDE-PQ2 ④-S 記載但**從未回填到共用工具**的雷。codex 版會剝前導非文字 byte
   再截斷，抽得比較全。**這個改良值得回填到其他專案。**
2. **`tools/build_skeleton.py`（新寫）** 合併時把所有 key 做 `\s+ → 單空格 + trim` 正規化，與引擎 `sciChtNormKey`（sci.cpp）
   逐字一致。原因：3 句玩家可見文字（`Looks like you BLEW it, Sonny!...`、`You have only your diving equipment...`、
   `I'll write to you at Happy Meadows!...`）含硬 `\n`，直接寫進 TSV 會被拆成多物理行 → merge/build 逐行讀時當 malformed
   丟棄 → 實機顯英文且覆蓋率統計看不出來（④-S v6，SQ3 踩過）。現在這三句都在 skeleton 且格式正確。

### 2.4 字型改用倚天點陣字（M2-D 進行中）

依 ④-S `[HARD]`「字形來源預設倚天（ETEN），不是 TTF rasterize」，跟進 `~/scummvm/space_quest4` 今天剛落地的方案：

- 複製 `tools/build_eten_font.py`、`tools/etunpack.py`、`tools/assets/eten/`（STDFONT.15 / SPCFONT.15 / stdfont.24 / SPCFONT.24）
- **引擎三顆旋鈕已改**（`patches/fontchinese.cpp`，已同步到 `scummvm-src` 並重編）：
  `kBig5Width = 12`（advance）、`kHiW = kHiH = 24`（hi-res glyph box）、`_big5Height` 初值 `14 → 15`
  —— 低解析 16×15、hi-res 24×24 都是倚天原生尺寸，不縮放。鐵律 `kHiW ≤ kBig5Width×2` 成立（24 ≤ 24）
- `tools/build_translation.sh` 末段改成 `build_eten_font.py "$OUT_UTF8" game --prefix qfg1`（取代 `bake_hires_font.py`）
- 倚天驗收 oracle 通過：`idx=0` 是「一」、「中」「猴」有字模

**字型檔位（advance 12 / glyph 24）是我依 [HARD] 選的起手式，不是玩家確認過的。**
④-S2 明說「改字型是主觀來回，先出對照截圖給玩家挑檔位，確認後才做全平台重編」。LSL2/SQ3 定案是 10/20（更密），
PQ2 選 12/24 是為了走倚天原生尺寸。M5 時應出 10/20（uming TTF 縮放）vs 12/24（倚天）對照截圖讓使用者挑。

### 2.5 譯文預填

`tools/prefill_from_sisters.py`（新寫，比對前兩邊都套 norm）掃七個姊妹專案譯文：

```
命中 124/3956（3%）→ translation/prefill.tsv（已放進 translation/batch/00-prefill.tsv）
```

命中的全是 parser 回應／系統 UI（「試試用另一種說法。」「空空如也。」…）。PQ2 劇情獨立、無 VGA remake，
**約 3,830 則要全新翻譯** —— 這是本專案最大宗工作量。

## 3. 驗到哪裡：**中文還沒在畫面上驗證過**（重要）

- ✅ 引擎編得起來、MT-32 啟用、遊戲跑得起來（`sci:pq2` 偵測 OK）
- ✅ headless 開場截圖正常（`out/probe/probe_*.png`，Sierra logo → 嫌犯照片 → credits）
- ❌ **「畫面出現中文」尚未證實** —— 端到端 probe 執行到一半被中止

已為此準備好一條最短驗證路徑，接手後直接跑即可：

- 開場旁白（`One Year has passed since Detective Sonny Bonds...`，text 資源第 2720 列）**已翻好**，
  放在 `translation/batch/01-m2-probe.tsv`，`build_translation.sh` 已跑過，`game/translation.tsv` 有 125 則
- 這段旁白在遊戲啟動約 80 秒後全螢幕顯示，**不需要任何按鍵**就會出現 → 截圖即可判定

```bash
cd ~/scummvm/police_quest2/workplace
rm -f out/e2e/*
timeout 220 docker run --rm --name pq2-e2e \
  -v "$PWD/scummvm-src:/src" -v "$PWD/game:/game" \
  -v "$PWD/out/e2e:/out" -v "$PWD/tools:/tools" \
  pq2-capture bash /tools/probe_parser.sh
# 看 out/e2e/cht_parser.png：那段旁白若顯示中文 → hi-res 繪字 + key 正規化 + 倚天字型三件事一次驗完
```

若仍是英文，依序查：① `game/translation.tsv` 有沒有該 key（Big5 檔要用 `grep -a`）②
啟動有沒有帶 `--language=tw` ③ `sciChtNormKey` 正規化後 key 是否真的相同。

**已知問題：`tools/probe_parser.sh` 的 xdotool 送不進按鍵**（打字沒出現在畫面上，intro 也跳不過）。
`xdotool search --name "ScummVM" key ...` 沒作用，可能要先 `windowactivate --sync` 或改用 `key --window <id>`。
M5 要走「進遊戲點 NPC」的路徑時得先修這個。

## 4. 下一步建議順序

1. **跑上面那條 probe 確認中文顯示**（M2 收尾）。這是所有後續工作的前提，別跳過。
2. **訂統一譯名表**再開翻：Sonny Bonds、Jessie Bains（The Death Angel）、Lytton、警階、10-code、
   犯罪現場／證物術語。放 `translation/glossary.tsv`，每個 subagent brief 都附上。
   本輪已用的譯名：桑尼·邦茲、傑西·班恩斯、死亡天使、萊頓（市）。
3. **M3 批次翻譯**：`translation/full_skeleton.tsv` 切批 → `translation/batch/*.tsv` →
   `tools/validate_batch.py` 逐批驗 → `tools/build_translation.sh` 合併烘字。
   注意 ④-S2 的 `.done` glob 雷：**部署真相是手維護的 master tsv，別讓 build 腳本蓋掉**。
4. **M4**：`SCI_LOG_GFX=1` 找標題 pic id 改掉 `paint16.cpp` 寫死的 `926`；選單字串在 `script.997`
   （抽字工具會漏，要手動撈 bare item 補進 skeleton）；判 baked-art 是 view（`sci0_view.py` 可重繪）還是 pic（只能疊 `.ovl`）。
5. **M5**：修 xdotool → 走正常玩家路徑實機驗收；跑一次英文版對照判別迴歸。
6. **M6**：打包腳本裡的遊戲名還是 SQ3 的，要全改；GitHub repo `wicanr2/police-quest2-cht` 目前是空的
   （**發 Release 屬對外動作，先取得使用者確認**）。

## 5. 目錄現況

```
workplace/
├── HANDOFF.md              ← 本檔
├── CONTEXT.md, WORKLIST.md ← 前一輪寫的，數字已過時（skeleton 是 3,956 不是 4,046）
├── game/                   ← 原始遊戲資源 + 已產出的 translation.tsv / qfg1_big5*.fnt（gitignored）
├── scummvm-src/            ← pinned 3d408ec + CHT patch，已編出 scummvm（gitignored）
├── patches/                ← 引擎 patch（PQ2 已改名，標題 pic id 待改）
├── tools/                  ← SQ3 成熟工具鏈 + 本輪新增 build_skeleton.py / prefill_from_sisters.py /
│                             probe_parser.sh / build_eten_font.py / etunpack.py / assets/eten/
│   └── legacy-codex/       ← 前一輪自寫腳本（作廢保留）
├── translation/
│   ├── full_skeleton.tsv   ← 3,956 列待翻骨架（唯一真相）
│   ├── prefill.tsv         ← 姊妹專案預填結果
│   ├── batch/              ← 00-prefill.tsv、01-m2-probe.tsv
│   └── legacy-codex/       ← 前一輪抽字結果（交叉驗證用）
├── extract/dump/           ← 480 個資源 dump（gitignored）
├── docker/                 ← Dockerfile.build / .capture / .mingw
└── out/probe, out/e2e/     ← headless 截圖
```

**git 狀態：`workplace/` 是本機 git repo 但仍 0 commit**，全部檔案 untracked。首次 commit 前確認
`.gitignore` 有擋掉 `game/`、`extract/dump/`、`scummvm-src/`、`out/`、`*.ROM`（目前有擋）。

## 6. Codex 2026-07-25 收尾進度

- 翻譯批次已擴充至 `138-personnel-files.tsv`；3,936/3,956 個鍵已有中文，剩餘 20 個是抽取出的內部/編碼鍵（`dummya`、`dummyb`、`%ssg.dir` 與 `xr...`/`J 9rx9` 等），保留原值避免破壞腳本。
- `tools/build_translation.sh` 已改用 `sort -V` 的數字批次順序；修正舊批次覆蓋新批次的問題，並自動產生 `game/pq2_title.ovl`。
- 實際日誌確認 PQ2 標題圖為 `pic=46`；`paint16.cpp` 與 `0001-sci-cht-zh_twn.patch` 已同步改用 46。
- Docker 實機截圖已看到繁中繪字與「復仇記」疊圖：`out/e2e-final/cht_skip_10.png`、`out/shots/idt_a.png`；英文回歸 `out/e2e-en/cht_skip_10.png` 保持英文畫面。
- 從 pinned `3d408ec` 乾淨 tree 執行 `tools/apply_patches.sh` 已通過；Docker 重編 `scummvm` 已通過。
- 主要 macOS/Windows/AppImage 包裝腳本已改成 PQ2 名稱、路徑與 `pq2-cht.png`，macOS data 包裝已用假 `.app` smoke test 驗證，包內含 translation、兩顆字型與 title overlay。
- Windows `PE32+` binary、patch/full zip 與 Linux AppImage patch/full 已實際產出並檢查內容；macOS data 包已用假 `.app` smoke test 驗證，真正 universal `.app/.dmg` 仍須 macOS runner。正常玩家 parser 自動輸入仍受 Docker xdotool 焦點限制，但中文畫面與英文回歸已完成可視驗收。
- 追加驗證：`docker/Dockerfile.capture` 已加入 Fluxbox；新增 `tools/probe_parser_noesc.sh` 不跳過 intro，100 秒後以視窗 ID 輸入 parser。`out/e2e-debug/noesc_parser.png` 顯示「抱歉，邦茲，你得做得更好！」，英文對照 `out/e2e-en-noesc/noesc_parser.png` 顯示原文，M5 已完成。
- `dist-cht/` 已加入可公開分發的 `translation.tsv`、兩顆 Big5 字型與 `pq2_title.ovl`；重新 smoke test `package_macos_data.sh` 成功，macOS CI workflow 不再依賴被 gitignore 的本機 `game/` 資料夾。
