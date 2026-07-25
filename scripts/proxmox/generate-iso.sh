#!/usr/bin/env bash

set -Eeuo pipefail

VERSION="9.2-1"
ANSWER_FILE=""
OUTPUT_DIR="$PWD"

usage() {
cat <<EOF
Usage:

  $0 --answer answer.toml [--output-dir DIR]

Options:

  --answer      Local answer.toml (required)

  --output-dir  Directory to place the generated ISO
                (default: current directory)

EOF
exit 1
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --answer)
            ANSWER_FILE="$2"
            shift 2
            ;;
        --output-dir)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        *)
            usage
            ;;
    esac
done

[[ -n "$ANSWER_FILE" ]] || usage

command -v curl >/dev/null || {
    echo "curl not installed"
    exit 1
}

command -v proxmox-auto-install-assistant >/dev/null || {
    echo "proxmox-auto-install-assistant not installed."
    exit 1
}

mkdir -p "$OUTPUT_DIR"

TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

ISO="proxmox-ve_${VERSION}.iso"
ISO_URL="https://enterprise.proxmox.com/iso/${ISO}"
ISO_PATH="$TMPDIR/$ISO"

echo "Downloading Proxmox ISO..."
curl -L --fail \
    -o "$ISO_PATH" \
    "$ISO_URL"

echo
echo "Validating answer.toml..."
proxmox-auto-install-assistant validate-answer "$ANSWER_FILE"

OUTPUT="$OUTPUT_DIR/proxmox-ve_${VERSION}-auto.iso"

echo
echo "Building unattended ISO..."

proxmox-auto-install-assistant prepare-iso \
    "$ISO_PATH" \
    --fetch-from iso \
    --answer-file "$ANSWER_FILE" \
    --output "$OUTPUT"

echo
echo "Done!"
echo
echo "Created:"
echo "    $OUTPUT"
