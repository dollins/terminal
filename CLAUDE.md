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

## VM Setup (Fedora + Claude Code enterprise)

Umožňuje mít dva Claude účty paralelně — osobní lokálně, enterprise přes SSH do VM.

### 1. UTM + Fedora

```bash
# Na macOS:
brew install --cask utm
```

- Stáhnout Fedora Server aarch64 (minimal/netinstall) z fedoraproject.org
- UTM → New VM → Virtualize → Linux → připojit ISO
- RAM: 8 GB, CPU: 4 cores, Disk: 32 GB
- Nainstalovat Fedora s "Minimal Install"

### 2. VM post-install

```bash
# Na VM:
sudo dnf update -y
sudo dnf install -y git curl jq bc nodejs npm openssh-server
sudo systemctl enable --now sshd

# Statická IP (příklad):
sudo nmcli con mod "Wired connection 1" ipv4.addresses 192.168.64.10/24
sudo nmcli con mod "Wired connection 1" ipv4.gateway 192.168.64.1
sudo nmcli con mod "Wired connection 1" ipv4.dns 192.168.64.1
sudo nmcli con mod "Wired connection 1" ipv4.method manual
sudo nmcli con up "Wired connection 1"
```

### 3. SSH z macOS

```bash
# Vygenerovat klíč:
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519_vm -C "petr@fedora-vm"
ssh-copy-id -i ~/.ssh/id_ed25519_vm.pub petr@192.168.64.10

# Přidat do ~/.ssh/config:
Host fedora-vm
  HostName 192.168.64.10
  User petr
  IdentityFile ~/.ssh/id_ed25519_vm
  IdentitiesOnly yes
  ForwardAgent yes
```

### 4. Claude Code na VM

```bash
ssh fedora-vm
npm install -g @anthropic-ai/claude-code
claude auth login --sso    # enterprise účet (otevře URL — zkopírovat do macOS prohlížeče)

# Zkopírovat nastavení:
mkdir -p ~/.claude
# (z macOS): scp statusline-command.sh fedora-vm:~/.claude/
# (z macOS): scp settings.json fedora-vm:~/.claude/

# Přidat do ~/.bashrc na VM:
echo 'export CLAUDE_SSH_HOST="fedora-vm"' >> ~/.bashrc
```

### 5. Aliasy (macOS ~/.zshrc)

```bash
alias claude-personal='claude'
claude-work() { ssh -t fedora-vm "claude $*"; }
```

### Výsledek

```
Tab 1: claude-personal     → lokální, osobní účet
Tab 2: claude-work         → SSH do VM, enterprise účet
        oba mají stejný status line, fonty renderuje Ghostty lokálně
```

## Požadavky

- **macOS + Linux** (skript je cross-platform)
- **Ghostty** — terminál s podporou OSC 8, Nerd Font, true color
- **Nerd Font** — MesloLGSDZ Nerd Font Mono
- **jq** — `brew install jq` / `dnf install jq`
- **VS Code + Remote SSH extension** — pro klikací remote linky
