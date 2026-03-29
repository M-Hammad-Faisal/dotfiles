# dotfiles

Config-driven macOS dotfiles. One file rules everything: **edit `config.json`, run `bootstrap.sh`**.

---

## Setup for a New Machine

### First Time
```bash
# 1. Clone (HTTPS if SSH not set up yet)
git clone https://github.com/YOUR_USERNAME/dotfiles.git ~/dotfiles

# 2. Copy example config
cp ~/dotfiles/config.example.json ~/dotfiles/config.json

# 3. Fill in your details
code ~/dotfiles/config.json

# 4. Run bootstrap
bash ~/dotfiles/bootstrap.sh
```

### What's in config.json
| Field | What to fill in |
|-------|----------------|
| `git.accounts` | Your GitHub usernames, emails, preferred SSH key names |
| `node.version` | Specific version like `"20"`, or `"lts"` for latest LTS |
| `python.version` | Specific version like `"3.11.9"`, or `"latest"` |
| `gcloud.enabled` | `true` if you use Google Cloud, `false` otherwise |
| `brew.packages.extras` | Any brew packages beyond the defaults |
| `brew.casks.extras` | Any brew casks beyond the defaults |
| `npm_globals.packages` | e.g. `["@anthropic-ai/claude-code", "typescript"]` |
| `pip_globals.packages` | e.g. `["playwright", "black"]` |
| `mas.apps` | Mac App Store apps with their IDs |
| `manual_installs` | Anything that can't be automated — shown in final checklist |
| `aliases.custom` | Your own shell aliases |

### Adding a New Git Account
1. Add an entry to `git.accounts` in `config.json`
2. Run: `bash install/ssh.sh && bash generate/ssh_config.sh && bash generate/zshrc.sh && bash symlink.sh`

### Updating Node or Python Version
1. Change the version in `config.json`
2. Run: `bash install/node.sh` or `bash install/python.sh`

### Regenerating Config Files Only (no reinstall)
```bash
bash generate/zshrc.sh
bash generate/gitconfig.sh
bash generate/ssh_config.sh
bash symlink.sh
```

---

## How it works

`config.json` is the single source of truth. Every script reads from it via `jq`. Nothing is hardcoded in any script.

```
config.json  →  generate/*.sh  →  config/  →  symlink.sh  →  ~/.zshrc, ~/.gitconfig, etc.
                install/*.sh   (brew, node, python, gcloud, ssh)
```

The `config/` directory is **auto-generated** — never edit those files directly.

---

## Quick start

```bash
git clone git@github.com-personal:YOUR_USERNAME/dotfiles.git ~/dotfiles
cd ~/dotfiles
bash bootstrap.sh
```

---

## How to customize

### Add a brew package
Add to `brew.packages.extras` in `config.json`, then:
```bash
bash bootstrap.sh --only=brew
```

### Change Node.js version
Edit `node.version` in `config.json`, then:
```bash
bash bootstrap.sh --only=node
```
Use `"lts"` or `"latest"` to auto-resolve.

### Change Python version
Edit `python.version` in `config.json`, then:
```bash
bash bootstrap.sh --only=python
```
Use `"latest"` to auto-resolve to the latest 3.x.

### Add a git account
Add an entry to `git.accounts` in `config.json`:
```json
{
  "name": "YourGitHubUsername",
  "email": "you@example.com",
  "host_alias": "github.com-work",
  "key_name": "id_ed25519_work",
  "default": false
}
```
Then re-run:
```bash
bash bootstrap.sh
```
This will generate the SSH key, update `~/.ssh/config`, and print the public key to add to GitHub.

### Add custom shell aliases
Add to `aliases.custom` in `config.json`:
```json
"custom": {
  "myalias": "some command"
}
```
Then regenerate:
```bash
bash generate/zshrc.sh && bash symlink.sh
```

---

## Git identity aliases

After setup, switch identity per-repo:
```bash
cd ~/work/some-repo
git-work       # sets user.name + user.email to work account
```
```bash
cd ~/personal/some-repo
git-personal   # sets user.name + user.email to personal account
```

---

## Cloning repos with SSH host aliases

Use the host alias instead of `github.com`:
```bash
# Personal account
git clone git@github.com-personal:YOUR_PERSONAL_USERNAME/repo.git

# Work account
git clone git@github.com-work:YOUR_WORK_USERNAME/repo.git
```

---

## Run a single module

```bash
bash bootstrap.sh --only=brew
bash bootstrap.sh --only=node
bash bootstrap.sh --only=python
bash bootstrap.sh --only=gcloud
bash bootstrap.sh --only=ssh
```

---

## Regenerate config files without full reinstall

```bash
bash generate/zshrc.sh && bash symlink.sh
bash generate/gitconfig.sh && bash symlink.sh
bash generate/ssh_config.sh && bash symlink.sh
```

Or all at once:
```bash
bash generate/zshrc.sh && bash generate/gitconfig.sh && bash generate/ssh_config.sh && bash symlink.sh
```

---

## Manual steps (after first run)

For each SSH key, copy its public key and add it to the corresponding GitHub account:

```bash
# Personal account key
cat ~/.ssh/id_ed25519_personal.pub
# → Add at: https://github.com/settings/ssh/new  (logged in as your personal account)

# Work account key
cat ~/.ssh/id_ed25519_work.pub
# → Add at: https://github.com/settings/ssh/new  (logged in as your work account)
```

Test connections:
```bash
ssh -T git@github.com-personal
ssh -T git@github.com-work
```

---

## File map

| File | Purpose |
|---|---|
| `config.json` | Single source of truth — edit this |
| `bootstrap.sh` | Full setup entry point |
| `symlink.sh` | Creates symlinks from `config/` to `~/` |
| `install/brew.sh` | Installs brew packages and casks |
| `install/node.sh` | Installs nvm + Node.js |
| `install/python.sh` | Installs pyenv + Python |
| `install/gcloud.sh` | Installs Google Cloud SDK |
| `install/ssh.sh` | Generates SSH keys for each git account |
| `generate/zshrc.sh` | Generates `config/.zshrc` |
| `generate/gitconfig.sh` | Generates `config/.gitconfig` + `config/.gitignore_global` |
| `generate/ssh_config.sh` | Generates `config/.ssh/config` |
| `config/` | Auto-generated — **do not edit manually** |
