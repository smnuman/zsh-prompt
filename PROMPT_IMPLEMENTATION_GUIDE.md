# Zsh Prompt Implementation Guide

A comprehensive guide to implementing and using the modular Zsh prompt system that provides rich Git integration, OS detection, and user context awareness.

## Overview

This prompt system is a modular, high-performance Zsh prompt that provides:

- **OS Detection**: Automatically displays OS-specific icons
- **Git Integration**: Rich Git status with branch, state, and sync indicators
- **User Context**: Root/regular user visual differentiation
- **History Mode**: Shows shared/private history state
- **Virtual Environment**: Python virtual environment display
- **Performance Optimized**: Designed for fast shell startup

## Quick Installation

### Prerequisites

1. **Zsh Shell**: Ensure you're using Zsh as your shell
2. **Nerd Font**: Install a Nerd Font for proper icon display (recommended: FiraCode Nerd Font)
3. **Git**: Required for Git status features

```bash
# Check if you have Zsh
echo $SHELL

# Install Nerd Font (macOS with Homebrew)
brew tap homebrew/cask-fonts
brew install font-fira-code-nerd-font
```

### Basic Setup

1. **Create the prompt directory structure**:
```bash
mkdir -p ~/.config/zsh/prompt
```

2. **Copy the prompt files** to `~/.config/zsh/prompt/`:
   - `prompt-init.zsh` - Main prompt initialization
   - `prompt-utils.zsh` - Utilities and styling functions
   - `prompt-git-status.zsh` - Git status integration

3. **Create the prompt loader** at `~/.config/zsh/zsh-prompt`:
```bash
cat > ~/.config/zsh/zsh-prompt << 'EOF'
PROMPT_UTILS="$ZDOTDIR/prompt/prompt-utils.zsh"
PROMPT_INIT="$ZDOTDIR/prompt/prompt-init.zsh"
PROMPT_GIT="$ZDOTDIR/prompt/prompt-git-status.zsh"

if [[ -f $PROMPT_UTILS && -f $PROMPT_INIT && -f $PROMPT_GIT ]]; then
    source $PROMPT_UTILS
    source $PROMPT_GIT
    source $PROMPT_INIT
else
    export PS1="[ %T ] %~ %# "
fi
EOF
```

4. **Load the prompt** in your `.zshrc`:
```bash
# Set ZDOTDIR if not already set
export ZDOTDIR="${ZDOTDIR:-$HOME/.config/zsh}"

# Source the prompt
[[ -f "$ZDOTDIR/zsh-prompt" ]] && source "$ZDOTDIR/zsh-prompt"
```

5. **Reload your shell**:
```bash
source ~/.zshrc
```

## Architecture Deep Dive

### Component Overview

The prompt system consists of three main components:

#### 1. `prompt-utils.zsh` - Core Utilities
**Location**: `~/.config/zsh/prompt/prompt-utils.zsh`

**Purpose**: Provides styling functions, OS detection, and color schemes.

**Key Functions**:
- `history_mode_icon()`: Shows shared (🌎) or private (🔏) history mode
- `thick_element()`: Creates thick separator elements with dual colors
- `thin_element()`: Creates thin elements with single colors
- `set_icons()`: Detects OS and sets appropriate icons
- `set_elements()`: Configures separators and visual elements
- `set_prompt_colours()`: Sets color schemes for root vs regular users

**OS Detection**:
```bash
# Supported OS icons
macOS:     (Apple icon)
Ubuntu:    (Ubuntu icon)
Linux:     (Generic Linux)
Windows:   (Windows icon)
Unknown:   ❓
```

#### 2. `prompt-git-status.zsh` - Git Integration
**Location**: `~/.config/zsh/prompt/prompt-git-status.zsh`

**Purpose**: Provides comprehensive Git repository status information.

**Features**:
- **Branch Display**: Current branch name or "DETACHED HEAD" state
- **Working Tree Status**: Clean (✓) or dirty (✗) indicators
- **Sync Status**: Ahead (↑) and behind (↓) commit counts
- **Special States**: Merge (🔀), rebase (⟳), cherry-pick (🍒), revert (↩)
- **Upstream Status**: Shows if branch has no upstream (⎋)

#### 3. `prompt-init.zsh` - Main Prompt Setup
**Location**: `~/.config/zsh/prompt/prompt-init.zsh`

**Purpose**: Assembles all components into the final prompt display.

**Prompt Segments**:
```
[OS] [TIME] [VENV] [PATH] [GIT] [HISTORY] $
```

### Visual Design

#### Regular User Prompt
```
 [TIME] /current/path  main ✓  🌎$
```

#### Root User Prompt
```
 [TIME] / main ✓  🌎# [ROOT]
```

#### Color Scheme

**Regular User**:
- Time: Light gray background, dark gray text
- Path: Cyan background, blue text
- Git: White background, colored status
- Prompt: Yellow `$`

**Root User**:
- Time: Cyan background, white text
- Path: Red background, white text
- Git: White background, colored status
- Prompt: Red `#`
- Tag: Yellow `[ROOT]` on right

## Advanced Configuration

### Customizing Colors

Edit `prompt-utils.zsh` function `set_prompt_colours()`:

```bash
function set_prompt_colours {
    COLOR_RESET="%f %k"
    PROMPT_COLOR_RESET="%f"
    if [[ $(id -u) -eq 0 ]]; then
        ROOT_COLOR="%K{cyan} %F{15}"        # Root time colors
        ROOT_PATH_COLOR="%K{red} %F{15}"    # Root path colors
        ROOT_PROMPT_COLOR=" %F{red}"        # Root prompt symbol
    else
        ROOT_COLOR="%K{15} %F{241}"         # User time colors
        ROOT_PATH_COLOR="%K{cyan} %F{blue}" # User path colors
        ROOT_PROMPT_COLOR=" %F{yellow}"     # User prompt symbol
    fi
}
```

### Customizing Icons

Edit `prompt-utils.zsh` function `set_icons()`:

```bash
function set_icons {
    # Custom OS icon
    case "$OSTYPE" in
        darwin*)    OS_ICON="🍎" ;;  # Custom Apple emoji
        linux*)     OS_ICON="🐧" ;;  # Penguin for Linux
        *)          OS_ICON="💻" ;;  # Computer for others
    esac

    # Custom Git icons
    ICON_BRANCH="🌿"     # Branch icon
    ICON_CLEAN="✅"      # Clean state
    ICON_DIRTY="❌"      # Dirty state
    # ... more customizations
}
```

### Adding Custom Segments

Create custom segments by editing `prompt-init.zsh`:

```bash
function prompt-setup {
    PROMPT_TIME="${_VS_}${ROOT_COLOR}%*${COLOR_RESET}"

    # Add custom segment
    CUSTOM_SEGMENT=""
    if command -v node >/dev/null 2>&1; then
        NODE_VERSION=$(node --version 2>/dev/null)
        CUSTOM_SEGMENT=" %F{green}⬢%f %F{white}${NODE_VERSION}%f"
    fi

    # Include in final prompt
    PROMPT="${myOS}${PROMPT_TIME}${CUSTOM_SEGMENT}${VENV_NAME}${FULL_PATH}${GIT_BRANCH}${PROMPT_END} "
}
```

## Troubleshooting

### Common Issues

#### 1. Icons Not Displaying
**Problem**: Boxes or question marks instead of icons
**Solution**: Install a Nerd Font and configure your terminal

```bash
# Check current font
echo "Current font should support: "

# Install Nerd Font (macOS)
brew install font-fira-code-nerd-font

# Or download manually from: https://www.nerdfonts.com/
```

#### 2. Git Status Not Showing
**Problem**: Git segment missing in repositories
**Solution**: Check Git installation and file permissions

```bash
# Verify Git is installed
git --version

# Check if in Git repository
git status

# Verify prompt file exists and is executable
ls -la ~/.config/zsh/prompt/prompt-git-status.zsh
```

#### 3. Slow Prompt Performance
**Problem**: Noticeable delay when displaying prompt
**Solution**: Enable performance mode

```bash
# Add to your shell configuration
export ZSH_PERF_MODE=true
```

#### 4. Root Detection Issues
**Problem**: Wrong colors/elements when switching between users
**Solution**: The prompt automatically detects user changes, but you can force refresh:

```bash
# Force prompt refresh
unset __last_uid
source ~/.zshrc
```

### Debug Mode

Enable detailed logging by setting debug variables:

```bash
# Enable debug logging
export ZSH_PROMPT_DEBUG=true

# Check logs
tail -f ~/.config/zsh/logs/prompt_debug.log
```

## Integration with Existing Systems

### Oh My Zsh Integration

If you're using Oh My Zsh, disable theme and use this prompt:

```bash
# In ~/.zshrc
ZSH_THEME=""  # Disable Oh My Zsh theme

# Source this prompt after Oh My Zsh
source $ZSH/oh-my-zsh.sh
[[ -f "$ZDOTDIR/zsh-prompt" ]] && source "$ZDOTDIR/zsh-prompt"
```

### Prezto Integration

For Prezto users:

```bash
# In ~/.zpreztorc
zstyle ':prezto:module:prompt' theme 'off'

# Source this prompt after Prezto
[[ -f "$ZDOTDIR/zsh-prompt" ]] && source "$ZDOTDIR/zsh-prompt"
```

### tmux Integration

The prompt works seamlessly with tmux. For best results:

```bash
# In ~/.tmux.conf
set -g default-terminal "screen-256color"
set -ga terminal-overrides ",*256col*:Tc"
```

## Performance Optimization

### Boot Performance Features

The prompt system includes several performance optimizations:

1. **Conditional Loading**: Only loads Git status in actual repositories
2. **Caching**: User ID changes trigger re-initialization only when needed
3. **Efficient Git Operations**: Minimal Git commands with error suppression
4. **Performance Mode**: Simplified logging when `ZSH_PERF_MODE=true`

### Benchmarking

Test prompt performance:

```bash
# Time prompt generation
time (for i in {1..100}; do prompt-setup; done)

# Profile with zprof
zmodload zsh/zprof
# ... use shell normally ...
zprof
```

## Customization Examples

### Minimal Prompt

For a simpler prompt, create a custom `prompt-init.zsh`:

```bash
function prompt-setup {
    local git_info=$([[ -d .git ]] && git_prompt_segment || echo "")
    PROMPT="%F{blue}%~%f${git_info} %F{yellow}$%f "
    RPROMPT="%F{gray}%T%f"
}
```

### Developer-Focused Prompt

Add development tool versions:

```bash
function dev_info() {
    local info=""
    [[ -f package.json ]] && info+=" %F{green}⬢%f"
    [[ -f Cargo.toml ]] && info+=" %F{red}🦀%f"
    [[ -f go.mod ]] && info+=" %F{cyan}🐹%f"
    echo "$info"
}

# Add to prompt-setup function
DEV_INFO=$(dev_info)
PROMPT="${myOS}${PROMPT_TIME}${DEV_INFO}${VENV_NAME}${FULL_PATH}${GIT_BRANCH}${PROMPT_END} "
```

## Migration Guide

### From Default Zsh

1. Backup current prompt:
```bash
echo "export PS1='$PS1'" > ~/prompt_backup.sh
```

2. Follow installation steps above

3. To revert:
```bash
source ~/prompt_backup.sh
```

### From Powerline/Starship

This prompt provides similar functionality to Powerline and Starship:

| Feature | Powerline | Starship | This Prompt |
|---------|-----------|----------|-------------|
| Git Status | ✓ | ✓ | ✓ |
| OS Detection | ✓ | ✓ | ✓ |
| Fast Loading | ✗ | ✓ | ✓ |
| Zsh Native | ✗ | ✗ | ✓ |
| Root Detection | ✓ | ✓ | ✓ |

## Contributing

To contribute to this prompt system:

1. Test changes across different environments:
   - macOS, Linux, WSL
   - Root and regular users
   - Various Git repository states

2. Maintain performance:
   - Profile with `zprof`
   - Test in large repositories
   - Ensure fast startup

3. Follow the modular design:
   - Keep utilities in `prompt-utils.zsh`
   - Git logic in `prompt-git-status.zsh`
   - Assembly in `prompt-init.zsh`

## License and Credits

This prompt system is designed for the portable dotfiles configuration architecture and integrates with the broader Zsh configuration system described in the main project documentation.

For more information about the complete dotfiles system, see the main `CLAUDE.md` and documentation in the `docs/` directory.