# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is the **Numan Zsh Prompt** - a modular, high-performance Zsh prompt system that provides rich Git integration, OS detection, and user context awareness. It's designed as a stand-alone module that integrates seamlessly with the broader NOMAD dotfiles environment.

## Architecture

The prompt system consists of three core components that work together:

### Core Files Structure
```
prompt/
├── prompt-init.zsh       # Main prompt assembly and precmd hook
├── prompt-utils.zsh      # Styling functions, OS detection, color schemes
├── prompt-git-status.zsh # Git repository status integration
└── CLAUDE.md            # This file
```

### Component Responsibilities

**`prompt-utils.zsh`** - Foundation layer:
- OS detection with Nerd Font icons (macOS 󱄅, Ubuntu 󰕈, Linux 󰌽, Windows 󰍲)
- Root vs regular user differentiation
- Color scheme management (cyan/blue for users, red/cyan for root)
- History mode detection (🌎 shared, 🔏 private)
- Powerline-style separator elements using Unicode chars

**`prompt-git-status.zsh`** - Git integration:
- Branch name display with detached HEAD detection (🪂 DETACHED)
- Working tree status (✓ clean, ✗ dirty, ✨ new repo)
- Upstream tracking (↑ ahead, ↓ behind, ⎋ no upstream)
- Special Git states (🔀 merge, ⟳ rebase, 🍒 cherry-pick, ↩ revert)
- Performance optimized with minimal Git commands

**`prompt-init.zsh`** - Assembly layer:
- Combines all segments using `add-zsh-hook precmd`
- Manages user ID change detection for dynamic updates
- Assembles final prompt: `[OS] [TIME] [VENV] [PATH] [GIT] [HISTORY] $`
- Sets RPROMPT for root user tag

## Common Development Commands

### Testing and Debugging
```bash
# Test prompt performance
time (for i in {1..10}; do prompt-setup; done)

# Enable debug mode
export ZSH_PROMPT_DEBUG=true

# Force prompt refresh (after user changes)
unset __last_uid
source ~/.zshrc

# Test in different Git states
git checkout -b test-branch
echo "test" > file.txt  # Creates dirty state
git add file.txt       # Staged changes
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

## Key Implementation Details

### Performance Optimizations
- **Conditional Git operations**: Only runs Git commands inside repositories
- **User ID caching**: Uses `__last_uid` variable to detect user changes
- **Minimal Git queries**: Single `git status --porcelain` call for dirty check
- **Error suppression**: All Git commands redirect stderr to `/dev/null`
- **Hook efficiency**: Uses `add-zsh-hook precmd` for automatic updates

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
The `git_prompt_segment()` function handles:
1. Repository detection via `git rev-parse --is-inside-work-tree`
2. Branch name extraction with `git symbolic-ref --short -q HEAD`
3. Working tree status via `git status --porcelain | wc -l`
4. Upstream tracking using `git rev-list --left-right --count`
5. Special state detection by checking Git directory files

## Customization Patterns

### Adding Custom Segments
Edit `prompt-init.zsh` function `prompt-setup()`:
```bash
# Example: Add Node.js version
NODE_INFO=""
if command -v node >/dev/null 2>&1; then
    NODE_VERSION=$(node --version 2>/dev/null)
    NODE_INFO=" %F{green}⬢%f %F{white}${NODE_VERSION}%f"
fi

# Include in final prompt
PROMPT="${myOS}${PROMPT_TIME}${NODE_INFO}${VENV_NAME}${FULL_PATH}${GIT_BRANCH}${PROMPT_END} "
```

### Modifying Colors
Edit color definitions in `prompt-utils.zsh` function `set_prompt_colours()`:
```bash
# Change user prompt colors
ROOT_COLOR="%K{blue} %F{white}"      # Blue background for time
ROOT_PATH_COLOR="%K{green} %F{black}" # Green background for path
```

### Custom Git Icons
Modify icon definitions in `prompt-utils.zsh` function `set_icons()`:
```bash
ICON_CLEAN="✅"      # Change clean indicator
ICON_DIRTY="❌"      # Change dirty indicator
ICON_BRANCH="🌿"     # Change branch icon
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

## Important Notes

- **Performance focused**: Optimized for sub-5ms render times
- **Root safety**: Automatically adapts colors and elements for root user
- **Git repository only**: Git status only appears when inside Git repositories
- **Error handling**: All Git operations include error suppression
- **Dynamic updates**: Automatically refreshes on directory/user changes
- **Modular design**: Each component can be customized independently
- **No external dependencies**: Pure Zsh implementation using only built-in features