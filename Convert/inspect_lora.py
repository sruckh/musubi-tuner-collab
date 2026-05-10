#!/usr/bin/env python3
"""
inspect_lora.py — Print LoRA file structure for debugging format mismatches.

Usage:
    python inspect_lora.py my_lora.safetensors
    python inspect_lora.py lora_a.safetensors lora_b.safetensors   # compare two
"""
import sys
import json
from pathlib import Path
from collections import Counter

try:
    from safetensors import safe_open
except ImportError:
    print("ERROR: pip install safetensors")
    sys.exit(1)


def inspect(path: str) -> dict:
    info = {"path": path, "metadata": {}, "keys": [], "shapes": {}, "dtypes": Counter()}
    with safe_open(path, framework="pt") as f:
        info["metadata"] = f.metadata() or {}
        for key in f.keys():
            t = f.get_tensor(key)
            info["keys"].append(key)
            info["shapes"][key] = list(t.shape)
            info["dtypes"][str(t.dtype)] += 1
    info["keys"].sort()
    return info


def summarize(info: dict):
    keys = info["keys"]
    print(f"\n{'='*60}")
    print(f"File: {info['path']}")
    print(f"{'='*60}")

    if info["metadata"]:
        print("\n--- Metadata ---")
        for k, v in info["metadata"].items():
            print(f"  {k}: {v}")

    print(f"\n--- Stats ---")
    print(f"  Total keys : {len(keys)}")
    print(f"  Dtypes     : {dict(info['dtypes'])}")

    if keys:
        # Top-level prefix (before first dot)
        prefixes = Counter(k.split(".")[0] for k in keys)
        print(f"  Prefixes   : {dict(prefixes)}")

        # Detect likely format
        if any(k.startswith("lora_unet_") for k in keys):
            fmt = "musubi-tuner"
        elif any(k.startswith("diffusion_model.") for k in keys):
            fmt = "Diffusers/ComfyUI (diffusion_model prefix)"
        elif any(k.startswith("transformer.") for k in keys):
            fmt = "Diffusers/PEFT (transformer prefix)"
        elif any(k.startswith("lora_te") for k in keys):
            fmt = "Kohya/AUTOMATIC1111"
        else:
            fmt = "Unknown"
        print(f"  Format     : {fmt}")

        # Check for alpha keys
        alpha_keys = [k for k in keys if k.endswith(".alpha")]
        print(f"  Alpha keys : {len(alpha_keys)} ({'present' if alpha_keys else 'MISSING — may cause scale issues'})")

        print(f"\n--- First 10 keys ---")
        for k in keys[:10]:
            print(f"  {k}  {info['shapes'][k]}")
        if len(keys) > 10:
            print(f"  ... ({len(keys) - 10} more)")


def compare(a: dict, b: dict):
    print(f"\n{'='*60}")
    print("COMPARISON")
    print(f"{'='*60}")
    ka, kb = set(a["keys"]), set(b["keys"])
    only_a = sorted(ka - kb)
    only_b = sorted(kb - ka)
    shared = sorted(ka & kb)

    # Normalize keys: strip lora_down/lora_up/alpha suffix to get module names
    def module_names(keys):
        mods = set()
        for k in keys:
            for suffix in [".lora_down.weight", ".lora_up.weight", ".lora_A.weight", ".lora_B.weight", ".alpha"]:
                if k.endswith(suffix):
                    mods.add(k[: -len(suffix)])
                    break
            else:
                mods.add(k)
        return mods

    ma, mb = module_names(a["keys"]), module_names(b["keys"])
    print(f"  Module count A: {len(ma)}")
    print(f"  Module count B: {len(mb)}")
    print(f"  Shared modules: {len(ma & mb)}")
    print(f"  Only in A     : {len(ma - mb)}")
    print(f"  Only in B     : {len(mb - ma)}")

    if only_a:
        print(f"\n  Keys only in A (first 5):")
        for k in only_a[:5]:
            print(f"    {k}")
    if only_b:
        print(f"\n  Keys only in B (first 5):")
        for k in only_b[:5]:
            print(f"    {k}")


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(1)

    files = sys.argv[1:]
    infos = []
    for f in files:
        if not Path(f).exists():
            # Try in Input/ dir
            candidate = Path(__file__).parent / "Input" / f
            if candidate.exists():
                f = str(candidate)
            else:
                print(f"ERROR: file not found: {f}")
                sys.exit(1)
        infos.append(inspect(f))

    for info in infos:
        summarize(info)

    if len(infos) == 2:
        compare(infos[0], infos[1])


if __name__ == "__main__":
    main()
