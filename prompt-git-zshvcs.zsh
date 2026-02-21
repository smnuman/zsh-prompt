#!/usr/bin/env zsh
# =============================== testing vcs_info ================================
# =============================================
#               vcs_info - Modern Git Prompt
# =============================================

autoload -Uz vcs_info
autoload -Uz add-zsh-hook

# Run vcs_info before each prompt
add-zsh-hook precmd vcs_info

# Only enable git (faster in non-git dirs)
zstyle ':vcs_info:*' enable git

# Check for changes → enables %u and %c
zstyle ':vcs_info:git:*' check-for-changes true

# # Format when everything is clean
# zstyle ':vcs_info:git:*' formats       '%F{075}%b%f%F{red}%u%c%f'

# Change dirty symbol to something else
zstyle ':vcs_info:git:*' stagedstr   '%F{green}+%f'
zstyle ':vcs_info:git:*' unstagedstr '%F{yellow}*%f'

# Optional: show stash count (●3 if 3 stashes)
zstyle ':vcs_info:git*+set-message:git-stash' true

# Optional: show number of commits ahead/behind remote (↑2 or ↓1)
zstyle ':vcs_info:git*+set-message:git-unpushed' true
zstyle ':vcs_info:git*+set-message:git-unpulled' true

# # Show short commit hash too
# zstyle ':vcs_info:git:*' formats '%F{075}%b%f %F{242}[%i]%f%F{red}%u%c%f'
# zstyle ':vcs_info:git*' formats "%s  %r/%S %b (%a) %m%u%c "
zstyle ':vcs_info:git:*' formats "%s  %r/%S %b (%a) %m%u%c "
# Format when in middle of action (rebase, merge, bisect…)
zstyle ':vcs_info:git:*' actionformats '%F{196}%b %F{220}(%a)%f%F{red}%u%c%f'

# =============================================
#               How to use in prompt
# =============================================

# 1. Right prompt (most popular & clean)
# RPROMPT='${vcs_info_msg_0_}'

# 2. Alternative: inside left prompt (after directory)
# PROMPT='%F{blue}%~%f${vcs_info_msg_0_} ❯ '

# 3. Fancy version with SSH host + git info (popular on remote machines)
# RPROMPT='${SSH_TTY:+%F{242}%m%f }${vcs_info_msg_0_}'
# ========================== test ends ==========================
