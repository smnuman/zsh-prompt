# 🌀 Zsh Minimal Git-Aware Prompt

A **minimal yet powerful Git-aware Zsh prompt** system designed for developers who value clarity and performance.

## ✨ Features

* 🎯 **Clear visual cues** - Instant status at a glance
* 🔄 **Upstream sync indicators** - Know when to push/pull
* 🐍 **Virtual environment detection** - Python/Node env display
* 👤 **Root vs User differentiation** - Safety warnings for root sessions
* ⚡ **Fast** - Pure Zsh, no external dependencies
* 🎨 **Customizable** - Modular design for easy tweaking

## 📸 Preview

```
[12:34:56](venv) ~/project [ main ✓ ↑2 ] $
└─ time   └─venv └─path  └─branch└status└sync
```

## 🧱 Directory Structure

```
~/.config/zsh/
├── prompt/
│   ├── prompt-git-status.zsh   # git_prompt_segment function
│   ├── prompt-utils.zsh        # helper functions like thin_element/thick_element and setup functions
│   └── prompt-init.zsh         # prompt-setup function and precmd hook
├── zsh-prompt                 # sourced from .zshrc
└── ...                        # other configs (env.zsh, exports, aliases, etc.)
```

## ⚙️ Setup Instructions

### 1. `prompt-init.zsh`

```zsh
#!/usr/bin/env zsh
# ~/.config/zsh/prompt/prompt-init.zsh

function prompt-setup() {
    local root_tag venv_name full_path git_branch prompt_end prompt_time

    if [[ $(id -u) -eq 0 ]]; then
        root_tag="%K{230}%F{red} %B[ROOT]%b %f%k"
        full_path="%K{red}%F{white} %/ %f%k"
        prompt_end="%F{red}#%f"
    else
        root_tag=""
        full_path="%K{cyan} %F{blue}%~%f %k"
        prompt_end="%F{yellow}\$%f"
    fi

    prompt_time="%K{15}%F{241}[%*]%f%k"
    venv_name=$([[ -n "$VIRTUAL_ENV" ]] && echo "(%F{magenta}$(basename "$VIRTUAL_ENV")%f)" || echo "")
    git_branch=$([[ -f "$ZDOTDIR/prompt/prompt-git-status.zsh" ]] && git_prompt_segment || echo "")

    PROMPT="${prompt_time}${venv_name}${full_path}${git_branch} ${prompt_end} "
    RPROMPT="${root_tag}"
}

autoload -Uz add-zsh-hook
add-zsh-hook precmd prompt-setup
```

### 2. `prompt-git-status.zsh`

```zsh
# ~/.config/zsh/prompt/prompt-git-status.zsh
function git_prompt_segment() {
  local BRANCH_NAME GIT_STATUS ARROWS BEHIND AHEAD

  if git rev-parse --is-inside-work-tree &>/dev/null; then
    BRANCH_NAME=$(git symbolic-ref --short -q HEAD 2>/dev/null || echo "HEAD")
    BRANCH_NAME=$([[ "$BRANCH_NAME" == "HEAD" ]] && echo "%F{magenta}🪂DETACHED%f" || echo "%F{cyan}${BRANCH_NAME}%f")

    if ! git rev-parse --verify HEAD >/dev/null 2>&1; then
      GIT_STATUS=" %F{blue}✨%f"
    else
      local DIRTY_COUNT=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
      GIT_STATUS=$([[ "$DIRTY_COUNT" -gt 0 ]] && echo " %F{red}✗%f" || echo " %F{green}✓%f")
    fi

    ARROWS=""
    if git rev-parse --symbolic-full-name --verify -q "@{u}" >/dev/null 2>&1; then
      read BEHIND AHEAD <<< "$(git rev-list --left-right --count @{u}...HEAD 2>/dev/null || echo "0 0")"
      [[ "$AHEAD" -gt 0 ]] && ARROWS+=" %F{red}↑$AHEAD%f"
      [[ "$BEHIND" -gt 0 ]] && ARROWS+=" %F{yellow}↓$BEHIND%f"
    else
      ARROWS+=" %F{244}⎋%f"
    fi

    [[ -f "$(git rev-parse --git-dir)/MERGE_HEAD" ]] && ARROWS+=" %F{208}🔀%f"
    [[ -d "$(git rev-parse --git-dir)/rebase-apply" || -d "$(git rev-parse --git-dir)/rebase-merge" ]] && ARROWS+=" %F{202}⟳%f"

    echo "[ ${BRANCH_NAME}${GIT_STATUS}${ARROWS} ]"
  fi
}
```

### 3. `prompt-utils.zsh`

`prompt-utils.zsh` provides helper functions for building prompt segments, as well as setup functions for colours and icons used throughout the prompt. It is sourced *before* `prompt-init.zsh` to ensure all helpers and variables are available for prompt construction.

#### Example helper functions:

```zsh
# ~/.config/zsh/prompt/prompt-utils.zsh

# Thin segment element (for minimal separators)
function thin_element() {
  echo "%F{$1}$2%f"
}

# Thick segment element (for blocky segments)
function thick_element() {
  echo "%K{$1}%F{$2} $3 %f%k"
}

# Setup colour variables for use in prompt
function set_prompt_colours() {
  PROMPT_FG_MAIN=cyan
  PROMPT_BG_MAIN=black
  PROMPT_FG_ROOT=red
  PROMPT_BG_ROOT=230
  PROMPT_FG_TIME=241
  PROMPT_BG_TIME=15
}

# Setup icons and segment elements
function set_icons_elements() {
  ICON_CLEAN="✓"
  ICON_DIRTY="✗"
  ICON_AHEAD="↑"
  ICON_BEHIND="↓"
  ICON_NO_UPSTREAM="⎋"
  ICON_MERGE="🔀"
  ICON_REBASE="⟳"
}
```

These helpers are used in other prompt scripts to keep the code DRY and customizable.

### 4. `zsh-prompt`

```zsh
# ~/.config/zsh/zsh-prompt
# Source this to wire up the dynamic prompt

source "$ZDOTDIR/prompt/prompt-git-status.zsh"
source "$ZDOTDIR/prompt/prompt-utils.zsh"
source "$ZDOTDIR/prompt/prompt-init.zsh"
```

---

## ✅ Features

* **Root/User Status:** Easily distinguish root sessions
* **Current Time:** Clock for better terminal awareness
* **Virtualenv name** appears inline
* **Git Branch with sync markers:**

  * ✓ clean / ✗ dirty
  * ↑ ahead / ↓ behind / ⎋ no upstream
  * 🔀 merge / ⟳ rebase
* **Path Highlighting:**

  * `~` for home
  * Full path or `/` for root sessions

---

## 📜 Bonus: Your `.zshrc` setup

Your `.zshrc` leverages a **modular plugin loader** via `zsh_add_file`, `zsh_add_plugin`, etc. That's great for clean config management!

Include `zsh-prompt` like this:

```zsh
zsh_add_file "zsh-prompt"
```

---

## 📌 Notes

* Make sure your `ZDOTDIR` is exported (e.g., in `env.zsh`) before anything else:

  ```zsh
  export ZDOTDIR="$HOME/.config/zsh"
  ```
* Colours assume support for 256-colour terminals (which most modern ones support).
* `git rev-parse` is heavily used to prevent false positives outside a repo.

---

## 🧪 Tested On

* macOS Terminal & iTerm2
* Ubuntu + Zsh
* Oh-My-Zsh optional

---

## 🚀 Installation

### As Part of Parent Zsh Config (Recommended)

This prompt is designed as a **Git submodule** in the parent zsh config:

```bash
# Already included if using parent ~/.config/zsh repo
cd ~/.config/zsh
source prompt/prompt-init.zsh  # Auto-loaded via .zshrc
```

### Standalone Installation

```bash
# Clone to your zsh config directory
git clone https://github.com/smnuman/zsh-prompt ~/.config/zsh/prompt

# Add to ~/.zshrc
source ~/.config/zsh/prompt/prompt-git-status.zsh
source ~/.config/zsh/prompt/prompt-utils.zsh
source ~/.config/zsh/prompt/prompt-init.zsh
```

## 🎨 Customization

### Change Colors

Edit `prompt-utils.zsh`:

```zsh
# Customize in set_prompt_colours()
PROMPT_FG_MAIN=cyan        # Main prompt color
PROMPT_BG_MAIN=black       # Background color
PROMPT_FG_ROOT=red         # Root user color
PROMPT_FG_TIME=241         # Timestamp color
```

### Change Icons

Edit `prompt-utils.zsh`:

```zsh
# Customize in set_icons_elements()
ICON_CLEAN="✓"             # Clean repo
ICON_DIRTY="✗"             # Uncommitted changes
ICON_AHEAD="↑"             # Commits ahead
ICON_BEHIND="↓"            # Commits behind
ICON_NO_UPSTREAM="⎋"       # No tracking branch
```

### Add Custom Segments

Add to `prompt-init.zsh`:

```zsh
# Example: Add hostname for SSH sessions
local hostname_segment=""
[[ -n "$SSH_CONNECTION" ]] && hostname_segment="%F{magenta}[%m]%f "

PROMPT="${hostname_segment}${prompt_time}${full_path}..."
```

## 🔧 Requirements

- **Zsh** ≥ 5.8
- **Git** ≥ 2.0 (for Git status features)
- **256-color terminal** (most modern terminals)

Optional:
- Nerd Fonts for enhanced icons
- True color terminal for better gradients

## 📦 Components

| File | Purpose |
|------|---------|
| `prompt-init.zsh` | Main setup, `precmd` hook, prompt construction |
| `prompt-git-status.zsh` | Git branch, status, sync indicators |
| `prompt-utils.zsh` | Helper functions, color/icon setup |

## 🌍 Platform Support

- ✅ **macOS** - Full support (tested on Ventura+)
- ✅ **Linux** - Full support (Ubuntu, Arch, Fedora)
- ✅ **BSD** - Basic support
- ⚠️ **Windows** - Use WSL2

## 🛠️ Troubleshooting

### Prompt not updating Git status?
```bash
# Check git is in PATH
which git

# Manually trigger prompt update
prompt-setup
```

### Colors not displaying correctly?
```bash
# Test terminal color support
echo -e "\033[38;5;82mGreen\033[0m"

# Check TERM variable
echo $TERM  # Should be xterm-256color or similar
```

### Performance issues?
```bash
# For very large repos, consider async Git checks
# (future enhancement planned)
```

## 💡 Credits

Design and implementation by **[@smnuman](https://github.com/smnuman)** with inspiration from Spaceship, Pure, and Starship prompts.

## 📂 Future Ideas

- [ ] Optional async Git status checks for large repos
- [ ] Show stash count indicator
- [ ] Docker context / Kubernetes context segments
- [ ] Prompt theme switcher (light/dark modes)
- [ ] Right prompt (RPROMPT) customization
- [ ] Exit code indicator
- [ ] Command execution time

## 📝 License

Part of personal dotfiles configuration. Use freely, modify as needed.

---

**Last Updated:** 2025-10-05
**Part of:** [smnuman/config-zsh](https://github.com/smnuman/config-zsh)

Enjoy your micro setup. Make your shell YOUR space! ☕
