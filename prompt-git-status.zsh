#!/usr/bin/env zsh
# ~/.config/zsh/prompt/git-status.zsh

# export PRE_REMOTE=0

function git_prompt_segment() {
  local BRANCH_NAME GIT_STATUS ARROWS

  if git rev-parse --is-inside-work-tree &>/dev/null; then
    # Branch name (handle detached)
    BRANCH_NAME=$(git symbolic-ref --short -q HEAD 2>/dev/null || echo "HEAD")
    BRANCH_NAME=$([[ "$BRANCH_NAME" == "HEAD" ]] && echo "%F{magenta} 🪂 DETACHED%f " || echo "%F{yellow} ${ICON_BRANCH} %F{cyan}${BRANCH_NAME}%f%f")

    # Repo state: dirty or clean
    if ! git rev-parse --verify HEAD >/dev/null 2>&1; then
      GIT_STATUS=" %F{blue}✨%f "   # New repo
    else
      local DIRTY_COUNT=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
      GIT_STATUS=$([[ "$DIRTY_COUNT" -gt 0 ]] && echo " %F{red}✗%f " || echo " %F{green}✓%f ")
    fi

    # Upstream/Downstream arrows
    ARROWS=""
    if git rev-parse --symbolic-full-name --verify -q "@{u}" >/dev/null 2>&1; then
      read BEHIND AHEAD <<< "$(git rev-list --left-right --count "@{u}...HEAD" 2>/dev/null || echo "0 0")"
      [[ "$AHEAD" -gt 0 ]] && ARROWS+=" %F{red}↑$AHEAD%f "
      [[ "$BEHIND" -gt 0 ]] && ARROWS+=" %F{yellow}↓$BEHIND%f "
    else
      ARROWS+=" %F{244}⎋%f "  # No upstream
    fi

    # Merge/rebase states
    if [[ -f "$(git rev-parse --git-dir)/MERGE_HEAD" ]]; then
        # ARROWS+=" %F{208}🔀%f "
        ARROWS+=" %F{208}$'\uF419'%f "
    elif [[ -d "$(git rev-parse --git-dir)/rebase-apply" || -d "$(git rev-parse --git-dir)/rebase-merge" ]]; then
        ARROWS+=" %F{202}⟳%f "
    elif [[ -f "$(git rev-parse --git-dir)/CHERRY_PICK_HEAD" ]]; then
        ARROWS+=" %F{171}🍒%f "
    elif [[ -f "$(git rev-parse --git-dir)/REVERT_HEAD" ]]; then
        ARROWS+=" %F{magenta}↩%f "
    fi

    : ${SHOW_REMOTE:=1}
    # local REMOTES=${SHOW_REMOTE:+$(git_remote_segment)}
    local REMOTES=""
    (( $SHOW_REMOTE )) && REMOTES=$(git_remote_segment)

    # echo "%K{15}$(set-remote ${BRANCH_NAME}${GIT_STATUS}${ARROWS} ${REMOTES})${_VS_GIT_}%k"
    echo "%K{15}$(set-remote ${BRANCH_NAME}${GIT_STATUS}${ARROWS} ${REMOTES})%k"

  else
    echo "%K{15} GIT:NaR ${_VS_GIT_}%k"
  fi
}

function git_remote_segment() {
  local github="" gitlab="" spc=" "

  if git rev-parse --is-inside-work-tree &>/dev/null; then
    while read -r name url _; do
      case "$url" in
        *github.com*) github="$name" ;;
        *gitlab.com*) gitlab="$name" ;;
      esac
    done < <(git remote -v | awk '{print $1, $2, $3}' | uniq)

    local segment=""
    [[ -n $github ]] && segment+="${spc}%F{blue}GH:$github%f"
    [[ -n $gitlab ]] && segment+="${spc}%F{magenta}GL:$gitlab%f"
    # echo "%K{15}$segment%k"
    # echo "$segment"
    # echo "$(set-remote ${_VS_} $segment)"
    echo "$(set-remote ${_VS_GIT_} $segment)"
  fi
}

function set-remote() {
    local A B
    (( $3 )) && A="$2" B="$1" || A="$1" B="$2"      # swapping arguments based on PRE_REMOTE(here $3), if it is passed

    # If A and B both are empty → return nothing
    [[ -z "$A" && -z "$B" ]] && { print -r -- ""; return; }
    [[ -z "$A" ]] && { print -r -- ""; return; }
    [[ -z "$B" ]] && { print -r -- "${A}"; return; }

    : ${PRE_REMOTE:=}   # default to PRE_REMOTE=1 (i.e., remote before branch/status)
    (( PRE_REMOTE )) && print -r -- "${B}${A}" || print -r -- "${A}${B}"
}
