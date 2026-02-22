---
name: video-analyzer
description: Transcribe and analyze YouTube videos using Groq Whisper for fast/cheap transcription, then analyze with the agent's LLM (Kimi). Use when the user wants to summarize, analyze, or extract insights from YouTube videos. Trigger phrases: "summarize this video", "analyze this YouTube link", "transcribe this", "what's this video about", "extract key points from video".
metadata: {"openclaw": {"always": true, "emoji": "🎬"}}
---

# Video Analyzer

Two-stage video analysis pipeline:
1. **Groq Whisper** - Transcribes audio 100x faster than real-time at $0.04/hour
2. **Agent LLM (Kimi)** - Analyzes transcript using your existing Kimi subscription

## Quick Start

### Prerequisites

1. **Groq API Key**: Get free credits at https://console.groq.com
   ```bash
   mkdir -p ~/.config/groq
   echo "gsk_your_key_here" > ~/.config/groq/api_key
   ```

2. **yt-dlp**: For downloading YouTube audio
   ```bash
   brew install yt-dlp
   ```

## Usage

When the user drops a YouTube link and asks for analysis:

1. **Transcribe** using the script:
   ```bash
   TRANSCRIPT_FILE=$(mktemp)
   ~/.openclaw/skills/video-analyzer/scripts/video-transcribe.sh "https://youtu.be/..." "$TRANSCRIPT_FILE"
   ```

2. **Analyze** using your LLM capabilities (Kimi via OpenClaw):
   - Read the transcript file
   - Apply the appropriate analysis prompt based on user request
   - Return structured analysis

## Analysis Prompts

### Summary Mode
```
Provide a concise 3-5 paragraph summary of the following video transcript. 
Focus on the main topic, key arguments, and conclusion.

TRANSCRIPT:
[content]
```

### Key Points Mode
```
Extract the 10-15 most important key points from this video transcript. 
Format as a bulleted list with clear, actionable insights.

TRANSCRIPT:
[content]
```

### Action Items Mode
```
Extract all action items, recommendations, and concrete steps mentioned 
in this video transcript. Format as a checklist.

TRANSCRIPT:
[content]
```

### Full Analysis Mode (default)
```
Analyze this video transcript comprehensively:

1. SUMMARY (2-3 paragraphs)
2. KEY POINTS (10-15 bullet points)
3. ACTION ITEMS (if any concrete recommendations)
4. NOTABLE QUOTES (2-3 memorable quotes with attribution if mentioned)
5. CONTEXT (who is speaking, their expertise/background if apparent)

Be thorough but concise.

TRANSCRIPT:
[content]
```

## How It Works

### Stage 1: Transcription (Groq Whisper)
- Downloads audio from YouTube using yt-dlp
- Sends audio to Groq's Whisper Large v3 API
- Returns raw transcript text
- **Cost**: ~$0.04 per hour of video
- **Speed**: ~30 seconds for 1 hour of audio

### Stage 2: Analysis (Agent LLM - Kimi)
- Reads transcript file
- Applies analysis prompt based on user request
- Uses your existing Kimi subscription via OpenClaw
- **Cost**: Uses your Kimi code subscription (no additional API cost)

### Total Cost Comparison
| Method | Cost per Hour | Speed |
|--------|--------------|-------|
| Manual | Your time | Hours |
| OpenAI Whisper | $0.36 | ~5 min |
| **Groq + Kimi** | **~$0.04** | **~2 min** |

## Limitations

- **File size**: Groq has 25MB limit per request (handles ~25 min videos)
- **Language**: Optimized for English; other languages may work but not tested
- **YouTube only**: Currently supports YouTube URLs only
- **Chunking**: Videos >25 min would need chunking (not yet implemented)

## Installation

This skill is installed via OpenClaw's skill link method:

```bash
openclaw skills link /path/to/video-analyzer
```

Or add to your openclaw.json:
```json
{
  "skills": {
    "additional": ["/path/to/video-analyzer"]
  }
}
```

## Future Enhancements

- [ ] Chunking for long videos (>25 min)
- [ ] Support for non-YouTube sources
- [ ] Speaker diarization (who said what)
- [ ] Timestamp extraction for key moments
- [ ] Direct Obsidian integration (save analysis to vault)
