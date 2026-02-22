# OpenClaw Video Analyzer Skill

🎬 Transcribe and analyze YouTube videos using Groq Whisper + Kimi

## Overview

A fast, cost-effective pipeline for extracting insights from YouTube videos:

1. **Groq Whisper** - Transcribes audio 100x faster than real-time (~$0.04/hour)
2. **Kimi (via OpenClaw)** - Analyzes transcript using your existing subscription

## Installation

### Prerequisites

1. **Groq API Key** - Get free credits at [console.groq.com](https://console.groq.com)
   ```bash
   mkdir -p ~/.config/groq
   echo "gsk_your_key_here" > ~/.config/groq/api_key
   ```

2. **yt-dlp** - For downloading YouTube audio
   ```bash
   brew install yt-dlp
   ```

3. **ffmpeg** - Usually installed with yt-dlp
   ```bash
   brew install ffmpeg
   ```

### Link the Skill

```bash
# Clone or navigate to the skill
openclaw skills link /path/to/openclaw-video-analyzer
```

Or add to your `openclaw.json`:
```json
{
  "plugins": {
    "load": {
      "paths": ["/path/to/parent-directory"]
    }
  }
}
```

## Usage

Once linked, just paste a YouTube link and ask:
- "Summarize this video"
- "Analyze this YouTube link"
- "What are the key points?"
- "Extract action items"

The agent will automatically:
1. Download and transcribe using Groq Whisper
2. Analyze using Kimi through your OpenClaw setup
3. Return structured insights

## Cost Comparison

| Method | Cost per Hour | Speed |
|--------|--------------|-------|
| Manual | Your time | Hours |
| OpenAI Whisper | $0.36 | ~5 min |
| **Groq + Kimi** | **~$0.04** | **~2 min** |

## How It Works

```
YouTube URL → yt-dlp → Audio → Groq Whisper → Transcript → Kimi Analysis → Insights
```

## Limitations

- **25MB limit** per audio file (~25 min videos)
- **YouTube only** (currently)
- **English optimized** (other languages may work)

## Future Ideas

- [ ] Chunking for long videos
- [ ] Non-YouTube sources
- [ ] Speaker diarization
- [ ] Timestamp extraction
- [ ] Direct Obsidian export

## License

MIT

## Related

- [OpenClaw](https://openclaw.ai) - The AI agent platform
- [Groq](https://groq.com) - Fast AI inference
- [Kimi](https://kimi.moonshot.cn) - AI assistant
