# Terminal & Claude Code Setup

## Status Line

Status line skript pro Claude Code: `statusline-command.sh`

### Instalace

1. **Nainstalovat Nerd Font** (nutné pro ikony):
   ```bash
   brew install --cask font-meslo-lg-nerd-font
   ```

2. **Nastavit font v Ghostty** (`~/.config/ghostty/config`):
   ```
   font-family = MesloLGSDZ Nerd Font Mono
   ```

3. **Zkopírovat skript**:
   ```bash
   cp statusline-command.sh ~/.claude/statusline-command.sh
   chmod +x ~/.claude/statusline-command.sh
   ```

4. **Nastavit v Claude Code** (`~/.claude/settings.json`):
   ```json
   {
     "statusLine": {
       "type": "command",
       "command": "bash ~/.claude/statusline-command.sh",
       "padding": 0
     }
   }
   ```

### Co status line zobrazuje

**Řádek 1** (pastelové Catppuccin barvy, powerline kulaté segmenty):
| Segment | Barva | Obsah | Klik (Cmd+click) |
|---|---|---|---|
| Složka | tmavě šedá | název projektu | otevře složku ve Finderu |
| Git | fialová | branch, venv, +/- řádky | otevře repo v prohlížeči (GitHub/GitLab) |
| Tokeny | modrá | počet tokenů, cena, čas session | — |
| Model | zelená | název modelu (context size) | — |
| Context | žlutá | % využití context window | — |

**Řádek 2**:
| Segment | Barva | Obsah | Klik (Cmd+click) |
|---|---|---|---|
| VS Code | modrá | ikona + VSC | otevře projekt ve VS Code |
| 5h limit | růžová | %, datum+hodina resetu | claude.ai/settings/usage |
| 7d limit | tmavě červená | %, datum+hodina resetu | claude.ai/settings/usage |
| Transcript | tmavě šedá | ikona + transcript | otevře transcript ve VS Code |

### Požadavky

- **Nerd Font** — MesloLGSDZ Nerd Font Mono (nebo jiný Nerd Font)
- **jq** — pro parsování JSON (`brew install jq`)
- **bc** — pro výpočty (součást macOS)
- **Ghostty** — terminál s podporou OSC 8 hyperlinků
