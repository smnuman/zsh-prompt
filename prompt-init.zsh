#!/usr/bin/env zsh
# 🌀 Set prompt dynamically at each shell
# Following variable is used in prompt-utils.zsh
__last_uid=""
function prompt-setup {

    PROMPT_START="${OS_ELEMENT}"

    NONE_ELEMENT="${_VS_}"

    (( PROMPT_SHOW_TIME )) && TIME_ELEMENT="${PRE_TIME}${ROOT_COLOR}${PROMPT_TIME}${COLOR_RESET}" || TIME_ELEMENT=""
    (( PROMPT_SHOW_USER )) && USER_ELEMENT="${PRE_USER}${ROOT_COLOR}${PROMPT_USER:-%n}${COLOR_RESET}" || USER_ELEMENT=""
    (( PROMPT_SHOW_VENV && ${+VIRTUAL_ENV} )) && VENV_ELEMENT="${_VS_}${V_ENVIRON}" || VENV_ELEMENT=""
    (( PROMPT_SHOW_PATH )) && PATH_ELEMENT="${ROOT_PATH_COLOR}${ROOT_PATH_ELEMENT}${COLOR_RESET}" || PATH_ELEMENT=""
    # 🌱 Git segment using 'prompt-git-status.zsh' in ~/.config/zsh/prompt/
    GIT_DETAILS=$([[ -d .git && -f "$ZDOTDIR/prompt/prompt-git-status.zsh" ]] &&  git_prompt_segment || echo "")
    (( PROMPT_SHOW_GIT )) && GIT_ELEMENT="${PRE_GIT}${GIT_DETAILS}" || GIT_ELEMENT=""
    (( PROMPT_SHOW_HISTORY_MODE )) && HIST_ELEMENT="${PRE_HIST}${HIST_ICON}" START_ELEMENT=1 || HIST_ELEMENT=""

    PROMPT_END="%K{15}${HIST_ELEMENT}${ROOT_PROMPT_COLOR}%(!.#.$)${PROMPT_COLOR_RESET} %k${RIGHT_POINTING} "

    local SEGMENTS=()
    local RESULT=()
    local path_index=-1
    local idx=0

    PROMPT_DEFAULT_LAYOUT=(time user venv path git)
    PROMPT_LAYOUT=("${PROMPT_LAYOUT[@]:-${PROMPT_DEFAULT_LAYOUT[@]}}")

    for seg in "${PROMPT_LAYOUT[@]}"; do
        case "$seg" in
            time)  [[ -n "$TIME_ELEMENT" ]] && SEGMENTS+=("time")   ;;
            user)  [[ -n "$USER_ELEMENT" ]] && SEGMENTS+=("user")   ;;
            venv)  [[ -n "$VENV_ELEMENT" ]] && SEGMENTS+=("venv")   ;;
            path)  [[ -n "$PATH_ELEMENT" ]] && SEGMENTS+=("path")   ;;
            git)   [[ -n "$GIT_ELEMENT" ]]  && SEGMENTS+=("git")    ;;
            none)  [[ -n "$GIT_ELEMENT" ]]  && SEGMENTS+=("none")   ;;
        esac
    done

    # Find index of PATH in layout
    for seg in "${SEGMENTS[@]}"; do
        [[ "$seg" == "path" ]] && path_index=$idx
        (( idx++ ))
    done

    idx=0
    for seg in "${SEGMENTS[@]}"; do
        upper_seg="${(U)seg}"                 # os → OS
        varname="${upper_seg}_ELEMENT"        # OS_ELEMENT
        value="${(P)varname}"                 # indirect expand

        [[ -z "$value" ]] && (( idx++ )) && continue

        [[ "$seg" == "none" ]] && RESULT=("${value}") && break

        if [[ "$seg" == "path" ]]; then
            # (( idx == 0 )) && prefix="" || prefix="${PRE_PATH}"
            (( idx == 0 && ! PROMPT_SHOW_OS_ICON )) && prefix="" || prefix="$PRE_PATH"
            suffix="${POST_PATH}"
            RESULT+=("${prefix}${value}${suffix}")
        else
            # Thin separator: append _VS_ unless segment is just before path
            prefix=""
            (( idx == 0 && PROMPT_SHOW_OS_ICON )) && prefix="${_VS_}" || prefix=""
            suffix=""
            (( idx + 1 != path_index )) && suffix="${_VS_}"
            RESULT+=("${prefix}${value}${suffix}")
        fi

        (( idx++ ))
    done

    # Join all SEGMENTS into final PROMPT
    PROMPT="${PROMPT_START}${(j::)RESULT}${PROMPT_END}"

    RPROMPT="${ROOT_TAG}"
}

add-zsh-hook precmd prompt-setup
