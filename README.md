# dotfiles-bootstrap

A shell script that turns a fresh Linux install into your personalized workstation. Fedora and KDE Plasma get first-class support, but Debian/Ubuntu and Arch are covered too. One command, zero manual steps.

## What it does

- Installs a curated list of packages (KDE desktop apps, CLI utilities, dev tools)
- Deploys your dotfiles from a `dotfiles/` directory into your home directory
- Enables sensible systemd services (firewall, NetworkManager)
- Backs up any existing config files before overwriting them
- Supports a dry-run mode so you can preview every action

## Quick start

```bash
git clone https://github.com/cappy-dev/dotfiles-bootstrap.git
cd dotfiles-bootstrap
chmod +x bootstrap.sh
./bootstrap.sh
```

That runs all three phases: packages, config, and services.

## Options

```bash
./bootstrap.sh --dry-run     # Print what would happen, do nothing
./bootstrap.sh --packages    # Only install packages
./bootstrap.sh --config      # Only deploy dotfiles
./bootstrap.sh --services    # Only enable systemd services
./bootstrap.sh --all         # Everything (default)
./bootstrap.sh --help        # Show usage info
```

## How dotfiles work

Put your config files inside the `dotfiles/` directory. The script mirrors that structure into your home directory.

Example layout:

```
dotfiles-bootstrap/
  bootstrap.sh
  dotfiles/
    .bashrc.custom
    .tmux.conf
    .vimrc
    .config/
      kitty/
        kitty.conf
```

The script copies `dotfiles/.bashrc.custom` to `~/.bashrc.custom`, `dotfiles/.config/kitty/kitty.conf` to `~/.config/kitty/kitty.conf`, and so on. Any file in `dotfiles/` lands at the same relative path under your home directory.

Before overwriting an existing file, the script creates a backup with a timestamp suffix (e.g. `.bashrc.custom.1700000000`).

### Bashrc hook

After deploying configs, the script appends a small hook to your `~/.bashrc` that sources `~/.bashrc.custom` if it exists. This keeps your custom aliases and functions separate from the distro defaults, so system updates never clobber your additions.

## Packages included

The script installs roughly 40 packages per distro, organized into three groups:

**Desktop (KDE Plasma focus):**
Konsole, Dolphin, Kate, Gwenview, Okular, Ark, Spectacle

**CLI utilities:**
git, vim, neovim, tmux, fzf, ripgrep, fd, bat, eza, htop, btop, curl, wget, rsync

**Development:**
gcc/g++, make, cmake, Python 3, Go, Rust

**System:**
firewalld (Fedora) or ufw (Debian/Arch), NetworkManager

On Fedora, the script also enables the RPM Fusion free repository for multimedia codecs.

## dry-run first

If you want to see exactly what the script would do on your machine without changing anything:

```bash
./bootstrap.sh --dry-run
```

Every action prints as a `DRY` line in yellow, and no commands actually execute. This is helpful for reviewing the package list or checking which config files would be deployed.

## Adding your own packages

Open `bootstrap.sh` and find the array for your distro (e.g. `FEDORA_PACKAGES` or `DEBIAN_PACKAGES`). Add or remove package names from the list. The arrays are plain Bash arrays with one package per line for readability.

## Adding your own dotfiles

1. Drop your config file into `dotfiles/` at the correct relative path
2. Run `./bootstrap.sh --config` to deploy it
3. Existing files get backed up automatically

## Why not Ansible/Chef/Salt?

Those tools are great for managing fleets of servers. For setting up a personal laptop, a single shell script you can read in five minutes is hard to beat. No agents, no inventory files, no YAML. Just Bash.

## License

MIT
