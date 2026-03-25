# Terminal Setup

Custom terminal configuration for Ghostty + Claude Code with a feature-rich status line.

## Screenshot

```
╭─────────────────────── Line 1 ───────────────────────╮
│  carvago-etl   main (+12 -3)   285k $9.20 4h2m   │
│  Opus 4.6 (󰊛1M)   14%                              │
╰──────────────────────────────────────────────────────╯
╭─────────────────────── Line 2 ───────────────────────╮
│  VSC   claude-work   user@email   5h 1% →25/3 🕐02h │
│  7d 0% →31/3 🕙22h   transcript                     │
╰──────────────────────────────────────────────────────╯
```

## Features

### Status Line

Two-line powerline status bar with Catppuccin Mocha pastel colors and rounded segment transitions.

**Line 1 — Project & Session:**
- **Folder** — project name, Cmd+click opens in Finder (or VS Code Remote when SSH)
- **Git** — branch, virtualenv, lines added/removed, Cmd+click opens repo (GitHub/GitLab)
- **Tokens** — token count, session cost in USD, session duration
- **Model** — model name with context window size
- **Context** — context window usage percentage

**Line 2 — Tools & Limits:**
- **VS Code** — Cmd+click opens project in VS Code (local or Remote SSH)
- **Remote host** — shows hostname when running over SSH (orange segment)
- **Account** — Claude email, Cmd+click opens profile settings
- **Rate limits** — 5h and 7h usage with reset time, dynamic clock icons matching reset hour, Cmd+click opens usage dashboard
- **Transcript** — Cmd+click opens session transcript in VS Code

### Clickable Links (OSC 8)

All Cmd+clickable segments use OSC 8 hyperlinks with ST terminator. Works in Ghostty, iTerm2, Kitty, WezTerm.

| Segment | Opens |
|---|---|
| Folder | Finder / VS Code Remote SSH |
| Git branch | Repository in browser (GitHub/GitLab auto-detected) |
| VS Code | Project in VS Code / VS Code Remote SSH |
| Account | claude.ai/settings/profile |
| Rate limits | claude.ai/settings/usage |
| Transcript | Session transcript in VS Code |

### Multi-Account with Docker

Run two Claude Code accounts simultaneously — personal locally, enterprise in a Docker container.

```
Tab 1: claude-personal     → local macOS, personal account
Tab 2: claude-work         → Docker container via SSH, enterprise account
        same status line, fonts render locally in Ghostty
        ~/Desktop/work is shared between host and container
```

The Docker container runs Fedora 43 with Claude Code and SSH server. The status line automatically detects the remote session and translates VS Code links to `vscode-remote://` URIs.

### Cross-Platform

The status line script works on both macOS and Linux (auto-detects `date -r` vs `date -d @`).

## Quick Start

### 1. Install dependencies

```bash
brew install --cask font-meslo-lg-nerd-font
brew install jq
```

### 2. Deploy configs

```bash
# Ghostty
mkdir -p ~/.config/ghostty
cp ghostty-config ~/.config/ghostty/config

# Claude Code
mkdir -p ~/.claude
cp statusline-command.sh ~/.claude/statusline-command.sh
chmod +x ~/.claude/statusline-command.sh
cp settings.json ~/.claude/settings.json
```

### 3. Multi-account setup (optional)

```bash
# Build and start container
docker compose up -d --build

# Copy SSH key
cat ~/.ssh/id_ed25519.pub | docker exec -i claude-work bash -c \
  "mkdir -p /home/petr/.ssh && cat >> /home/petr/.ssh/authorized_keys && \
   chown -R petr:petr /home/petr/.ssh && chmod 700 /home/petr/.ssh && \
   chmod 600 /home/petr/.ssh/authorized_keys"

# Login enterprise account
ssh -t claude-work "claude auth login --sso"

# Add to ~/.ssh/config
Host claude-work
    HostName localhost
    User petr
    Port 2222
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null

# Add to ~/.zshrc
alias claude-personal='claude'
claude-work() { ssh -t claude-work "claude $*"; }
```

## Files

| File | Description |
|---|---|
| `statusline-command.sh` | Status line script (`~/.claude/`) |
| `settings.json` | Claude Code settings (`~/.claude/`) |
| `ghostty-config` | Ghostty terminal config (`~/.config/ghostty/`) |
| `Dockerfile` | Fedora 43 + Claude Code + SSH server |
| `docker-compose.yml` | Container orchestration |
| `CLAUDE.md` | Detailed setup documentation |

## Requirements

- **macOS** (Apple Silicon or Intel)
- **Ghostty** — terminal with OSC 8, true color, Nerd Font support
- **Nerd Font** — MesloLGSDZ Nerd Font Mono
- **jq** — JSON parsing
- **Docker** — only for multi-account setup
- **VS Code + Remote SSH** — for clickable remote links
