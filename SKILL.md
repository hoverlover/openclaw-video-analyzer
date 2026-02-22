---
name: video-analyzer
description: Transcribe and analyze YouTube videos using Groq Whisper for fast transcription. Use when the user provides a YouTube URL and asks to summarize, analyze, transcribe, or extract insights from a video. Trigger phrases include "summarize this video", "analyze this YouTube link", "what's this video about", "transcribe this", "extract key points from video".
metadata:
  {
    "openclaw": { "always": true, "emoji": "🎬" }
  }
---

# Video Analyzer

Transcribe YouTube videos and analyze them using the agent's LLM.

## When to Use

- User provides a YouTube URL and asks for summary/analysis
- User wants key points, action items, or notable quotes from a video
- User asks "what's this video about?" or similar

## How to Use

### Step 1: Transcribe the Video

Run the transcription script with the YouTube URL:

```bash
TRANSCRIPT_FILE=$(mktemp)
{baseDir}/scripts/video-transcribe.sh "https://youtu.be/VIDEO_ID" "$TRANSCRIPT_FILE"
```

The script will:
- Download audio from YouTube
- Transcribe using Groq Whisper
- Automatically chunk videos >25 min into smaller segments
- Output a plain text transcript

### Step 2: Read the Transcript

```bash
cat "$TRANSCRIPT_FILE"
```

### Step 3: Analyze Based on User Request

Use the appropriate analysis mode below based on what the user asked for.

## Analysis Modes

### Summary Mode
Use when user asks for a summary or overview:

```
Provide a concise 3-5 paragraph summary of this video transcript.
Focus on the main topic, key arguments, and conclusion.

TRANSCRIPT:
[transcript content]
```

### Key Points Mode
Use when user asks for key points or takeaways:

```
Extract the 10-15 most important key points from this video transcript.
Format as a bulleted list with clear, actionable insights.

TRANSCRIPT:
[transcript content]
```

### Action Items Mode
Use when user asks for actions, recommendations, or steps:

```
Extract all action items, recommendations, and concrete steps mentioned
in this video transcript. Format as a checklist.

TRANSCRIPT:
[transcript content]
```

### Notable Quotes Mode
Use when user asks for specific quotes or memorable lines:

```
Extract 3-5 notable quotes from this video transcript.
Include attribution if speakers are identified.
Format as:
- "Quote text" - Speaker Name

TRANSCRIPT:
[transcript content]
```

### Full Analysis Mode (Default)
Use when user asks for comprehensive analysis or doesn't specify:

```
Analyze this video transcript comprehensively:

1. SUMMARY (2-3 paragraphs)
2. KEY POINTS (10-15 bullet points)
3. ACTION ITEMS (if any concrete recommendations)
4. NOTABLE QUOTES (2-3 memorable quotes with attribution if mentioned)
5. CONTEXT (who is speaking, their expertise/background if apparent)

Be thorough but concise.

TRANSCRIPT:
[transcript content]
```

## Finding Specific Content

If the user asks about a specific topic, person, or quote in the video:

1. Read the full transcript first
2. Search for keywords related to their question
3. Quote the relevant sections verbatim with timestamps if available
4. Provide context around the quote

## Output Format

Return your analysis in clean markdown:
- Use headers for sections
- Use bullet points for lists
- Use bold for emphasis
- Quote verbatim when referencing specific statements
- Keep responses concise but comprehensive
