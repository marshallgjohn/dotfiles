# WSL + WezTerm + Dotfiles Setup Instructions

Replicate my home setup on a new machine: Fedora under WSL, WezTerm on Windows,
zsh + Oh My Zsh + Starship, tmux, Neovim (LazyVim), and the modern CLI toolkit.
An agent executing this should work top to bottom and verify each step.

> Assumes a Fedora WSL distro (here: `FedoraLinux-44`). If the distro name
> differs, replace `FedoraLinux-44` everywhere (WezTerm config + domain names).
> The dotfiles repo must be reachable from the new machine (public, or a
> provisioned SSH key / token).

## 1. WSL distro prep (inside WSL, as the user)

```bash
# Login shell = zsh (install it first if missing: sudo dnf install -y zsh)
sudo chsh -s /usr/bin/zsh "$USER"   # then log out/in, or: exec zsh -l
```

`/etc/wsl.conf` needs (at minimum):

```ini
[boot]
systemd=true
```

## 2. System packages (inside WSL)

```bash
sudo dnf install -y \
  zsh git neovim tmux gawk \
  fzf zoxide eza bat fd-find git-delta

# lazygit lives in a COPR (not in base Fedora repos):
sudo dnf copr enable -y atim/lazygit && sudo dnf install -y lazygit

# starship is NOT in Fedora repos — use the official installer:
curl -sS https://starship.rs/install.sh | sh -s -- -y
```

What each is for: `fzf` fuzzy finder (Ctrl+R/T), `zoxide` smart `z` jumping,
`eza` modern `ls`, `bat` modern `cat`, `fd-find` modern `find`,
`git-delta` git pager, `lazygit` git UI, `gawk` (required by tmux plugin manager).

## 3. Dotfiles (inside WSL)

```bash
git clone https://github.com/marshallgjohn/dotfiles.git ~/dotfiles
cd ~/dotfiles && ./install.sh
```

`install.sh` does three things (safe to re-run):
1. Clones Oh My Zsh to `~/.oh-my-zsh` (never vendored in the repo) plus
   `zsh-autosuggestions` and `zsh-syntax-highlighting`.
2. Symlinks `~/.zshrc`, `~/.tmux.conf`, `~/.gitconfig`,
   `~/.config/starship.toml`, `~/.config/nvim`, `~/.config/mc`,
   `~/.config/superfile` → `~/dotfiles/...`.

Then set the machine's git identity (do NOT keep the home one):

```bash
# Edit ~/dotfiles/.gitconfig [user] section, or per-repo:
git -C ~/dotfiles config user.name "Your Name"
git -C ~/dotfiles config user.email "you@work.com"
```

Restart the shell: `exec zsh -l`.

## 4. tmux plugins (inside WSL, inside tmux)

```bash
tmux                        # start a session (prefix is Ctrl+A, see §6)
# then press: Ctrl+A, release, Shift+I  (installs tpm plugins)
```

Plugins (declared at the bottom of `~/.tmux.conf`): `tpm`,
`tmux-resurrect` (saves layout + pane contents), `tmux-continuum`
(auto-restores after reboot). `~/.tmux/plugins/` is local state, not in git.

## 5. Neovim (inside WSL)

No action needed — `lazy.nvim` bootstraps all plugins on first `nvim` launch.
`lazy-lock.json` is tracked (reproducible plugin versions);
`lazyvim.json` is ignored (local state).

## 6. WezTerm (on Windows)

Write the file below to `%USERPROFILE%\.config\wezterm\wezterm.lua`
(PowerShell: `$env:USERPROFILE\.config\wezterm\wezterm.lua`).
It auto-reloads on save. Key design points (do not "fix" these):
- WSL domain opens `zsh -l` in `~` (not the Windows cwd).
- Hot-pink cursor `#ff69b4` on Catppuccin Mocha.
- **No `config.leader`** — tmux owns `Ctrl+A`; a WezTerm leader would swallow it.

```lua
-- WezTerm optimal setup for WSL (FedoraLinux-44)
-- Location: %USERPROFILE%\.config\wezterm\wezterm.lua
local wezterm = require("wezterm")
local config = wezterm.config_builder()

-- ── WSL: default to Fedora ──────────────────────────────────────
-- New tabs/windows open directly in WSL, no `wsl.exe` needed.
config.default_domain = "WSL:FedoraLinux-44"

-- Explicit WSL domain (more robust than auto-detect alone).
-- default_prog runs a login shell so ~/.zshrc loads.
config.wsl_domains = {
  {
    name = "WSL:FedoraLinux-44",
    distribution = "FedoraLinux-44",
    default_prog = { "zsh", "-l" },
    -- Start in WSL home (~), not the Windows CWD:
    default_cwd = "~",
  },
}

-- Quick launcher (Ctrl+Shift+P): WSL / PowerShell / CMD
config.launch_menu = {
  {
    label = "Fedora (WSL default)",
    domain = { DomainName = "WSL:FedoraLinux-44" },
  },
  {
    label = "PowerShell",
    args = { "powershell.exe", "-NoLogo" },
    domain = { DomainName = "local" },
  },
  {
    label = "CMD",
    args = { "cmd.exe" },
    domain = { DomainName = "local" },
  },
}

-- ── Appearance ──────────────────────────────────────────────────
config.color_scheme = "Catppuccin Mocha"
-- Pink cursor (hot pink)
config.colors = {
  cursor_bg = "#ff69b4",
  cursor_fg = "#11111b",
  cursor_border = "#ff69b4",
}
config.font = wezterm.font_with_fallback({
  "JetBrainsMono Nerd Font",
  "Cascadia Code",
  "Segoe UI Emoji",
})
config.font_size = 11.0
config.line_height = 1.1
config.cell_width = 1.0

config.initial_cols = 120
config.initial_rows = 30
config.window_padding = { left = 8, right = 8, top = 8, bottom = 8 }
config.window_decorations = "INTEGRATED_BUTTONS|RESIZE"
config.window_background_opacity = 1.0
config.inactive_pane_hsb = { saturation = 0.9, brightness = 0.8 }

-- Tab bar
config.enable_tab_bar = true
config.hide_tab_bar_if_only_one_tab = false
config.use_fancy_tab_bar = true
config.tab_max_width = 32
config.show_tab_index_in_tab_bar = false

-- Scrollback + scrollbar
config.scrollback_lines = 10000
config.enable_scroll_bar = true

-- ── Behavior (WSL-friendly) ─────────────────────────────────────
config.check_for_updates = true
config.automatically_reload_config = true

-- Keep TERM compatible inside WSL/tmux/vim.
-- "xterm-256color" is safest; "wezterm" gives italics/undercurl if
-- your terminfo is installed (`tic -x wezterm.terminfo` on Fedora).
config.term = "xterm-256color"

-- Hyperlinks: Ctrl+Click to open
config.hyperlink_rules = wezterm.default_hyperlink_rules()
config.bypass_mouse_reporting_modifiers = "CTRL"
config.mouse_bindings = {
  {
    event = { Up = { streak = 1, button = "Left" } },
    mods = "CTRL",
    action = wezterm.action.OpenLinkAtMouseCursor,
  },
}

-- ── Keybindings ─────────────────────────────────────────────────
-- Most defaults work; these add launcher + WSL tab + sane splits.
-- NOTE: no WezTerm leader key on purpose — tmux uses Ctrl+A as its
-- prefix, and WezTerm would swallow a leader keypress instead of
-- passing ^A through to the pane.
config.keys = {
  -- Launcher: pick WSL / PowerShell / CMD
  { key = "p", mods = "CTRL|SHIFT", action = wezterm.action.ShowLauncher },
  -- New WSL tab explicitly (even if default ever changes)
  {
    key = "t",
    mods = "CTRL|SHIFT",
    action = wezterm.action.SpawnCommandInNewTab({
      domain = { DomainName = "WSL:FedoraLinux-44" },
    }),
  },
  -- Pane splits (current WSL domain)
  {
    key = "d",
    mods = "CTRL|SHIFT",
    action = wezterm.action.SplitHorizontal({ domain = "CurrentPaneDomain" }),
  },
  {
    key = "e",
    mods = "CTRL|SHIFT",
    action = wezterm.action.SplitVertical({ domain = "CurrentPaneDomain" }),
  },
  -- Pane navigation with Ctrl+Shift+Arrows
  { key = "LeftArrow", mods = "CTRL|SHIFT", action = wezterm.action.ActivatePaneDirection("Left") },
  { key = "RightArrow", mods = "CTRL|SHIFT", action = wezterm.action.ActivatePaneDirection("Right") },
  { key = "UpArrow", mods = "CTRL|SHIFT", action = wezterm.action.ActivatePaneDirection("Up") },
  { key = "DownArrow", mods = "CTRL|SHIFT", action = wezterm.action.ActivatePaneDirection("Down") },
  -- Copy/paste (also Ctrl+Shift+C/V by default)
  { key = "c", mods = "CTRL|SHIFT", action = wezterm.action.CopyTo("Clipboard") },
  { key = "v", mods = "CTRL|SHIFT", action = wezterm.action.PasteFrom("Clipboard") },
  -- Quick select / copy mode for keyboard copy
  { key = " ", mods = "CTRL|SHIFT", action = wezterm.action.QuickSelect },
  { key = "x", mods = "CTRL|SHIFT", action = wezterm.action.ActivateCopyMode },
}

return config
```

## 7. Verify (inside WSL unless noted)

```bash
echo $SHELL            # /usr/bin/zsh
pwd                    # new WezTerm tab opens in ~, not /mnt/c/...
command -v zoxide fzf eza bat fd delta lazygit starship  # all found
bindkey | grep -c fzf  # 4 (Ctrl+R/T, Alt+C wired)
git --no-pager -C ~/dotfiles lg | head -3   # delta-paged log works
tmux show -gv prefix   # C-a
powershell.exe -NoProfile -NonInteractive -Command "Write-Output interop-ok"
```

In WezTerm: `Ctrl+A`, release, lowercase `c` → new tmux window.
`open .` → Windows Explorer; `open https://example.com` → browser.

## 8. Troubleshooting (learned the hard way)

- **New tab opens in `/mnt/c/...` with bash** → WezTerm `default_prog` must be
  `{ "zsh", "-l" }` and `default_cwd = "~"` (§6). Existing panes don't migrate;
  open a new tab.
- **tmux `Ctrl+A c` does nothing** → something (WezTerm leader) is swallowing
  `^A`. There must be no `config.leader`. Correct chord: `Ctrl+A`, release,
  lowercase `c` (not `Ctrl+C`, not `Shift+C`).
- **`exec format error` on any `.exe`** → WSL interop lost its handler. Run the
  `wsl-fix-interop` shell function (re-registers `WSLInterop` in binfmt_misc).
  Full reset alternative: `wsl --shutdown` from Windows (kills all sessions).
- **Starship `Scanning current directory timed out`** → expected on slow `/mnt/c`
  mounts; `~/.config/starship.toml` sets `scan_timeout = 200`. Prefer working
  under `~` (ext4) over `/mnt/c` (9p).
- **`wslview` missing** → intentional; `wslu` isn't packaged on Fedora, the
  dotfiles use `explorer.exe`/`clip.exe`/`powershell.exe` interop directly
  (`open`, `pbcopy`, `pbpaste`, `BROWSER`).
