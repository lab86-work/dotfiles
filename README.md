# dotfiles

Linux development environment managed with [chezmoi](https://www.chezmoi.io/).

A public, self-contained dotfiles repo with no secret-manager dependencies (no 1Password, no Vault). It sets up zsh, oh-my-zsh, Powerlevel10k, and a few common developer tools.

## What is chezmoi?

[chezmoi](https://www.chezmoi.io/) manages your personal configuration files (dotfiles) across multiple machines. It stores your dotfiles in a git repository and applies them to your home directory, with support for templates and machine-specific config.

## Quick Start

### 1. Install chezmoi

```bash
sh -c "$(curl -fsLS get.chezmoi.io)"
```

This installs the `chezmoi` binary to `~/bin` using the official installer.

### 2. Init from this repo

```bash
bin/chezmoi init https://github.com/lab86-work/dotfiles.git
```

This clones the repo to `~/.local/share/chezmoi` over HTTPS.

You will be prompted for (both **optional**, can be left blank):
- **Full name** and **Email** (only needed if you configure git to push changes)

### 3. Apply dotfiles

```bash
chezmoi diff        # preview changes
chezmoi apply       # apply dotfiles to ~/
```

`chezmoi apply` will also run `run_once_install.sh`, which interactively prompts you to install:
- **Core**: base tools, zsh, oh-my-zsh, Powerlevel10k, zsh plugins
- **Developer tools**: GitHub CLI (`gh`), opencode

### 4. Configure the prompt

```bash
p10k configure
```

## Daily usage

| Command | Description |
|---|---|
| `chezmoi add ~/.zshrc` | Start managing a new dotfile |
| `chezmoi edit ~/.zshrc` | Edit a managed dotfile |
| `chezmoi diff` | Preview changes before applying |
| `chezmoi apply` | Apply changes to your home directory |
| `chezmoi update` | Pull latest changes and apply them |
| `chezmoi cd` | Open a shell in the chezmoi source directory |
| `chezmoi status` | Show the state of dotfiles |
| `chezmoi doctor` | Check for common problems |

Chezmoi aliases are also available once dotfiles are applied:

| Alias | Command |
|---|---|
| `cza` | `chezmoi apply` |
| `czd` | `chezmoi diff` |
| `cze` | `chezmoi edit` |
| `czu` | `chezmoi update` |
| `czs` | `chezmoi status` |

## Repository structure

```
dotfiles/
├── README.md                        # This file
├── run_once_install.sh              # Interactive setup script (run once by chezmoi apply)
├── .chezmoi.toml.tmpl               # chezmoi config template (prompts for name, email)
│
├── dot_zshrc                        # → ~/.zshrc (oh-my-zsh, p10k, sources aliases)
├── dot_zsh_aliases                  # → ~/.zsh_aliases (ll, git, docker, chezmoi shortcuts)
├── dot_p10k.zsh                     # → ~/.p10k.zsh (Powerlevel10k prompt config)
│
└── dot_config/
    └── gh/
        └── config.yml               # → ~/.config/gh/config.yml (GitHub CLI settings)
```

### chezmoi file naming conventions

| Source name | Destination |
|---|---|
| `dot_zshrc` | `~/.zshrc` |
| `dot_config/` | `~/.config/` |
| `private_*` prefix | file mode 0600 (not world-readable) |
| `executable_bin_myscript` | `~/bin/myscript` (executable bit set) |
| `*.tmpl` suffix | processed as a Go template before applying |

## Secrets

This repository is **fully public** and contains no secrets. It deliberately has no secret-manager integration (1Password, Vault, etc.). Anything machine-specific or sensitive (API tokens, SSH keys) is expected to be managed outside this repo — e.g. via your editor, `gh auth login`, `opencode auth login`, or local unmanaged files.

If you fork this repo, keep it that way:
- Never commit tokens, keys, or passwords
- Rotate anything that is accidentally pushed (deleting a commit is not enough, it stays in history)

## CI/CD & Security

| Workflow | Trigger | Description |
|---|---|---|
| `ci.yml` | push / PR to `main` | Validates all chezmoi templates with a dry-run |
| `security.yml` | push / PR / daily | Scans for secrets with [Gitleaks](https://gitleaks.io/) |
| `security-trufflehog.yml` | push / PR / daily | Scans full git history for secrets with [TruffleHog](https://trufflesecurity.com/trufflehog) |
| `security-detect-secrets.yml` | push / PR / daily | Scans tracked files against `.secrets.baseline` with [detect-secrets](https://github.com/Yelp/detect-secrets) |
| `codeql.yml` | push / PR / daily | [CodeQL](https://codeql.github.com/) analysis with the `security-extended` query suite (includes secrets queries) |
| Dependabot | weekly | Keeps GitHub Actions versions up to date |

### Secret scanning

Four independent scanners run in CI — **Gitleaks**, **TruffleHog**, **detect-secrets**, and **CodeQL** — plus GitHub's native secret scanning. If any scanner flags a new secret, the build fails.

- `.gitleaks.toml` configures Gitleaks
- `.secrets.baseline` is the detect-secrets baseline. Regenerate it after intentionally adding test fixtures / example values:

  ```bash
  uv tool run detect-secrets scan > .secrets.baseline
  ```

- To enable GitHub's native **secret scanning** + **push protection**: repo **Settings → Code security and analysis → Enable secret scanning and enable push protection**.

## License

[MIT](LICENSE)
