#!/usr/bin/env bash
# convert_lora.sh — batch-convert LoRA .safetensors files
#
# Converts all .safetensors files in Input/ and writes results to Output/.
#
# Usage:
#   ./convert_lora.sh                    # musubi-tuner → ComfyUI (default)
#   ./convert_lora.sh --target default   # ComfyUI → musubi-tuner
#   ./convert_lora.sh --file my_lora.safetensors  # single file
#
# Requirements:
#   musubi-tuner must be installed (pip install -e .) or its repo path set:
#     export MUSUBI_TUNER_DIR=/path/to/musubi-tuner

set -euo pipefail

# ── Paths ──────────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INPUT_DIR="${SCRIPT_DIR}/Input"
OUTPUT_DIR="${SCRIPT_DIR}/Output"

# ── Locate musubi-tuner ────────────────────────────────────────────────────
find_musubi_tuner() {
    # 1. Explicit env var
    if [[ -n "${MUSUBI_TUNER_DIR:-}" && -f "${MUSUBI_TUNER_DIR}/src/musubi_tuner/convert_lora.py" ]]; then
        echo "${MUSUBI_TUNER_DIR}"
        return
    fi
    # 2. Sibling or parent directory (common clone location)
    for candidate in \
        "${SCRIPT_DIR}/../musubi-tuner" \
        "${HOME}/musubi-tuner" \
        "/content/musubi-tuner" \
        "/opt/musubi-tuner"
    do
        if [[ -f "${candidate}/src/musubi_tuner/convert_lora.py" ]]; then
            echo "$(realpath "${candidate}")"
            return
        fi
    done
    # 3. Installed as Python package — use python -m
    if python -c "import musubi_tuner.convert_lora" 2>/dev/null; then
        echo "__module__"
        return
    fi
    echo ""
}

# ── Defaults ───────────────────────────────────────────────────────────────
TARGET="other"          # "other"=musubi→ComfyUI  |  "default"=ComfyUI→musubi
SINGLE_FILE=""          # empty = process all files in Input/
OVERWRITE=false
DIFFUSERS_PREFIX=""

# ── Argument parsing ───────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
    case "$1" in
        --target)    TARGET="$2";          shift 2 ;;
        --file)      SINGLE_FILE="$2";     shift 2 ;;
        --overwrite) OVERWRITE=true;       shift   ;;
        --prefix)    DIFFUSERS_PREFIX="$2"; shift 2 ;;
        -h|--help)
            sed -n '2,14p' "$0" | sed 's/^# \?//'
            exit 0
            ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
done

if [[ "$TARGET" != "other" && "$TARGET" != "default" ]]; then
    echo "Error: --target must be 'other' or 'default'" >&2
    exit 1
fi

# ── Validate environment ───────────────────────────────────────────────────
MUSUBI_DIR="$(find_musubi_tuner)"
if [[ -z "$MUSUBI_DIR" ]]; then
    echo "Error: musubi-tuner not found." >&2
    echo "  Set MUSUBI_TUNER_DIR=/path/to/musubi-tuner or install with:" >&2
    echo "  pip install -e /path/to/musubi-tuner" >&2
    exit 1
fi

# Build the base python command
if [[ "$MUSUBI_DIR" == "__module__" ]]; then
    PYTHON_CMD="python -m musubi_tuner.convert_lora"
else
    PYTHON_CMD="python ${MUSUBI_DIR}/src/musubi_tuner/convert_lora.py"
    cd "$MUSUBI_DIR"
fi

# ── Collect input files ────────────────────────────────────────────────────
mkdir -p "$INPUT_DIR" "$OUTPUT_DIR"

if [[ -n "$SINGLE_FILE" ]]; then
    # Accept bare filename or full path
    if [[ "$SINGLE_FILE" != /* ]]; then
        SINGLE_FILE="${INPUT_DIR}/${SINGLE_FILE}"
    fi
    if [[ ! -f "$SINGLE_FILE" ]]; then
        echo "Error: file not found: $SINGLE_FILE" >&2
        exit 1
    fi
    INPUT_FILES=("$SINGLE_FILE")
else
    mapfile -t INPUT_FILES < <(find "$INPUT_DIR" -maxdepth 1 -name "*.safetensors" | sort)
fi

if [[ ${#INPUT_FILES[@]} -eq 0 ]]; then
    echo "No .safetensors files found in: ${INPUT_DIR}"
    echo "Place your LoRA file(s) there and re-run."
    exit 0
fi

# ── Labels ─────────────────────────────────────────────────────────────────
if [[ "$TARGET" == "other" ]]; then
    DIRECTION="musubi-tuner → ComfyUI / Diffusers"
else
    DIRECTION="ComfyUI / Diffusers → musubi-tuner"
fi

echo "=================================================="
echo "  musubi-tuner LoRA Converter"
echo "=================================================="
echo "  Direction : ${DIRECTION}"
echo "  Input     : ${INPUT_DIR}"
echo "  Output    : ${OUTPUT_DIR}"
echo "  Files     : ${#INPUT_FILES[@]}"
echo "=================================================="
echo ""

# ── Convert ────────────────────────────────────────────────────────────────
CONVERTED=0
SKIPPED=0
FAILED=0

for IN_PATH in "${INPUT_FILES[@]}"; do
    FNAME="$(basename "$IN_PATH")"
    OUT_PATH="${OUTPUT_DIR}/${FNAME}"

    if [[ -f "$OUT_PATH" && "$OVERWRITE" == false ]]; then
        echo "  ⏭  ${FNAME} — output exists, skipping (use --overwrite to replace)"
        (( SKIPPED++ )) || true
        continue
    fi

    echo -n "  ⚙  ${FNAME} ... "

    PREFIX_FLAG=""
    [[ -n "$DIFFUSERS_PREFIX" ]] && PREFIX_FLAG="--diffusers_prefix ${DIFFUSERS_PREFIX}"

    if $PYTHON_CMD \
            --input  "$IN_PATH"  \
            --output "$OUT_PATH" \
            --target "$TARGET"   \
            $PREFIX_FLAG 2>&1; then
        SIZE_MB=$(( $(wc -c < "$OUT_PATH") / 1024 / 1024 ))
        echo "✅ done (${SIZE_MB} MB)"
        (( CONVERTED++ )) || true
    else
        echo "❌ FAILED"
        (( FAILED++ )) || true
    fi
done

echo ""
echo "=================================================="
echo "  Converted : ${CONVERTED}"
echo "  Skipped   : ${SKIPPED}"
echo "  Failed    : ${FAILED}"
echo "=================================================="
[[ $FAILED -gt 0 ]] && exit 1 || exit 0
