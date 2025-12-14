#!/usr/bin/env zsh
# 🌀 Set prompt dynamically at each shell
# Following variable is used in prompt-utils.zsh
__last_uid=""
function prompt-setup {

    PROMPT_START="${OS_ELEMENT}"

    NONE_ELEMENT="${_VS_}"

    # (( PROMPT_SHOW_TIME ))          && TIME_ELEMENT="${PRE_TIME}${PROMPT_TIME}" || TIME_ELEMENT=""
    # (( PROMPT_SHOW_USER ))          && USER_ELEMENT="${PRE_USER}${PROMPT_USER:-%n}" || USER_ELEMENT=""
    # (( PROMPT_SHOW_VENV && \
    #     ${+VIRTUAL_ENV} ))          && VENV_ELEMENT="${_VS_}${V_ENVIRON}" || VENV_ELEMENT=""
    # (( PROMPT_SHOW_PATH ))          && PATH_ELEMENT="${ROOT_PATH_ELEMENT}" || PATH_ELEMENT=""
    # # 🌱 Git segment using 'prompt-git-status.zsh' in ~/.config/zsh/prompt/
    # GIT_DETAILS=$([[ -d .git && -f "$ZDOTDIR/prompt/prompt-git-status.zsh" ]] &&  git_prompt_segment 2>/dev/null || echo "")
    # (( PROMPT_SHOW_GIT ))           && GIT_ELEMENT="${PRE_GIT}${GIT_DETAILS}" || GIT_ELEMENT=""
    # (( PROMPT_SHOW_HISTORY_MODE ))  && HIST_ELEMENT="${PRE_HIST}${ICON_HIST}" || HIST_ELEMENT=""

    (( PROMPT_SHOW_TIME ))          && TIME_ELEMENT="${PROMPT_TIME}" || TIME_ELEMENT=""
    (( PROMPT_SHOW_USER ))          && USER_ELEMENT=" ${PROMPT_USER:-%n}" || USER_ELEMENT=""
    (( PROMPT_SHOW_VENV && \
        ${+VIRTUAL_ENV} ))          && VENV_ELEMENT="${_VS_}${V_ENVIRON}" || VENV_ELEMENT=""
    (( PROMPT_SHOW_PATH ))          && PATH_ELEMENT="${ROOT_PATH_ELEMENT}" || PATH_ELEMENT=""
    # 🌱 Git segment using 'prompt-git-status.zsh' in ~/.config/zsh/prompt/
    GIT_DETAILS=$([[ -d .git && -f "$ZDOTDIR/prompt/prompt-git-status.zsh" ]] &&  git_prompt_segment 2>/dev/null || echo "")
    (( PROMPT_SHOW_GIT ))           && GIT_ELEMENT="${GIT_DETAILS}" || GIT_ELEMENT=""
    (( PROMPT_SHOW_HISTORY_MODE ))  && HIST_ELEMENT="${ICON_HIST}" || HIST_ELEMENT=""

    PROMPT_END="%K{15}${HIST_ELEMENT}${ROOT_PROMPT_COLOR}%(!.#.$)${PROMPT_COLOR_RESET} %k${RIGHT_POINTING} "

    local SEGMENTS=()
    local RESULT=()
    local highlight_index=-1
    local user_index=-1
    local idx=0

    # default fallback layout if none specified in the PROMPTRC
    PROMPT_DEFAULT_LAYOUT=(time user venv path git)
    # Use PROMPT_LAYOUT from PROMPTRC or default
    PROMPT_LAYOUT=("${PROMPT_LAYOUT[@]:-${PROMPT_DEFAULT_LAYOUT[@]}}")

    for seg in "${PROMPT_LAYOUT[@]}"; do
        case "$seg" in
            time)  [[ -n "$TIME_ELEMENT" ]] && SEGMENTS+=("time")   ;;
            user)  [[ -n "$USER_ELEMENT" ]] && SEGMENTS+=("user")   ;;
            venv)  [[ -n "$VENV_ELEMENT" ]] && SEGMENTS+=("venv")   ;;
            path)  [[ -n "$PATH_ELEMENT" ]] && SEGMENTS+=("path")   ;;
            git)   [[ -n "$GIT_ELEMENT" ]]  && SEGMENTS+=("git")    ;;
            none)  [[ -n "$NONE_ELEMENT" ]] && SEGMENTS+=("none")   ;;
        esac
    done

    last_index=$(( ${#SEGMENTS[@]} - 1 ))

    # Find index of PATH in layout
    for seg in "${SEGMENTS[@]}"; do
        [[ "$seg" == "${PROMPT_HIGHLIGHT:-path}" ]] && highlight_index=$idx
        [[ "$seg" == "user" && $EUID -eq 0 ]]       && user_index=$idx
        (( idx++ ))
    done

    idx=0
    for seg in "${SEGMENTS[@]}"; do
        upper_seg="${(U)seg}"                 # os → OS
        varname="${upper_seg}_ELEMENT"        # OS_ELEMENT
        value="${(P)varname}"                 # indirect expand

        seg_bg="${ROOT_PATH_COLOR}"           # default bg for a segment

        [[ -z "$value" ]] && (( idx++ )) && continue

        [[ "$seg" == "none" ]] && RESULT=("${value}") && break

        if [[ "$seg" == "${PROMPT_HIGHLIGHT:-"path"}" ]]; then
            # special case of highlighting a chosen segment (or the default "path" segment) ::
            prefix="${PRE_HIGHLIGHT}"    ;  (( idx == 0 && ! PROMPT_SHOW_OS_ICON ))                                         && prefix="" || \
                                            (( idx != 0 && highlight_index - 1 > user_index && user_index != -1 ))          && prefix="${PRE_HL_MIDDLE}" ;
                                            (( highlight_index - 1 == user_index && user_index != -1 ))                     && prefix="${ROOT_SEPARATOR}" ;

            suffix="${POST_HIGHLIGHT}"   ;  (( highlight_index + 1 == user_index && user_index != -1 ))                     && suffix="${ROOT_SEPARATOR}" ;

        elif [[ "$seg" == "user" && $EUID -eq 0 ]]; then
            # special case of 'root user' segment being highlighted ::
            prefix="${PRE_HIGHLIGHT}"   ;   (( idx == 0 && ! PROMPT_SHOW_OS_ICON ))                                         && prefix="" || \
                                            (( idx != 0 && highlight_index + 1 == user_index && user_index != -1 ))         && prefix="" ;
                                            (( idx != 0 && user_index - 1 > highlight_index && highlight_index != -1 ))     && prefix="${PRE_HL_MIDDLE}" ;

            suffix="${POST_HIGHLIGHT}"  ;   (( user_index + 1 == highlight_index && user_index != -1 ))                     && suffix="" ;

        else
            # Thin separator: append _VS_ unless segment is just before path
            prefix=""                   ;   (( idx == 0 && PROMPT_SHOW_OS_ICON ))                                           && prefix="${_VS_}" ;

            suffix=""                   ;   (( idx + 1 != highlight_index && idx + 1 != user_index  ))                      && suffix="${_VS_}" ;
                                            (( idx + 1 == highlight_index && highlight_index != -1  ))                      && suffix="" ;
                                            (( idx + 1 == user_index      && user_index != -1       ))                      && suffix="" ;

            seg_bg="${ROOT_COLOR}"      ;   (( idx > highlight_index && highlight_index != -1 ))                            && seg_bg="${PROMPT_normal_CLR}" suffix="${_VS2}" ;
                                            (( idx > user_index && user_index != -1 ))                                      && seg_bg="${PROMPT_normal_CLR}" suffix="${_VS2}" ;

        fi

        RESULT+=("${prefix}${seg_bg}${value}${COLOR_RESET}${suffix}")

        (( idx++ ))
    done

    # Join all SEGMENTS into final PROMPT
    PROMPT="${PROMPT_START}${(j::)RESULT}${PROMPT_END}"

    RPROMPT="${ROOT_TAG}"
}

add-zsh-hook precmd prompt-setup
