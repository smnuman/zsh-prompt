# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is the **Numan Zsh Prompt** - a modular, high-performance Zsh prompt system that provides rich Git integration, OS detection, and user context awareness. It's designed as a stand-alone module that integrates seamlessly with the broader NOMAD dotfiles environment.

## Architecture

The prompt system uses a modular, configuration-driven design with dynamic segment assembly:

### Core Files Structure
```
prompt/
├── prompt-defaults       # Base configuration (DO NOT edit directly)
├── prompt.rc             # User overrides (symlink to ~/.config/.promptrc)
├── prompt-init.zsh       # Main prompt assembly, segment rendering, precmd hook
├── prompt-utils.zsh      # Styling functions, OS detection, color schemes
├── prompt-git-status.zsh # Git repository status integration
├── prompt-git-zshvcs.zsh # Alternative vcs_info implementation (experimental)
└── CLAUDE.md             # This file
```

### Configuration System

**Two-tier configuration hierarchy**:
1. **`prompt-defaults`** - Base defaults, defines all available options
2. **`prompt.rc`** - User overrides, typically symlinked to `~/.config/.promptrc`

Source order: `prompt-defaults` → `prompt.rc` → `prompt-utils.zsh` → `prompt-git-status.zsh` → `prompt-init.zsh`

### Prompt Segment Structure

Dynamic assembly based on `PROMPT_LAYOUT` array:
```
[OS] [TIME] [USER] [VENV] [NODE] [PATH] [GIT] [HISTORY] $
```

- Segments rendered only if enabled via `PROMPT_SHOW_*` toggles
- One segment can be highlighted (thick separators) via `PROMPT_HIGHLIGHT`
- Root user automatically highlights `user` segment if `PROMPT_HL_ROOT_USER=1`

### Component Responsibilities

**`prompt-defaults` / `prompt.rc`** - Configuration:
- `PROMPT_LAYOUT=(time path git)` - Segment order and presence
- `PROMPT_HIGHLIGHT=path` - Which segment to visually emphasize
- `PROMPT_SHOW_*` toggles for each segment type
- Color schemes, icons, Git remote display options

**`prompt-utils.zsh`** - Foundation layer:
- OS detection with Nerd Font icons (macOS 󱄅, Ubuntu 󰕈, Linux 󰌽, Windows 󰍲)
- Root vs regular user differentiation with `__last_uid` caching
- Color scheme management (cyan/blue for users, red/cyan for root)
- History mode detection (🌎 shared, 🔏 private)
- Separator element generation (thin `›` vs thick ``)
- Dynamic path truncation modes (full, short, smart, smart:git)

**`prompt-git-status.zsh`** - Git integration:
- Branch name display with detached HEAD detection (🪂 DETACHED)
- Working tree status (✓ clean, ✗ dirty, ✨ new repo)
- Upstream tracking (↑ ahead, ↓ behind, ⎋ no upstream)
- Remote name display with GitHub/GitLab icons
- Special Git states (🔀 merge, ⟳ rebase, 🍒 cherry-pick, ↩ revert)

**`prompt-init.zsh`** - Assembly and rendering:
- Dynamically assembles segments based on `PROMPT_LAYOUT` array
- Complex prefix/suffix logic for highlighted vs non-highlighted segments (lines 85-175)
- Manages transitions between normal/highlighted/root segments
- Registers `prompt-setup()` via `add-zsh-hook precmd`
- Sets PROMPT and RPROMPT

## Common Development Commands

### Testing and Debugging
```bash
# Test prompt performance
time (for i in {1..10}; do prompt-setup; done)

# Force prompt refresh (after configuration or user changes)
unset __last_uid && source ~/.zshrc

# Test different user contexts
sudo -i                 # Test root user prompt (red colors, # symbol)
exit                    # Return to normal user

# Test different Git states
git checkout -b test-branch              # New branch
echo "test" > file.txt && git add .      # Staged changes
echo "more" >> file.txt                  # Dirty state (staged + unstaged)
git commit -m "test"                     # Clean state
git push -u origin test-branch           # With upstream tracking

# Test segment rendering
type prompt-setup git_prompt_segment history_mode_icon

# Test different layouts quickly (modify prompt.rc)
PROMPT_LAYOUT=(time path git) PROMPT_HIGHLIGHT=git && unset __last_uid && source ~/.zshrc

# Check configuration variables
echo $PROMPT_LAYOUT
echo $PROMPT_HIGHLIGHT
echo $EUID
```

### Installation Commands
```bash
# Standalone installation
cd ~/.config/zsh
git clone --depth=1 git@github.com:smnuman/prompt.git

# Source in .zshrc
source ~/.config/zsh/prompt/prompt-init.zsh

# Or via modular loader (if using zsh_add_file function)
zsh_add_file "$ZDOTDIR/prompt/prompt-init.zsh"
```

### Integration Commands
```bash
# Check if prompt functions are loaded
type prompt-setup
type git_prompt_segment
type history_mode_icon

# Verify required dependencies
git --version          # Required for Git status
echo $ZDOTDIR         # Should point to ~/.config/zsh
fc -l | head -1       # Check history functionality
```

## Configuration System

### Key Configuration Variables

**Layout Control:**
- `PROMPT_LAYOUT=(time user path git)` - Segment order (valid: time, user, node, venv, path, git, none)
- `PROMPT_HIGHLIGHT=path` - Segment to highlight with thick separators
- `PROMPT_HL_ROOT_USER=1` - Auto-highlight user segment when EUID=0
- `PROMPT_PATH_MODE="smart:git"` - Path display: full, short, smart, smart:git

**Segment Toggles:**
- `PROMPT_SHOW_OS_ICON`, `PROMPT_SHOW_TIME`, `PROMPT_SHOW_USER`
- `PROMPT_SHOW_VENV`, `PROMPT_SHOW_NODE`, `PROMPT_SHOW_PATH`
- `PROMPT_SHOW_GIT`, `PROMPT_SHOW_HISTORY_MODE`

**Git Configuration:**
- `SHOW_REMOTE=1` - Display remote name in Git segment
- `PRE_REMOTE=1` - Show remote before (1) or after (0) branch/status

**Testing Different Layouts:**
```bash
# Edit prompt.rc to test different configurations
PROMPT_LAYOUT=(time user path git)    # Standard layout
PROMPT_LAYOUT=(time path git)         # No user segment
PROMPT_LAYOUT=(time git path)         # Git before path
PROMPT_HIGHLIGHT=git                   # Highlight Git instead of path

# Reload to see changes
unset __last_uid && source ~/.zshrc
```

## Key Implementation Details

### Separator Logic (Most Complex Part)

The `prompt-init.zsh` file (lines 85-175) implements intricate prefix/suffix logic for each segment:

- **Thin separators** (`›` U+E0B1): Between normal segments
- **Thick separators** (`` U+E0B0): Around highlighted segments
- **Transition rules**: Special handling when normal segments meet highlighted/root segments
- **Edge cases**: First segment, last segment, OS icon presence

When modifying segment rendering, test with multiple configurations:
```bash
PROMPT_LAYOUT=(time user path git) PROMPT_HIGHLIGHT=path    # user before path
PROMPT_LAYOUT=(time path user git) PROMPT_HIGHLIGHT=user    # user after path
PROMPT_LAYOUT=(time path git) PROMPT_HIGHLIGHT=path         # no user segment
```

**Critical**: Root user segments have their own highlighting that interacts with `PROMPT_HIGHLIGHT`. The logic handles cases where both exist.

### Performance Optimizations
- **Conditional Git operations**: Only runs Git commands inside repositories
- **User ID caching**: Uses `__last_uid` variable to detect `su`/`sudo -i` changes
- **Minimal Git queries**: Single `git status --porcelain` call for dirty check
- **Error suppression**: All Git commands redirect stderr to `/dev/null`
- **Hook efficiency**: Uses `add-zsh-hook precmd` for automatic updates
- **Dynamic elements**: Node/venv info computed once per prompt, not per segment

### Color System
The prompt uses different color schemes based on user privilege level:

**Regular User**:
- Time: Light gray background (`%K{15}`), dark gray text (`%F{241}`)
- Path: Cyan background (`%K{cyan}`), blue text (`%F{blue}`)
- Prompt symbol: Yellow `$` (`%F{yellow}`)

**Root User**:
- Time: Cyan background (`%K{cyan}`), white text (`%F{15}`)
- Path: Red background (`%K{red}`), white text (`%F{15}`)
- Prompt symbol: Red `#` (`%F{red}`)
- Right prompt: Yellow `[ROOT]` tag

### Git Status Logic
The `git_prompt_segment()` function in `prompt-git-status.zsh` handles:
1. Repository detection via `git rev-parse --is-inside-work-tree`
2. Branch name extraction with `git symbolic-ref --short -q HEAD`
3. Working tree status via `git status --porcelain | wc -l`
4. Upstream tracking using `git rev-list --left-right --count "@{u}...HEAD"`
5. Special state detection by checking Git directory files (.git/MERGE_HEAD, .git/rebase-merge, etc.)
6. Remote name display with provider-specific icons:
   - GitHub remote: `󰊤 origin` (orange icon)
   - GitLab remote: `󰮠 origin` (gold icon)
   - Can be positioned before or after branch via `PRE_REMOTE` config

**Alternative**: `prompt-git-zshvcs.zsh` uses Zsh's built-in `vcs_info` system (currently experimental, not active by default)

## Customization Patterns

### Changing Prompt Layout
Edit `prompt.rc` (never edit `prompt-defaults` directly):
```bash
# Reorder segments
PROMPT_LAYOUT=(time user path git)    # Standard
PROMPT_LAYOUT=(time path git)         # Minimal
PROMPT_LAYOUT=(user path git)         # No time

# Change highlighted segment
PROMPT_HIGHLIGHT=git                   # Highlight Git instead of path
PROMPT_HIGHLIGHT=none                  # Disable highlighting

# Path display mode
PROMPT_PATH_MODE="full"                # Show full path
PROMPT_PATH_MODE="short"               # Show only basename
PROMPT_PATH_MODE="smart:git"           # Smart truncation in Git repos
```

### Adding Custom Segments

1. **Define dynamic element** in `prompt-utils.zsh` `set_dynamic_elements()`:
```bash
# Example: Add Python version
PYTHON_INFO="$(command -v python3 >/dev/null 2>&1 && python3 --version | cut -d' ' -f2)"
```

2. **Add segment to `prompt-init.zsh`** `prompt-setup()`:
```bash
(( PROMPT_SHOW_PYTHON )) && [[ -n ${PYTHON_INFO} ]] \
    && PYTHON_ELEMENT="${PYTHON_INFO}" || PYTHON_ELEMENT=""
```

3. **Add to layout options** (line ~52):
```bash
case "$seg" in
    # ... existing cases ...
    python) [[ -n "$PYTHON_ELEMENT" ]] && SEGMENTS+=("python") ;;
esac
```

4. **Add toggle to `prompt-defaults`**:
```bash
PROMPT_SHOW_PYTHON=1
```

### Modifying Colors
Edit `prompt.rc` to override color scheme:
```bash
# Change highlighted segment colors
PROMPT_HIGHLIGHT_COLOR="blue"          # Background for highlighted segment

# Custom color codes (add to prompt-defaults color section)
fg[orange]=208
fg[pink]=205
GIT_COLOR_GH="$fg[orange]"             # GitHub remote color
```

### Custom Icons
Override in `prompt.rc`:
```bash
CUSTOM_OS_ICON=""                     # Custom OS icon
CUSTOM_BRANCH_ICON=""                 # Custom Git branch icon
ICON_GITHUB="󰊤"                        # GitHub remote icon
ICON_GITLAB="󰮠"                        # GitLab remote icon
```

## Dependencies and Requirements

### Required
- **Zsh 5.8+**: Core shell functionality
- **Git 2.30+**: For Git status features
- **Unicode terminal**: For separator characters and icons

### Recommended
- **Nerd Font**: For proper OS and Git icons display
- **256-color terminal**: For full color scheme support
- **tmux compatibility**: Works seamlessly with tmux multiplexer

### Optional Integrations
- **Virtual environments**: Automatically detects and displays Python venv
- **History sharing**: Shows shared (🌎) vs private (🔏) history mode
- **Oh My Zsh/Prezto**: Compatible when their themes are disabled

## File Sourcing Order

**Critical**: Source files in this exact order:
1. `prompt-defaults` (base configuration)
2. `prompt.rc` (user overrides)
3. `prompt-utils.zsh` (must load before prompt-init)
4. `prompt-git-status.zsh` (must load before prompt-init)
5. `prompt-init.zsh` (registers precmd hook)

Breaking this order will cause undefined variable errors or missing functions.

## Testing Scenarios

When making changes, test across these scenarios:

**User Contexts:**
- Regular user vs root user (`sudo -i`)
- User context switching (`su username`)

**Git States:**
- Clean repository
- Dirty (unstaged changes)
- Staged changes
- Ahead/behind/diverged from upstream
- Detached HEAD
- Special states (merge, rebase, cherry-pick, revert)
- No upstream tracking
- GitHub vs GitLab remotes

**Layout Configurations:**
- Different `PROMPT_LAYOUT` orders
- Different `PROMPT_HIGHLIGHT` targets
- With/without OS icon (`PROMPT_SHOW_OS_ICON`)
- Root user with various highlight configs

**Environment:**
- Inside/outside Git repositories
- With/without Python virtual environments
- With/without Node.js in PATH
- Different terminal widths
- Shared vs private history mode

## Important Notes

- **Performance focused**: Optimized for sub-5ms render times
- **Root safety**: Automatically adapts colors and elements for root user (EUID detection)
- **Git repository only**: Git status only appears when inside Git repositories
- **Error handling**: All Git operations include error suppression
- **Dynamic updates**: Automatically refreshes on directory/user changes via precmd hook
- **User context switching**: Detects `su` and `sudo -i` to update colors/icons
- **Modular design**: Each component can be customized independently
- **Configuration isolation**: Never edit `prompt-defaults`, always use `prompt.rc`
- **No external dependencies**: Pure Zsh implementation using only built-in features
- **Alternative Git backend**: `prompt-git-zshvcs.zsh` provides vcs_info-based implementation (currently experimental)
