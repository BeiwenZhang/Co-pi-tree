#!/usr/bin/env bash

set -euo pipefail

FFMPEG_BIN="${FFMPEG_BIN:-/home/d501/anaconda3/envs/lyh/bin/ffmpeg}"
FFPROBE_BIN="${FFPROBE_BIN:-/home/d501/anaconda3/envs/lyh/bin/ffprobe}"

if [[ ! -x "$FFMPEG_BIN" ]]; then
    echo "ffmpeg not found at: $FFMPEG_BIN" >&2
    exit 1
fi

if [[ ! -x "$FFPROBE_BIN" ]]; then
    echo "ffprobe not found at: $FFPROBE_BIN" >&2
    exit 1
fi

usage() {
    cat <<'EOF'
Usage:
  reencode_web_mp4.sh input.mp4 [output.mp4]
  reencode_web_mp4.sh --in-place input1.mp4 input2.mp4 ...
  reencode_web_mp4.sh --dir some_folder

Behavior:
  - Re-encodes non-H.264 MP4 files to web-friendly H.264 MP4.
  - Leaves already-compatible H.264 files untouched.
  - Uses yuv420p + faststart for broad browser support.

Environment overrides:
  FFMPEG_BIN=/path/to/ffmpeg
  FFPROBE_BIN=/path/to/ffprobe
EOF
}

codec_name() {
    "$FFPROBE_BIN" -v error -select_streams v:0 \
        -show_entries stream=codec_name \
        -of default=noprint_wrappers=1:nokey=1 "$1" | head -n 1
}

has_audio() {
    local count
    count="$("$FFPROBE_BIN" -v error -select_streams a \
        -show_entries stream=index \
        -of csv=p=0 "$1" | wc -l)"
    [[ "${count// /}" -gt 0 ]]
}

video_encoder() {
    if "$FFMPEG_BIN" -hide_banner -encoders 2>/dev/null | rg -q 'libx264'; then
        echo "libx264"
    elif "$FFMPEG_BIN" -hide_banner -encoders 2>/dev/null | rg -q 'libopenh264'; then
        echo "libopenh264"
    else
        echo "No H.264 encoder found in ffmpeg." >&2
        exit 1
    fi
}

reencode_one() {
    local input="$1"
    local output="$2"
    local codec
    local vencoder
    codec="$(codec_name "$input")"
    vencoder="$(video_encoder)"

    if [[ "$codec" == "h264" ]]; then
        echo "[skip] $input is already H.264"
        if [[ "$input" != "$output" ]]; then
            cp -f "$input" "$output"
        fi
        return 0
    fi

    echo "[reencode] $input -> $output (source codec: $codec)"

    mkdir -p "$(dirname "$output")"

    if has_audio "$input"; then
        "$FFMPEG_BIN" -y -i "$input" \
            -c:v "$vencoder" -b:v 1800k \
            -pix_fmt yuv420p \
            -movflags +faststart \
            -c:a aac -b:a 128k \
            "$output"
    else
        "$FFMPEG_BIN" -y -i "$input" \
            -c:v "$vencoder" -b:v 1800k \
            -pix_fmt yuv420p \
            -movflags +faststart \
            -an \
            "$output"
    fi
}

reencode_in_place() {
    local input="$1"
    local tmp
    tmp="$(dirname "$input")/.tmp.$(basename "$input")"
    reencode_one "$input" "$tmp"
    mv -f "$tmp" "$input"
}

if [[ $# -lt 1 ]]; then
    usage
    exit 1
fi

case "$1" in
    --help|-h)
        usage
        exit 0
        ;;
    --dir)
        [[ $# -eq 2 ]] || { usage; exit 1; }
        while IFS= read -r -d '' file; do
            reencode_in_place "$file"
        done < <(find "$2" -maxdepth 1 -type f -name "*.mp4" -print0 | sort -z)
        ;;
    --in-place)
        [[ $# -ge 2 ]] || { usage; exit 1; }
        shift
        for file in "$@"; do
            reencode_in_place "$file"
        done
        ;;
    *)
        if [[ $# -eq 1 ]]; then
            input="$1"
            output="${input%.mp4}.web.mp4"
            reencode_one "$input" "$output"
        elif [[ $# -eq 2 ]]; then
            reencode_one "$1" "$2"
        else
            usage
            exit 1
        fi
        ;;
esac
