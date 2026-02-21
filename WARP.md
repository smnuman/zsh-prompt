# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Repository Overview

This is the **Numan Zsh Prompt** - a modular, high-performance Zsh prompt system providing rich Git integration, OS detection, and user context awareness. It's designed as a stand-alone module that integrates with the broader NOMAD dotfiles environment.

## Architecture

The prompt system consists of three core components:

### Core Files
- `prompt-init.zsh` - Main prompt assembly and precmd hook. Orchestrates all segments and manages dynamic layout based on `PROMPT_LAYOUT` configuration.
- `prompt-utils.zsh` - Foundation layer providing OS detection (macOS 󱄅, Ubuntu 󰕈, Linux 󰌽, Windows 󰍲), root vs regular user differentiation, color scheme management, and Powerline-style separator elements.
- `prompt-git-status.zsh` - Git repository integration handling branch names, working tree status (✓ clean, ✗ dirty, ✨ new repo), upstream tracking (↑ ahead, ↓ behind, ⎋ no upstream), and special Git states (🔀 merge, ⟳ rebase, 🍒 cherry-pick, ↩ revert).
- `prompt-defaults` - Default configuration template (not modified directly).
- `prompt.rc` - User-editable runtime configuration, intended to be symlinked to `~/.config/.promptrc`.

### Prompt Segment Structure
```
[OS] [TIME] [USER] [VENV] [NODE] [PATH] [GIT] [HISTORY] $
```

Segments are dynamically assembled based on `PROMPT_LAYOUT` array. The highlighted segment (typically `path` or `user` for root) uses different colors and thick separators, while non-highlighted segments use thin separators.

### Key Design Principles
- **Performance First**: All Git operations are conditional and error-suppressed. User ID caching (`__last_uid`) prevents unnecessary re-initialization.
- **Dynamic Highlighting**: One segment can be visually emphasized using thick Powerline separators. Root user segments are automatically highlighted when `PROMPT_HL_ROOT_USER=1`.
- **Root User Safety**: When `EUID==0`, colors change to red/cyan warning scheme, prompt changes from `$` to `#`, and `[ROOT]` tag appears in RPROMPT.
- **Separator Logic**: Complex prefix/suffix logic in `prompt-init.zsh` ensures proper spacing and separator placement between highlighted and non-highlighted segments.

## Common Development Commands

### Testing and Validation
```bash
# Test prompt rendering performance
time (for i in {1..10}; do prompt-setup; done)

# Force prompt refresh after configuration changes
unset __last_uid
source ~/.zshrc

# Test in different Git states
git checkout -b test-branch      # New branch
echo "test" > file.txt          # Create dirty state
git add file.txt                # Staged changes

# Verify all functions loaded
type prompt-setup git_prompt_segment history_mode_icon
```

### Development Workflow
```bash
# Edit user configuration
vim ~/.config/zsh/prompt/prompt.rc

# Edit core prompt logic
vim ~/.config/zsh/prompt/prompt-init.zsh

# Test changes immediately (no restart needed)
source ~/.config/zsh/prompt/prompt-init.zsh

# Check Git integration
cd /path/to/git/repo && prompt-setup
```

### Installation Commands
```bash
# Standalone installation
cd ~/.config/zsh
git clone --depth=1 git@github.com:smnuman/prompt.git

# Source in .zshrc (choose one method)
source ~/.config/zsh/prompt/prompt-init.zsh
# OR via modular loader
zsh_add_file "$ZDOTDIR/prompt/prompt-init.zsh"
```

### Debugging
```bash
# Enable debug mode (if implemented)
export ZSH_PROMPT_DEBUG=true

# Check variable values
echo $PROMPT_LAYOUT
echo $PROMPT_HIGHLIGHT
echo $EUID

# Verify Git commands work
git rev-parse --is-inside-work-tree
git symbolic-ref --short -q HEAD
```

## Configuration System

### Two-Tier Configuration
1. **prompt-defaults** - Base defaults, should not be edited
2. **prompt.rc** - User overrides, typically symlinked to `~/.config/.promptrc`

### Key Configuration Variables

**Layout Control:**
- `PROMPT_LAYOUT=(time user path git)` - Order of segments (valid: time, user, node, venv, path, git, none)
- `PROMPT_HIGHLIGHT=path` - Which segment to highlight (path, git, time, user, venv, none)
- `PROMPT_HL_ROOT_USER=1` - Auto-highlight user segment when root
- `PROMPT_PATH_MODE="smart"` - Path display mode: full, short, smart, smart:git

**Segment Toggles:**
- `PROMPT_SHOW_OS_ICON=1` - Display OS icon
- `PROMPT_SHOW_TIME=1` - Display time segment
- `PROMPT_SHOW_USER=1` - Display username
- `PROMPT_SHOW_VENV=1` - Display Python virtual environment
- `PROMPT_SHOW_NODE=1` - Display Node.js version
- `PROMPT_SHOW_PATH=1` - Display current path
- `PROMPT_SHOW_GIT=1` - Display Git information
- `PROMPT_SHOW_HISTORY_MODE=1` - Display history mode icon (🌎 shared, 🔏 private)

**Git Remote Configuration:**
- `SHOW_REMOTE=1` - Show remote name in Git segment
- `PRE_REMOTE=1` - Show remote before (1) or after (0) branch/status

**Color Customization:**
- `PROMPT_HIGHLIGHT_COLOR="cyan"` - Background color for highlighted segment
- `PROMPT_HIGHLIGHT_BODY="cyan"` / `PROMPT_HIGHLIGHT_TEXT="blue"` - Highlighted segment colors
- `PROMPT_GENERAL_BODY="15"` / `PROMPT_GENERAL_TEXT="241"` - Normal segment colors
- `PROMPT_GENERAL_ROOT_BODY="red"` / `PROMPT_GENERAL_ROOT_TEXT="15"` - Root user colors

### Color Scheme System
Regular user: Time (light gray bg, dark text) → Path (cyan bg, blue text) → Yellow `$`
Root user: Time (cyan bg, white text) → Path (red bg, white text) → Red `#` + `[ROOT]` tag

## Important Implementation Notes

### Separator Logic in prompt-init.zsh
The most complex part of the codebase is the prefix/suffix calculation for each segment (lines 85-164). This handles:
- Thin separators (`›` U+E0B1) between normal segments
- Thick separators (`` U+E0B0) around highlighted segments
- Special spacing rules when transitioning between highlighted/non-highlighted segments
- Root user segment highlighting interaction with main highlighted segment

When modifying segment rendering, test with multiple layouts:
```bash
PROMPT_LAYOUT=(time user path git)    # user before path
PROMPT_LAYOUT=(time path user git)    # user after path
PROMPT_LAYOUT=(time git path)         # no user segment
```

### Git Status Performance
`git_prompt_segment()` in `prompt-git-status.zsh` is optimized to:
1. Check if inside Git repo once: `git rev-parse --is-inside-work-tree`
2. Get branch name: `git symbolic-ref --short -q HEAD`
3. Count dirty files: `git status --porcelain | wc -l`
4. Get upstream counts: `git rev-list --left-right --count "@{u}...HEAD"`

All operations redirect stderr to `/dev/null` to suppress errors outside repos.

### User ID Change Detection
`prompt-utils.zsh` uses `__last_uid` to detect when `su` or `sudo -i` changes the user. When detected, it re-initializes icons and colors. This mechanism ensures root user gets proper red warning colors.

### Dynamic Path Display
`__prompt_path()` function in `prompt-utils.zsh` implements smart path truncation:
- Root user always sees full path (`%~`)
- Regular users get mode-dependent truncation (full, short, smart)
- Smart mode shows more context in Git repos vs non-repos

## Customization Patterns

### Adding Custom Segments
To add a new segment (e.g., Python version):

1. Define the segment in `prompt-init.zsh`:
```bash
(( PROMPT_SHOW_PYTHON )) && [[ -n ${PYTHON_INFO} ]] \
    && PYTHON_ELEMENT="${PYTHON_INFO}" || PYTHON_ELEMENT=""
```

2. Add to dynamic elements in `prompt-utils.zsh`:
```bash
PYTHON_INFO="$(command -v python3 >/dev/null 2>&1 && python3 --version | cut -d' ' -f2)"
```

3. Add `python` to valid segment types in layout loop (line 42)
4. Update `prompt-defaults` with `PROMPT_SHOW_PYTHON=1`

### Modifying Separator Appearance
Separators defined in `prompt-utils.zsh` `set_elements()`:
- `_VS_` - Thin separator between normal segments
- `PRE_HIGHLIGHT` / `POST_HIGHLIGHT` - Thick separators around highlighted segment
- `ROOT_SEPARATOR` - Separator for root user segments

Change separator characters by modifying `thin_element` and `thick_element` calls.

### Custom Git Remote Icons
Icons set in `prompt-git-status.zsh` and `prompt-utils.zsh`:
```bash
ICON_GITHUB="󰊤"  # Nerd Font GitHub icon
ICON_GITLAB="󰮠"  # Nerd Font GitLab icon
```

Override in `prompt.rc` or set `CUSTOM_OS_ICON` for OS icon.

## File Sourcing Order

Correct loading sequence is critical:
1. Source `prompt-defaults` (base configuration)
2. Source `prompt.rc` (user overrides)
3. Source `prompt-utils.zsh` (must come before prompt-init)
4. Source `prompt-git-status.zsh` (must come before prompt-init)
5. Source `prompt-init.zsh` (registers precmd hook)

The `prompt-init.zsh` file uses `add-zsh-hook precmd prompt-setup` to run before each prompt display.

## Requirements

- **Zsh 5.8+** - Required for prompt expansion features
- **Git 2.30+** - For Git status integration
- **Nerd Font** - For proper icon display (OS icons, Git symbols)
- **256-color terminal** - For full color scheme support

Optional: tmux, Python venv, Node.js (for segment display)

## Testing Different Scenarios

When making changes, test across:
- Root vs regular user (`sudo -i`)
- Inside vs outside Git repositories
- Different Git states (clean, dirty, merge, rebase, detached HEAD)
- Different PROMPT_LAYOUT configurations
- Different terminal widths
- With/without virtual environments active
- Different history modes (shared/private)

## Related Documentation

- `CLAUDE.md` - Comprehensive development guide (very similar content)
- `PROMPT_IMPLEMENTATION_GUIDE.md` - Detailed implementation walkthrough
- `README.md` - User-facing installation and usage instructions
- `docs/PROMPT_INIT_ANALYSIS.md` - Analysis of prompt-init.zsh complexity
