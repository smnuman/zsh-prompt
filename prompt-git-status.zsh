#!/usr/bin/env zsh
# ~/.config/zsh/prompt/git-status.zsh

# export PRE_REMOTE=0

function git_prompt_segment() {
  local BRANCH_NAME GIT_STATUS ARROWS spc=" "

  if git rev-parse --is-inside-work-tree &>/dev/null; then
    # Branch name (handle detached)
    BRANCH_NAME=$(git symbolic-ref --short -q HEAD 2>/dev/null || echo "HEAD")
    BRANCH_NAME=$([[ "$BRANCH_NAME" == "HEAD" ]] && echo "%F{magenta} ${ICON_DETACHED} DETACHED%f " || echo "%F{yellow}${ICON_BRANCH} %F{cyan}${BRANCH_NAME}%f%f")

    # Repo state: dirty or clean
    if ! git rev-parse --verify HEAD >/dev/null 2>&1; then
      GIT_STATUS="${spc}%F{blue}${ICON_NEW_REPO}%f"   # New repo
    else
      local DIRTY_COUNT=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
      GIT_STATUS=$([[ "$DIRTY_COUNT" -gt 0 ]] && echo "${spc}%F{red}${ICON_DIRTY}%f" || echo "${spc}%F{green}${ICON_CLEAN}%f")
    fi

    # Upstream/Downstream arrows
    ARROWS=""
    if git rev-parse --symbolic-full-name --verify -q "@{u}" >/dev/null 2>&1; then
      read BEHIND AHEAD <<< "$(git rev-list --left-right --count "@{u}...HEAD" 2>/dev/null || echo "0 0")"
      [[ "$AHEAD" -gt 0 ]] && ARROWS+=" %F{red}${ICON_AHEAD}$AHEAD%f"
      [[ "$BEHIND" -gt 0 ]] && ARROWS+=" %F{yellow}${ICON_BEHIND}$BEHIND%f"
      [[ "$AHEAD" -eq 0 && "$BEHIND" -eq 0 ]] && ARROWS+=" %F{green}${ICON_UPSTREAM}%f"     # Found upstream -- in green
    else
      ARROWS+=" %F{red}${ICON_NO_UPSTREAM}%f "  # No upstream -- in red
    #   ARROWS+=" %F{244}${ICON_NO_UPSTREAM}⎋%f "  # No upstream
    fi

    # Merge/rebase states
    if [[ -f "$(git rev-parse --git-dir)/MERGE_HEAD" ]]; then
        # ARROWS+=" %F{208}🔀%f "
        ARROWS+=" %F{208}${ICON_MERGE}%f "
    elif [[ -d "$(git rev-parse --git-dir)/rebase-apply" || -d "$(git rev-parse --git-dir)/rebase-merge" ]]; then
        ARROWS+=" %F{202}${ICON_REBASE}%f "
    elif [[ -f "$(git rev-parse --git-dir)/CHERRY_PICK_HEAD" ]]; then
        ARROWS+=" %F{171}${ICON_CHERRY_PICK}%f "
    elif [[ -f "$(git rev-parse --git-dir)/REVERT_HEAD" ]]; then
        ARROWS+=" %F{magenta}${ICON_REVERT}%f "
    fi

    local LOCALS="${BRANCH_NAME}${GIT_STATUS}${ARROWS}"
    local REMOTES=""

    : ${SHOW_REMOTE:-1}
    (( $SHOW_REMOTE )) && REMOTES=$(git_remote_segment) && echo "$(set-remote ${LOCALS} ${REMOTES})" || echo "${LOCALS}"

  else
    (( $SHOW_REMOTE )) && echo "GIT:NaR" || echo ""
  fi
}

function __git_remote_segment() {
  local github="" gitlab="" segment="" git_icon="" git_remote="" icon=""

  if git rev-parse --is-inside-work-tree &>/dev/null; then
    while read -r name url _; do
      case "$url" in
        *github.com*)   github="$r"
                        icon="$(__git_icon_or_fallback "$ICON_GITHUB" "GH:")"
                        git_icon="%F{$GH_ICON_CLR}${icon}%f"
                        git_remote="%F{$GH_REMOTE_CLR}$github%f"
                        ;;
        *gitlab.com*)   gitlab="$r"
                        icon="$(__git_icon_or_fallback "$ICON_GITLAB" "GL:")"
                        git_icon="%F{$GL_ICON_CLR}${icon}%f"
                        git_remote="%F{$GL_REMOTE_CLR}$gitlab%f"
                        ;;
      esac
    done < <(git remote -v | awk '{print $1, $2, $3}' | uniq)

    segment+="${git_icon} ${git_remote}"

    echo "$(set-remote ${_VS_GIT_} $segment)"
  fi
}

# ========== Helper to set remote before/after branch/status ==========
git_remote_segment() {
  local segment="" remotes=() r url icon
  local active_remote active_clr="$GIT_REMOTE_ACTIVE_CLR" passive_clr="$GIT_REMOTE_PASSIVE_CLR"

  git rev-parse --is-inside-work-tree &>/dev/null || return

  active_remote="$(git config --get branch.$(git branch --show-current).remote 2>/dev/null)"

  # collect relevant remotes (excluding origin)
  while read -r ref; do
    r="${ref%%/*}"
    # [[ "$r" == "origin" ]] && continue
    remotes+=("$r")
  done < <(git branch -r --contains HEAD 2>/dev/null | sed 's/^[ *]*//')

  typeset -U remotes
  (( ${#remotes[@]} == 0 )) && return

  for r in "${remotes[@]}"; do
    url="$(git remote get-url "$r" 2>/dev/null)" || continue

    case "$url" in
    *github.com*)   github="$r"
                    icon="$(__git_icon_or_fallback "$ICON_GITHUB" "GH")"
                    git_icon="%F{$GH_ICON_CLR}${icon}%f"
                    git_remote="%F{$GH_REMOTE_CLR}$github%f"
                    ;;
    *gitlab.com*)   gitlab="$r"
                    icon="$(__git_icon_or_fallback "$ICON_GITLAB" "GL")"
                    git_icon="%F{$GL_ICON_CLR}${icon}%f"
                    git_remote="%F{$GL_REMOTE_CLR}$gitlab%f"
                    ;;
    esac

    if [[ "$r" == "$active_remote" ]]; then
      segment+=" ${git_icon} %F{$active_clr}${r}%f"
    else
      segment+=" ${git_icon} %F{$passive_clr}${r}%f"
    fi
  done

  echo "$(set-remote ${_VS_GIT_} "${segment# }")"
}

# =====================================================================


function set-remote() {
    local A B
    # swapping arguments based on PRE_REMOTE(here $3), if it is passed
    (( $3 )) && A="$2" B="$1" || A="$1" B="$2"
    [[ -z "$B" ]]            && { print -r -- "${A}"; return; }
    # defaults to PRE_REMOTE=1 (i.e., remote before branch/status)
    : ${PRE_REMOTE:=}
    (( PRE_REMOTE )) && print -r -- "${B}${A}" || print -r -- "${A}${B}"
}

__git_icon_or_fallback() {
  local icon="$1" fallback="$2"
  [[ "$icon" == *[[:graph:]]* ]] && print -r -- "$icon" || print -r -- "$fallback:"
}
