# OpenClaw Video Analyzer Skill

🎬 Transcribe and analyze YouTube videos using Groq Whisper + OpenClaw

## Overview

A fast, cost-effective pipeline for extracting insights from YouTube videos:

1. **Groq Whisper** - Transcribes audio 100x faster than real-time (~$0.04/hour)
2. **OpenClaw Agent** - Analyzes transcript using your configured LLM

## Installation

### Prerequisites

1. **Groq API Key** - Get free credits at [console.groq.com](https://console.groq.com)
   ```bash
   mkdir -p ~/.config/groq
   echo "gsk_your_key_here" > ~/.config/groq/api_key
   ```

2. **yt-dlp** - For downloading YouTube audio

   **macOS:** `brew install yt-dlp`  
   **Debian/Ubuntu:** `sudo apt install yt-dlp`  
   **Arch:** `sudo pacman -S yt-dlp`  
   **Other (Python):** `pip3 install yt-dlp`  
   **Other (binary):** Download from [yt-dlp releases](https://github.com/yt-dlp/yt-dlp/releases)

3. **ffmpeg** - Audio processing (often a yt-dlp dependency)

   **macOS:** `brew install ffmpeg`  
   **Debian/Ubuntu:** `sudo apt install ffmpeg`  
   **Arch:** `sudo pacman -S ffmpeg`  
   **Other:** See [ffmpeg.org/download](https://ffmpeg.org/download.html)

### Install the Skill

OpenClaw loads skills from **3 locations** (in order of precedence):

| Location | Path | Precedence |
|----------|------|------------|
| **Workspace skills** | `<workspace>/skills/` | Highest |
| **Managed/local skills** | `~/.openclaw/skills/` | Middle |
| **Bundled skills** | Shipped with OpenClaw | Lowest |

If a skill name conflicts, workspace wins → managed/local → bundled.

**Clone into managed skills (recommended for shared use):**

```bash
mkdir -p ~/.openclaw/skills
git clone https://github.com/hoverlover/openclaw-video-analyzer.git ~/.openclaw/skills/video-analyzer
```

**Or clone into workspace skills (project-specific):**

```bash
git clone https://github.com/hoverlover/openclaw-video-analyzer.git ./skills/video-analyzer
```

Then restart OpenClaw: `openclaw gateway restart`

*You can also configure extra skill folders via `skills.load.extraDirs` in `~/.openclaw/openclaw.json` (lowest precedence).*

## Usage

Once installed, just paste a YouTube link and ask:
- "Summarize this video"
- "Analyze this YouTube link"
- "What are the key points?"
- "Extract action items"

The agent will automatically:
1. Download and transcribe using Groq Whisper
2. Analyze using your OpenClaw agent's LLM
3. Return structured insights

## Cost Comparison

| Method | Cost per Hour | Speed |
|--------|--------------|-------|
| Manual | Your time | Hours |
| OpenAI Whisper | $0.36 | ~5 min |
| **Groq Whisper** | **~$0.04** | **~2 min** |

## How It Works

```
YouTube URL → yt-dlp → Audio → Groq Whisper → Transcript → OpenClaw Analysis → Insights
```

## How Chunking Works

For videos longer than ~15 minutes or larger than 25MB, the script automatically:

1. **Detects silence points** using ffmpeg's `silencedetect` filter
2. **Finds optimal split points** between 10-15 minute intervals, preferring natural pauses
3. **Transcribes each chunk** sequentially via Groq Whisper
4. **Stitches transcripts** together with paragraph breaks

This keeps each chunk well under Groq's 25MB limit while maintaining natural speech boundaries.

## Limitations

- **YouTube only** (currently)
- **English optimized** (other languages may work)

## Future Ideas

- [x] Chunking for long videos (✅ implemented)
- [ ] Non-YouTube sources
- [ ] Speaker diarization
- [ ] Timestamp extraction
- [ ] Direct Obsidian export

## License

MIT

## Related

- [OpenClaw](https://openclaw.ai) - The AI agent platform
- [Groq](https://groq.com) - Fast AI inference
