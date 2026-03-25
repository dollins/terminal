# Terminal & Claude Code Setup

Konfigurace pro čistou instalaci: Ghostty + Claude Code + status line.

## Soubory v repu

| Soubor | Kam zkopírovat | Popis |
|---|---|---|
| `statusline-command.sh` | `~/.claude/statusline-command.sh` | Status line skript |
| `settings.json` | `~/.claude/settings.json` | Claude Code nastavení |
| `ghostty-config` | `~/.config/ghostty/config` | Ghostty konfigurace |

## Instalace na čistém stroji

### 1. Font (nutné pro ikony)

```bash
brew install --cask font-meslo-lg-nerd-font
```

### 2. Závislosti

```bash
brew install jq    # parsování JSON (bc je součást macOS)
```

### 3. Ghostty config

```bash
mkdir -p ~/.config/ghostty
cp ghostty-config ~/.config/ghostty/config
```

### 4. Claude Code config

```bash
mkdir -p ~/.claude
cp statusline-command.sh ~/.claude/statusline-command.sh
chmod +x ~/.claude/statusline-command.sh
cp settings.json ~/.claude/settings.json
```

## Claude Code nastavení (`settings.json`)

- `includeCoAuthoredBy: false` — nepřidávat Co-Authored-By do commitů
- `effortLevel: "high"` — maximální úroveň úsilí
- `statusLine` — custom status line skript

## Status Line

### Řádek 1 (pastelové Catppuccin barvy, powerline kulaté segmenty)

| Segment | Barva | Obsah | Cmd+click |
|---|---|---|---|
| Složka | tmavě šedá | název projektu | otevře složku ve Finderu |
| Git | fialová | branch, venv, +/- řádky | otevře repo v prohlížeči (GitHub/GitLab) |
| Tokeny | modrá | počet tokenů, cena, čas session | — |
| Model | zelená | název modelu (context size) | — |
| Context | žlutá | % využití context window | — |

### Řádek 2

| Segment | Barva | Obsah | Cmd+click |
|---|---|---|---|
| VS Code | modrá | ikona + VSC | otevře projekt ve VS Code |
| 5h limit | růžová | %, datum+hodina resetu | claude.ai/settings/usage |
| 7d limit | tmavě červená | %, datum+hodina resetu | claude.ai/settings/usage |
| Transcript | tmavě šedá | ikona + transcript | otevře transcript ve VS Code |

### Klikací OSC 8 odkazy

Status line používá OSC 8 hyperlinky (ST terminátor `\033\\`). Funguje v Ghostty, iTerm2, Kitty, WezTerm. Vyžaduje Cmd+click.

### Ikony hodin u rate limitů

Používají se `nf-weather-time` ikony (U+E381–U+E38C) — hodiny na ikoně odpovídají hodině resetu limitu.

## Požadavky

- **macOS** (script používá `date -r` pro timestamp formátování)
- **Ghostty** — terminál s podporou OSC 8, Nerd Font, true color
- **Nerd Font** — MesloLGSDZ Nerd Font Mono
- **jq** — `brew install jq`
