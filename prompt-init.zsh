#!/usr/bin/env zsh
# 🌀 Set prompt dynamically at each shell
# Following variable is used in prompt-utils.zsh
__last_uid=""
function prompt-setup {
    PROMPT_TIME="${_VS_}${ROOT_COLOR}%*${COLOR_RESET}"
    VENV_NAME=$([[ -n "$VIRTUAL_ENV" ]] && echo " (%F{magenta}$(basename "$VIRTUAL_ENV")%f )" || echo "")

    FULL_PATH="${LEFT_SEPARATOR}${ROOT_PATH_COLOR}${ROOT_PATH_ELEMENT}${COLOR_RESET}${RIGHT_SEPARATOR}"

    # 🌱 Git segment using 'prompt-git-status.zsh' in ~/.config/zsh/prompt/
    GIT_BRANCH=$([[ -d .git && -f "$ZDOTDIR/prompt/prompt-git-status.zsh" ]] &&  git_prompt_segment || echo "")

    PROMPT_END="%K{15}${ROOT_PROMPT_COLOR}%(!.#.$)${PROMPT_COLOR_RESET} %k${RIGHT_POINTING}"
    PROMPT="${myOS}${PROMPT_TIME}${VENV_NAME}${FULL_PATH}${GIT_BRANCH}${PROMPT_END} "

    RPROMPT="${ROOT_TAG}"
}
add-zsh-hook precmd prompt-setup
