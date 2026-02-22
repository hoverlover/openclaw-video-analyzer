#!/usr/bin/env bash
#
# video-transcribe.sh - Transcribe video/audio using Groq Whisper
# Usage: video-transcribe.sh <url_or_path> [output_file]
#
# Supports chunking for files >25MB (Groq's limit)
# Chunks are split at natural silence points between 10-15 minutes
#

set -e

URL="$1"
OUTPUT="${2:-/tmp/transcript_$(date +%s).txt}"
GROQ_API_KEY="${GROQ_API_KEY:-$(cat ~/.config/groq/api_key 2>/dev/null || echo '')}"
GROQ_LIMIT_BYTES=26214400  # 25MB

# Chunking config (in seconds)
MIN_CHUNK=600      # 10 min - don't split before this
TARGET_CHUNK=720   # 12 min - ideal split point
MAX_CHUNK=900      # 15 min - force split if no silence found

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

get_duration() {
    ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$1" 2>/dev/null | cut -d. -f1
}

# Detect silence points and return split timestamps
# Args: audio_file min_chunk max_chunk
# Output: space-separated list of split points in seconds
find_split_points() {
    local audio_file="$1"
    local min_chunk="$2"
    local max_chunk="$3"
    local duration=$(get_duration "$audio_file")
    
    if [[ -z "$duration" ]]; then
        echo "Error: Could not determine audio duration" >&2
        return 1
    fi
    
    # If under max chunk, no splitting needed
    if [[ $duration -le $max_chunk ]]; then
        return 0
    fi
    
    # Find all silence points using ffprobe (silence >0.3s, below -40dB)
    local silences=$(ffprobe -v error -f lavfi -i "silencedetect=n=-40dB:d=0.3" \
        -show_entries frame_tags=lavfi.silence_start,lavfi.silence_end \
        -of default=noprint_wrappers=1 "$audio_file" 2>&1 | \
        grep -E "silence_start|silence_end" | \
        grep "silence_end" | sed 's/.*=//' | sort -n)
    
    local splits=""
    local last_split=0
    local next_target=$min_chunk
    
    while [[ $next_target -lt $duration ]]; do
        local best_split=""
        local best_distance=999999
        
        # Look for silence within acceptable window
        for silence in $silences; do
            # Round to integer
            silence_int=${silence%.*}
            
            # Skip if before our target window
            if [[ $silence_int -lt $next_target ]]; then
                continue
            fi
            
            # Skip if after max chunk from last split
            if [[ $silence_int -gt $((last_split + max_chunk)) ]]; then
                break
            fi
            
            # Calculate distance from target (prefer closer to target_chunk from last_split)
            local ideal=$((last_split + TARGET_CHUNK))
            local distance=$((silence_int > ideal ? silence_int - ideal : ideal - silence_int))
            
            if [[ $distance -lt $best_distance ]]; then
                best_distance=$distance
                best_split=$silence_int
            fi
        done
        
        # If no good silence found, force split at max_chunk
        if [[ -z "$best_split" ]]; then
            best_split=$((last_split + max_chunk))
            if [[ $best_split -ge $duration ]]; then
                break
            fi
        fi
        
        splits="$splits $best_split"
        last_split=$best_split
        next_target=$((last_split + min_chunk))
    done
    
    echo "$splits" | xargs  # trim whitespace
}

# Transcribe a single audio file
# Args: audio_file output_file
transcribe_file() {
    local audio_file="$1"
    local out_file="$2"
    
    curl -s -X POST "https://api.groq.com/openai/v1/audio/transcriptions" \
        -H "Authorization: Bearer $GROQ_API_KEY" \
        -H "Content-Type: multipart/form-data" \
        -F "file=@$audio_file" \
        -F "model=whisper-large-v3" \
        -F "response_format=text" \
        -F "language=en" \
        > "$out_file"
    
    if [[ ! -s "$out_file" ]]; then
        return 1
    fi
    return 0
}

echo "📥 Downloading audio..." >&2

# Download audio using yt-dlp for YouTube URLs, or use file directly
if [[ "$URL" =~ ^https?://(www\.)?(youtube|youtu\.be) ]]; then
    # YouTube URL - extract audio (MP3 for better compatibility)
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

# Get file info
FILE_SIZE=$(stat -f%z "$AUDIO_FILE" 2>/dev/null || stat -c%s "$AUDIO_FILE" 2>/dev/null || echo "0")
FILE_SIZE_MB=$(($FILE_SIZE / 1024 / 1024))
DURATION=$(get_duration "$AUDIO_FILE")
DURATION_MIN=$((DURATION / 60))

echo "📊 Audio info: ${FILE_SIZE_MB}MB, ~${DURATION_MIN} minutes" >&2

# Determine if chunking is needed
NEEDS_CHUNKING=false
if [[ $FILE_SIZE -gt $GROQ_LIMIT_BYTES ]] || [[ $DURATION -gt $MAX_CHUNK ]]; then
    NEEDS_CHUNKING=true
fi

if [[ "$NEEDS_CHUNKING" == "true" ]]; then
    echo "✂️  File exceeds Groq limits. Using smart chunking..." >&2
    
    # Find split points
    SPLIT_POINTS=$(find_split_points "$AUDIO_FILE" $MIN_CHUNK $MAX_CHUNK)
    
    if [[ -z "$SPLIT_POINTS" ]]; then
        # Shouldn't happen if duration > max_chunk, but handle gracefully
        echo "   No splits needed (single chunk)" >&2
        NEEDS_CHUNKING=false
    else
        echo "   Split points (seconds): $SPLIT_POINTS" >&2
        
        # Split the audio file
        # Use segment muxer with re-encoding for precise cuts at silence points
        prev=0
        i=1
        segments=""
        
        for split in $SPLIT_POINTS; do
            seg_file="$TMPDIR/chunk_$(printf "%03d" $i).mp3"
            
            # Extract segment using ffmpeg with re-encoding for clean cuts
            ffmpeg -y -i "$AUDIO_FILE" -ss $prev -to $split -c:a libmp3lame -q:a 2 \
                "$seg_file" 2>/dev/null
            
            if [[ -f "$seg_file" ]]; then
                segments="$segments $seg_file"
                ((i++))
            fi
            
            prev=$split
        done
        
        # Final segment (from last split to end)
        final_seg="$TMPDIR/chunk_$(printf "%03d" $i).mp3"
        ffmpeg -y -i "$AUDIO_FILE" -ss $prev -c:a libmp3lame -q:a 2 \
            "$final_seg" 2>/dev/null
        
        if [[ -f "$final_seg" ]]; then
            segments="$segments $final_seg"
        fi
        
        # Transcribe each chunk
        echo "🎯 Transcribing $(echo $segments | wc -w) chunks..." >&2
        
        chunk_num=1
        total_chunks=$(echo $segments | wc -w)
        
        > "$OUTPUT"  # Clear output file
        
        for seg in $segments; do
            chunk_out="$TMPDIR/chunk_${chunk_num}_transcript.txt"
            
            echo "   Chunk $chunk_num/$total_chunks..." >&2
            
            if ! transcribe_file "$seg" "$chunk_out"; then
                echo "Error: Failed to transcribe chunk $chunk_num" >&2
                exit 1
            fi
            
            # Append to final output with paragraph break
            cat "$chunk_out" >> "$OUTPUT"
            echo -e "\n\n" >> "$OUTPUT"
            
            ((chunk_num++))
        done
        
        echo "✅ Chunks combined into final transcript" >&2
    fi
fi

# Standard single-file transcription (no chunking needed)
if [[ "$NEEDS_CHUNKING" != "true" ]]; then
    echo "🎯 Transcribing with Groq Whisper..." >&2
    
    if ! transcribe_file "$AUDIO_FILE" "$OUTPUT"; then
        echo "Error: Transcription failed or returned empty" >&2
        exit 1
    fi
fi

# Final output
WORD_COUNT=$(wc -w < "$OUTPUT" | tr -d ' ')
echo "✅ Transcript saved to: $OUTPUT" >&2
echo "   Word count: $WORD_COUNT" >&2

echo "$OUTPUT"
