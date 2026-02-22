#!/usr/bin/env bash
#
# video-transcribe.sh - Transcribe video/audio using Groq Whisper
# Usage: video-transcribe.sh <url_or_path> [output_file]
#

set -e

URL="$1"
OUTPUT="${2:-/tmp/transcript_$(date +%s).txt}"
GROQ_API_KEY="${GROQ_API_KEY:-$(cat ~/.config/groq/api_key 2>/dev/null || echo '')}"

if [[ -z "$GROQ_API_KEY" ]]; then
    echo "Error: GROQ_API_KEY not set. Add to ~/.config/groq/api_key or environment." >&2
    exit 1
fi

if [[ -z "$URL" ]]; then
    echo "Usage: video-transcribe.sh <url_or_path> [output_file]" >&2
    exit 1
fi

# Create temp directory
TMPDIR=$(mktemp -d)
trap "rm -rf $TMPDIR" EXIT

echo "📥 Downloading audio..." >&2

# Download audio using yt-dlp for YouTube URLs, or use file directly
if [[ "$URL" =~ ^https?://(www\.)?(youtube|youtu\.be) ]]; then
    # YouTube URL - extract audio
    yt-dlp -q -x --audio-format mp3 --audio-quality 0 \
        -o "$TMPDIR/audio.%(ext)s" "$URL" 2>&1 | grep -v "^\[download\]" || true
    AUDIO_FILE=$(find "$TMPDIR" -name "*.mp3" -o -name "*.m4a" -o -name "*.webm" | head -1)
else
    # Check if it's a local file
    if [[ -f "$URL" ]]; then
        AUDIO_FILE="$URL"
    else
        echo "Error: Unsupported URL or file not found: $URL" >&2
        exit 1
    fi
fi

if [[ -z "$AUDIO_FILE" || ! -f "$AUDIO_FILE" ]]; then
    echo "Error: Failed to extract audio" >&2
    exit 1
fi

echo "🎯 Transcribing with Groq Whisper..." >&2

# Get file size for progress indication
FILE_SIZE=$(stat -f%z "$AUDIO_FILE" 2>/dev/null || stat -c%s "$AUDIO_FILE" 2>/dev/null || echo "0")
echo "   File size: $(($FILE_SIZE / 1024 / 1024)) MB" >&2

# Call Groq API for transcription
# Groq supports files up to 25MB; if larger, we'd need to chunk (not implemented here)
if [[ $FILE_SIZE -gt 26214400 ]]; then
    echo "⚠️  Warning: File >25MB. Groq has a 25MB limit. Consider using shorter videos." >&2
fi

curl -s -X POST "https://api.groq.com/openai/v1/audio/transcriptions" \
    -H "Authorization: Bearer $GROQ_API_KEY" \
    -H "Content-Type: multipart/form-data" \
    -F "file=@$AUDIO_FILE" \
    -F "model=whisper-large-v3" \
    -F "response_format=text" \
    -F "language=en" \
    > "$OUTPUT"

if [[ ! -s "$OUTPUT" ]]; then
    echo "Error: Transcription failed or returned empty" >&2
    exit 1
fi

echo "✅ Transcript saved to: $OUTPUT" >&2
echo "   Word count: $(wc -w < "$OUTPUT")" >&2

echo "$OUTPUT"
