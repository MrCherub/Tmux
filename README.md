# Tmux
A productivity-focused tmux setup with Catppuccin styling, Nord accents, Vim pane navigation, and CPU/session/uptime status modules.

<img width="1305" height="22" alt="Tmux status line preview" src="https://github.com/user-attachments/assets/e28bf959-3593-4217-bb24-e13f3e77a78a" />

## File Layout
- `tmux/tmux.conf`: Main tmux config.

## Highlights
- Prefix key is `Ctrl+a` (instead of default `Ctrl+b`).
- Vertical split is bound to `prefix + a`.
- Mouse mode is enabled.
- Catppuccin window style is `rounded`.
- Window title text shows `pane_current_command` (for both active/inactive windows).
- Window number bubbles:
  - Inactive windows use a 13-color cycle (Catppuccin palette + Nord accent).
  - Active window bubble uses Nord background `#2e3440`.
  - Active window number text is forced to light `#eceff4` for contrast.
- Status-right modules include application, session, uptime, and Catppuccin CPU.

## Plugins Used
- `tmux-plugins/tpm`
- `tmux-plugins/tmux-sensible`
- `christoomey/vim-tmux-navigator`
- `catppuccin/tmux`
- `tmux-plugins/tmux-cpu`
- `tmux-plugins/tmux-battery`

## Install
1. Clone this repo.
2. Symlink `tmux/tmux.conf` to `~/.tmux.conf` (or copy it).
3. Start tmux and install TPM plugins with `prefix + I`.

## Notes
- Config expects Nerd Font glyph support for icons (CPU icon and separators).
- Plugin init lines are intentionally kept at the bottom of `tmux.conf`.
