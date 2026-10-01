"""Build Lua data from pinned, public upstream sources; no runtime network I/O."""
from pathlib import Path
import argparse
import json
import yaml


def quote(value):
    # Source values are printable symbols; JSON quoting is also valid Lua here.
    return json.dumps(value, ensure_ascii=False)


def index(path):
    pairs = []
    for line in path.read_text(encoding="utf-8").splitlines():
        if not line.strip() or line.startswith("#"):
            continue
        fields = line.split()
        pairs.append((int(fields[0]), int(fields[1], 16)))
    return pairs


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("ice", type=Path)
    parser.add_argument("index", type=Path)
    parser.add_argument("ranges", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()
    args.output.mkdir(parents=True, exist_ok=True)
    two = index(args.index)
    assert [p for p, _ in two] == list(range(23940)), "unexpected GB index"
    ranges = index(args.ranges)
    assert ranges[0] == (0, 128) and ranges[-1] == (189000, 65536)
    text = "-- Generated from pinned WHATWG Encoding indexes. See docs/rime-uv.md.\nreturn {two={\n"
    text += ",\n".join(",".join(str(cp) for _, cp in two[i:i+24]) for i in range(0, len(two), 24))
    text += "\n},ranges={\n" + ",\n".join("{%d,%d}" % pair for pair in ranges) + "\n}}\n"
    (args.output / "gb_data.lua").write_text(text, encoding="utf-8")
    symbols = yaml.safe_load((args.ice / "symbols_caps_v.yaml").read_text(encoding="utf-8"))["symbols"]
    categories = {
        "udw": ("单位", ["Vdw", "Vhb"]),
        "uxh": ("序号", ["Vszq", "Vszh", "Vszd", "Vlmd", "Vlm"]),
        "uts": ("特殊", ["Vfh", "Vxh", "Vjt"]),
        "ubd": ("标点", ["Vbd", "Vbdz"]),
        "usx": ("数学", ["Vsx", "Vfs"]),
        "ujh": ("几何", ["Vjh"]),
        "uzm": ("字母", ["Vxl", "Vxld", "Vey", "Veyd", "Vzmq", "Vzmh"]),
    }
    rows = ["-- Generated from pinned rime-ice symbols.\nreturn {"]
    for code, (name, sources) in categories.items():
        items = list(dict.fromkeys(str(s) for key in sources for s in symbols[key]))
        assert items and all(not any(ord(c) < 32 for c in s) for s in items)
        rows.append("  %s={name=%s,items={%s}}," % (code, quote(name), ",".join(map(quote, items))))
    rows.append("}\n")
    (args.output / "symbols.lua").write_text("\n".join(rows), encoding="utf-8")


if __name__ == "__main__":
    main()
