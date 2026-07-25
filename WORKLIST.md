# 警察故事 2《復仇記》繁中化 — WORKLIST

## 里程碑

| 里程碑 | 狀態 |
|---|---|
| M0 環境盤點、版本辨識、初始 dump | ✅ SCI0/EGA、`sci:pq2`、480 資源 |
| M1 文字抽取與可重現 skeleton | ✅ 3,956 個候選 key（含 script bytecode 前綴修正與噪音過濾） |
| M2 引擎 patch 端到端顯示中文 | ✅ Docker 實機確認（`out/e2e-final/cht_skip_10.png`、`out/shots/idt_a.png`） |
| M3 全文翻譯（text/message + script 內嵌 + 動態句） | ✅ 3,936/3,956（99%）可見文字；剩餘 20 個內部/編碼鍵保留原值 |
| M4 baked-art / 選單完整化 | ✅ PQ2 title `pic=46` 已確認，`pq2_title.ovl` 已生成並掛入引擎 |
| M5 正常路徑實機驗收與英文對照 | ✅ 中文 `out/e2e-debug/noesc_parser.png` 與英文 `out/e2e-en-noesc/noesc_parser.png` 均完成正常 parser 回應驗收 |
| M6 三平台 patch/full 打包 | ✅ Windows zip、Linux AppImage patch/full 與 GitHub Actions macOS universal `.app/.dmg` 均已產出並驗證 |

## 下一步

1. 發布前由使用者確認是否建立 GitHub Release（目前不執行對外發布）。

## 本輪產物

- `extract/dump/`：本機 SCI dump（gitignored）
- `translation/text-skeleton.tsv`：text/message 抽字結果
- `translation/script-strings.json`：script 內嵌字串結果
- `translation/skeleton.tsv`：合併後待翻骨架
