# Terminal & Claude Code Setup

Konfigurace pro čistou instalaci: Ghostty + Claude Code + status line.
Podporuje lokální i remote (VM přes SSH) použití.

## Soubory v repu

| Soubor | Kam zkopírovat | Popis |
|---|---|---|
| `statusline-command.sh` | `~/.claude/statusline-command.sh` | Status line skript |
| `settings.json` | `~/.claude/settings.json` | Claude Code nastavení |
| `ghostty-config` | `~/.config/ghostty/config` | Ghostty konfigurace |

## Instalace na čistém stroji (macOS)

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
- `attribution: { commit: "", pr: "" }` — bez attribution
- `effortLevel: "high"` — maximální úroveň úsilí
- `statusLine` — custom status line skript

## Status Line

### Řádek 1 (pastelové Catppuccin barvy, powerline kulaté segmenty)

| Segment | Barva | Obsah | Cmd+click |
|---|---|---|---|
| Složka | tmavě šedá | název projektu | otevře složku (Finder / VS Code Remote) |
| Git | fialová | branch, venv, +/- řádky | otevře repo v prohlížeči (GitHub/GitLab) |
| Tokeny | modrá | počet tokenů, cena, čas session | — |
| Model | zelená | název modelu (context size) | — |
| Context | žlutá | % využití context window | — |

### Řádek 2

| Segment | Barva | Obsah | Cmd+click |
|---|---|---|---|
| VS Code | modrá | ikona + VSC | otevře projekt ve VS Code (lokálně / Remote SSH) |
| Remote host | oranžová | hostname VM | jen při SSH session |
| Account | tmavě šedá | Claude email | claude.ai/settings/profile |
| 5h limit | růžová | %, datum+hodina resetu | claude.ai/settings/usage |
| 7d limit | tmavě červená | %, datum+hodina resetu | claude.ai/settings/usage |
| Transcript | tmavě šedá | ikona + transcript | otevře transcript ve VS Code |

### Remote podpora

Skript detekuje env var `CLAUDE_SSH_HOST`. Když je nastavený:
- Folder link → `vscode://vscode-remote/ssh-remote+HOST/path`
- VSC link → `vscode://vscode-remote/ssh-remote+HOST/path`
- Transcript → `vscode://vscode-remote/ssh-remote+HOST/path`
- Zobrazí se oranžový segment s názvem remote hostu

Skript je cross-platform (macOS `date -r` i Linux `date -d @`).

## Docker Setup (Claude Code enterprise)

Umožňuje mít dva Claude účty paralelně — osobní lokálně, enterprise v Docker kontejneru přes SSH.

### Proč Docker místo VM?

| | VM (UTM) | Docker |
|---|---|---|
| Start | ~30s | ~1s |
| RAM | 8 GB fixně | sdílený |
| Disk | 32 GB image | ~500 MB |
| Údržba | dnf update | rebuild image |
| Portabilita | lokálně | kdekoli |

### Soubory

- `Dockerfile` — Fedora 43 minimal + Claude Code + SSH
- `docker-compose.yml` — služba, volumes, port mapping

### 1. Spustit kontejner

```bash
cd ~/Desktop/work/terminal
docker compose up -d --build
```

### 2. Nastavit SSH klíč

```bash
# Zkopírovat public key do kontejneru:
ssh-copy-id -p 2222 petr@localhost

# Nebo ručně:
cat ~/.ssh/id_ed25519.pub | ssh -p 2222 petr@localhost "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"
```

### 3. Přihlásit Claude Code (enterprise)

```bash
ssh claude-work
claude auth login --sso
# Otevře URL → zkopírovat do macOS prohlížeče → enterprise účet
```

### 4. SSH config (macOS ~/.ssh/config)

```
Host claude-work
    HostName localhost
    User petr
    Port 2222
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
```

### 5. Aliasy (macOS ~/.zshrc)

```bash
alias claude-personal='claude'
claude-work() { ssh -t claude-work "claude $*"; }
```

### Sdílené soubory

`docker-compose.yml` mountuje `~/Desktop/work` do kontejneru jako `/home/petr/work`. Soubory jsou sdílené — editujete lokálně, Claude Code v kontejneru je vidí.

### Výsledek

```
Tab 1: claude-personal     → lokální, osobní účet
Tab 2: claude-work         → Docker kontejner, enterprise účet
        oba mají stejný status line, fonty renderuje Ghostty lokálně
        ~/Desktop/work je sdílený
```

### Status line v remote

Skript automaticky detekuje `CLAUDE_SSH_HOST` env var (nastavený v kontejneru). Když je remote:
- VSC linky → `vscode://vscode-remote/ssh-remote+claude-work/path`
- Oranžový segment s názvem hostu
- Folder link → otevře ve VS Code Remote SSH

## Požadavky

- **macOS + Linux** (skript je cross-platform)
- **Ghostty** — terminál s podporou OSC 8, Nerd Font, true color
- **Nerd Font** — MesloLGSDZ Nerd Font Mono
- **Docker** — `brew install --cask docker`
- **jq** — `brew install jq`
- **VS Code + Remote SSH extension** — pro klikací remote linky
