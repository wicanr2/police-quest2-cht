#!/usr/bin/env python3
"""用姊妹專案(同系列 Sierra SCI 繁中化)已完成的譯文預填 PQ2 skeleton。

比對前兩邊都套 `norm()`(與引擎 sciChtNormKey 一致),否則硬換行/padding 空白
會讓內容比對 MISS(CLAUDE-PQ2 ④-S)。命中的多半是系統 UI / parser 回應 /
共用道具詞,劇情句幾乎不會重複。

用法:prefill_from_sisters.py <full_skeleton.tsv> <out_prefill.tsv> <sister.tsv> [...]
"""
import re
import sys
from pathlib import Path


def norm(s):
    return re.sub(r"[ \r\n\t]+", " ", s).strip()


def read_pairs(path):
    """姊妹 tsv 可能是 UTF-8 或 Big5(runtime 檔),兩種都試。"""
    raw = Path(path).read_bytes()
    for enc in ("utf-8", "big5", "cp950"):
        try:
            text = raw.decode(enc)
            break
        except UnicodeDecodeError:
            continue
    else:
        text = raw.decode("utf-8", errors="replace")
    for line in text.splitlines():
        if "\t" not in line or line.lstrip().startswith("#"):
            continue
        en, zh = line.split("\t", 1)
        yield norm(en), zh.strip(), enc


def main():
    skeleton, out = sys.argv[1], sys.argv[2]
    table = {}
    for src in sys.argv[3:]:
        n = 0
        enc_used = None
        for en, zh, enc in read_pairs(src):
            enc_used = enc
            # 只收「真的翻過」的(col2 與 col1 不同且含中文)
            if not zh or zh == en or not re.search(r"[一-鿿]", zh):
                continue
            table.setdefault(en, zh)
            n += 1
        print(f"  載入 {n:5d} 則 ({enc_used}) ← {src}")

    hit = total = 0
    rows = []
    hits_sample = []
    for line in Path(skeleton).read_text(encoding="utf-8").splitlines():
        if "\t" not in line:
            continue
        en = line.split("\t", 1)[0]
        total += 1
        zh = table.get(norm(en))
        if zh:
            hit += 1
            rows.append(f"{en}\t{zh}")
            if len(hits_sample) < 15:
                hits_sample.append((en, zh))
        else:
            rows.append(f"{en}\t{en}")
    Path(out).write_text("\n".join(rows) + "\n", encoding="utf-8")
    print(f"預填命中 {hit}/{total} ({100 * hit // max(1, total)}%) → {out}")
    for en, zh in hits_sample:
        print(f"    {en[:48]!r} → {zh[:40]}")


if __name__ == "__main__":
    main()
