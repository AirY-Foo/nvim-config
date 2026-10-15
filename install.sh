#!/usr/bin/env bash
set -euo pipefail
repo="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
target="${XDG_CONFIG_HOME:-$HOME/.config}/nvim"
install_deps=0
skip_plugins=0
skip_servers=0
while (($#)); do
  case "$1" in
    --target) target="$2"; shift 2 ;;
    --install-deps) install_deps=1; shift ;;
    --skip-plugins) skip_plugins=1; shift ;;
    --skip-servers) skip_servers=1; shift ;;
    *) echo "Unknown argument: $1" >&2; exit 2 ;;
  esac
done
if ((install_deps)); then
  if ! command -v apt-get >/dev/null; then
    echo '--install-deps supports Debian/Ubuntu. On other systems install Neovim >=0.11.2, git, curl, rg, fd, a C compiler, Node.js and unzip first.' >&2
    exit 1
  fi
  elevate=(); if ((EUID != 0)); then elevate=(sudo); fi
  "${elevate[@]}" apt-get update
  "${elevate[@]}" apt-get install -y git curl ca-certificates tar gzip ripgrep fd-find build-essential nodejs npm unzip python3-venv
  if ! command -v nvim >/dev/null || ! nvim --clean --headless '+lua if vim.fn.has("nvim-0.11.2") == 0 then vim.cmd("cquit 1") end' +qa >/dev/null 2>&1; then
    case "$(uname -m)" in x86_64) arch=x86_64 ;; aarch64|arm64) arch=arm64 ;; *) echo 'Unsupported Neovim binary architecture' >&2; exit 1 ;; esac
    stage="$(mktemp -d)"
    curl -fL --retry 3 "https://github.com/neovim/neovim/releases/latest/download/nvim-linux-${arch}.tar.gz" -o "$stage/nvim.tar.gz"
    tar -xzf "$stage/nvim.tar.gz" -C "$stage"
    nvim_dir="$HOME/.local/opt/nvim-$(date +%Y%m%d%H%M%S)-$$"
    mkdir -p "$HOME/.local/opt" "$HOME/.local/bin"
    mv -- "$stage/nvim-linux-${arch}" "$nvim_dir"
    ln -sfn "$nvim_dir/bin/nvim" "$HOME/.local/bin/nvim"
    export PATH="$HOME/.local/bin:$PATH"
    echo 'Add export PATH="$HOME/.local/bin:$PATH" to your shell startup file if needed.'
  fi
fi
if ((!skip_plugins)); then
  command -v git >/dev/null
  command -v nvim >/dev/null
  nvim --clean --headless '+lua if vim.fn.has("nvim-0.11.2") == 0 then vim.cmd("cquit 1") end' +qa
fi
mkdir -p -- "$(dirname -- "$target")"
parent="$(cd -- "$(dirname -- "$target")" && pwd -P)"
target="$parent/$(basename -- "$target")"
case "$target" in /|"$HOME"|"$repo"|"$repo"/*) echo "Unsafe target: $target" >&2; exit 1 ;; esac
if [[ "$repo" == "$target/"* || -L "$target" ]]; then echo "Unsafe target: $target" >&2; exit 1; fi
backup=''
if [[ -e "$target" ]]; then
  backup="$target.backup-$(date +%Y%m%d-%H%M%S)-$$"
  mv -- "$target" "$backup"
  echo "Backup: $backup"
fi
mkdir -p -- "$target"
for name in init.lua lazy-lock.json lazyvim.json stylua.toml lua; do cp -R -- "$repo/$name" "$target/"; done
if [[ ! -f "$repo/lua/config/local.lua" && -n "$backup" && -f "$backup/lua/config/local.lua" ]]; then
  cp -- "$backup/lua/config/local.lua" "$target/lua/config/local.lua"
fi
if ((!skip_plugins)); then
  export XDG_CONFIG_HOME="$parent"
  export NVIM_APPNAME="$(basename -- "$target")"
  nvim --headless -i NONE -n '+lua require("config.bootstrap").plugins()' +qa
  if ((!skip_servers)); then nvim --headless -i NONE -n '+lua require("config.bootstrap").main()' +qa; fi
fi
echo "Installed: $target"
echo 'Run :checkhealth. Optional Docker/Codex settings: lua/config/local.example.lua.'
