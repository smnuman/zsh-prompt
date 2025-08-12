# ~/.config/zsh/prompt/git-status.zsh
function git_prompt_segment() {
  local BRANCH_NAME GIT_STATUS ARROWS

  if git rev-parse --is-inside-work-tree &>/dev/null; then
    # Branch name (handle detached)
    BRANCH_NAME=$(git symbolic-ref --short -q HEAD 2>/dev/null || echo "HEAD")
    BRANCH_NAME=$([[ "$BRANCH_NAME" == "HEAD" ]] && echo "%F{magenta}🪂 DETACHED%f" || echo "%F{yellow}${ICON_BRANCH} %F{cyan}${BRANCH_NAME}%f%f")

    # Repo state: dirty or clean
    if ! git rev-parse --verify HEAD >/dev/null 2>&1; then
      GIT_STATUS=" %F{blue}✨%f"   # New repo
    else
      local DIRTY_COUNT=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
      GIT_STATUS=$([[ "$DIRTY_COUNT" -gt 0 ]] && echo " %F{red}✗%f" || echo " %F{green}✓%f")
    fi

    # Upstream/Downstream arrows
    ARROWS=""
    if git rev-parse --symbolic-full-name --verify -q "@{u}" >/dev/null 2>&1; then
      read BEHIND AHEAD <<< "$(git rev-list --left-right --count "@{u}...HEAD" 2>/dev/null || echo "0 0")"
      [[ "$AHEAD" -gt 0 ]] && ARROWS+=" %F{red}↑$AHEAD%f"
      [[ "$BEHIND" -gt 0 ]] && ARROWS+=" %F{yellow}↓$BEHIND%f"
    else
      ARROWS+=" %F{244}⎋%f"  # No upstream
    fi

    # Merge/rebase states
    if [[ -f "$(git rev-parse --git-dir)/MERGE_HEAD" ]]; then
        # ARROWS+=" %F{208}🔀%f"
        ARROWS+=" %F{208}$'\uF419'%f"
    elif [[ -d "$(git rev-parse --git-dir)/rebase-apply" || -d "$(git rev-parse --git-dir)/rebase-merge" ]]; then
        ARROWS+=" %F{202}⟳%f"
    elif [[ -f "$(git rev-parse --git-dir)/CHERRY_PICK_HEAD" ]]; then
        ARROWS+=" %F{171}🍒%f"
    elif [[ -f "$(git rev-parse --git-dir)/REVERT_HEAD" ]]; then
        ARROWS+=" %F{magenta}↩%f"
    fi

    echo "%K{15} ${BRANCH_NAME}${GIT_STATUS}${ARROWS} ${_VS_GIT_}%k"
    # echo "[ ${BRANCH_NAME}${GIT_STATUS}${ARROWS} ]"
  fi
}
