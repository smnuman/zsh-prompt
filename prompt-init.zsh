#!/usr/bin/env zsh
# 🌀 Set prompt dynamically at each shell
# Following variable is used in prompt-utils.zsh
__last_uid=""
function prompt-setup {

    set_elements    # calling it from prompt-utils.zsh

    PROMPT_START="${OS_ELEMENT}"

    (( ! PROMPT_SHOW_OS_ICON ))     && NONE_ELEMENT=""  # || NONE_ELEMENT="${_VS_}"
    # (( PROMPT_SHOW_OS_ICON && EUID != 0 )) && NONE_ELEMENT="${_VS_}"

    (( PROMPT_SHOW_TIME ))          && TIME_ELEMENT="${PROMPT_TIME}"        || TIME_ELEMENT=""
    (( PROMPT_SHOW_USER ))          && USER_ELEMENT="${PROMPT_USER:-%n}"    || USER_ELEMENT=""
    (( PROMPT_SHOW_VENV && ${+VIRTUAL_ENV} )) \
                                    && VENV_ELEMENT="${V_ENVIRON}"          || VENV_ELEMENT=""
    (( PROMPT_SHOW_NODE )) && [[ -n ${NODE_INFO} ]] \
                                    && NODE_ELEMENT="${NODE_INFO}"          || NODE_ELEMENT=""
    (( PROMPT_SHOW_PATH ))          && PATH_ELEMENT="${ROOT_PATH_ELEMENT}"  || PATH_ELEMENT=""
    # 🌱 Git segment using 'prompt-git-status.zsh' in ~/.config/zsh/prompt/
    GIT_DETAILS=$([[ -d .git && -f "$ZDOTDIR/prompt/prompt-git-status.zsh" ]] &&  git_prompt_segment 2>/dev/null || echo "")
    (( PROMPT_SHOW_GIT ))           && GIT_ELEMENT="${GIT_DETAILS}"         || GIT_ELEMENT=""
    (( PROMPT_SHOW_HISTORY_MODE ))  && HIST_ELEMENT="${ICON_HIST}"          || HIST_ELEMENT=""

    PROMPT_END="%K{15}${HIST_ELEMENT}${ROOT_PROMPT_COLOR}%(!.#.$)${PROMPT_COLOR_RESET} %k${RIGHT_POINTING} "

    local SEGMENTS=()
    local RESULT=()
    local highlight_index=-1
    local user_index=-1
    local idx=0

    local max_seg_len=7

    # default fallback layout if none specified in the PROMPTRC
    PROMPT_DEFAULT_LAYOUT=(time user venv path git)
    # Use PROMPT_LAYOUT from PROMPTRC or default
    PROMPT_LAYOUT=("${PROMPT_LAYOUT[@]:-${PROMPT_DEFAULT_LAYOUT[@]}}")

    for seg in "${PROMPT_LAYOUT[@]}"; do
        case "$seg" in
            time)  [[ -n "$TIME_ELEMENT" ]] && SEGMENTS+=("time")   ;;
            user)  [[ -n "$USER_ELEMENT" ]] && SEGMENTS+=("user")   ;;
            node)  [[ -n "$NODE_ELEMENT" ]] && SEGMENTS+=("node")   ;;
            venv)  [[ -n "$VENV_ELEMENT" ]] && SEGMENTS+=("venv")   ;;
            path)  [[ -n "$PATH_ELEMENT" ]] && SEGMENTS+=("path")   ;;
            git)   [[ -n "$GIT_ELEMENT" ]]  && SEGMENTS+=("git")    ;;
            none)  [[ -n "$NONE_ELEMENT" ]] && SEGMENTS+=("none")   && echo "layout NONE noted ..." ;;
        esac
    done

    last_index=$(( ${#SEGMENTS[@]} - 1 ))
    # echo "              last_index is: ${last_index}"

    # Find index of PATH in layout
    for seg in "${SEGMENTS[@]}"; do
        [[ "$seg" == "${PROMPT_HIGHLIGHT:-path}" ]]                             && highlight_index=$idx
        [[ "$seg" == "user" && $EUID == 0 && $PROMPT_HL_ROOT_USER == 1 ]]       && user_index=$idx
        (( idx++ ))
    done
    # (( $PROMPT_HL_ROOT_USER == 0 )) && ( user_index=-1 )

    # echo -e "              EUID         : ${EUID}"
    # echo -e "              highlight_idx: ${highlight_index}"
    # echo -e "              user_idx     : ${user_index}\n"

    # segment-setter
    idx=0
    for seg in "${SEGMENTS[@]}"; do
        # # --------- remove from here --------------
        # seg_len="${#seg}"
        # pad=$(( max_seg_len - seg_len ))
        # (( pad < 0 )) && pad=0
        # print_seg="${seg}$(printf '%*s' "$pad")"
        # # --------- remove till here --------------
        # echo "Handling segment: ${seg}"
        upper_seg="${(U)seg}"                 # os → OS
        varname="${upper_seg}_ELEMENT"        # OS_ELEMENT
        value="${(P)varname}"                 # indirect expand

        [[ -z "$value" ]] && { (( idx++ )); continue; }

        seg_bg="${ROOT_PATH_COLOR}"           # default bg for a segment, if it is highlighted one and/or a root-user one

        if [[ ( "$seg" == "none" ) && ( PROMPT_SHOW_OS_ICON -eq 1 ) ]]; then
            {
                RESULT=("${value}")
                # echo "RESULT set... to: ]${RESULT}["
            } always {
                # echo "... breaking out for 'none' entry ..." && \
                break ;
            }
        fi

        if [[ "$seg" == "${PROMPT_HIGHLIGHT:-"path"}" ]]; then
            # echo  "Stage: 1 -- [ $print_seg - idx: $idx ] highlighted segment"
            # special case of highlighting a chosen segment (or the default "path" segment) ::
            prefix="${PRE_HIGHLIGHT}"    ;  (( idx == 0 && ! PROMPT_SHOW_OS_ICON ))                                         && prefix="" || \
                                            (( idx != 0 && highlight_index - 1 > user_index  &&  user_index != -1 ))         && prefix="${PRE_HL_MIDDLE}" ;
                                            (( idx != 0 && highlight_index - 1 == user_index &&  user_index != -1 ))         && prefix="${ROOT_SEPARATOR}" ;

            suffix="${POST_HIGHLIGHT}"   ;  (( highlight_index + 1 == user_index &&  user_index     != -1  ))                     && suffix="${ROOT_SEPARATOR}" ;
                                            (( idx == last_index ))                                                         && suffix="${POST_HIGHLIGHT_LAST}"  ;

        elif [[ "$seg" == "user" && "$EUID" == 0 && $PROMPT_HL_ROOT_USER == 1 ]]; then
            # echo  "Stage: 2 -- [ $print_seg - idx: $idx ] highlight root-user"
            # special case of 'root user' segment being highlighted ::
            prefix="${PRE_HIGHLIGHT}"   ;   (( idx == 0 && ! PROMPT_SHOW_OS_ICON ))                                         && prefix="" || \
                                            (( idx != 0 && highlight_index + 1 == user_index && highlight_index != -1 ))    && prefix="" ;
                                            (( idx != 0 && user_index - 1 > highlight_index  && highlight_index != -1 ))     && prefix="${PRE_HL_MIDDLE}" ;

            suffix="${POST_HIGHLIGHT}"  ;   (( user_index + 1 == highlight_index &&  user_index != -1 ))                     && suffix="" ;
                                            (( idx == last_index ))                                                         && suffix="${POST_HIGHLIGHT_LAST}"  ;

        elif [[ ( EUID == 0 ) && ( highlight_index -eq -1 ) && ( user_index -eq -1 ) ]]; then
            # echo  "Stage: 3 -- [ $print_seg - idx: $idx ] root-user, no highlight, no user segment"
            # zshlog --debug -f "${PROMPT_LOG}"  "Stage: 3 -- [ $seg - index: $idx ] root-user, no highlight, no user"
            prefix="1"                   ;
                                            (( idx == 0 && PROMPT_SHOW_OS_ICON ))                                           && prefix="${_VS_}2" ;
                                            (( idx == 0 && ! PROMPT_SHOW_OS_ICON ))                                         && prefix="3" ;
                                            (( last_index <= 0 ))                                                           && prefix="4" ;

            suffix="${_VS_}5"            ;
                                            (( idx == last_index ))                                                         && suffix="${NO_HL_END_SEG}6" ;
                                            (( idx + 1 == highlight_index ))                                                && suffix="7" ;
                                            (( last_index <= 0 ))                                                           && suffix="8" ;
            seg_bg="${ROOT_COLOR}"      ;

        else
            # echo  "Stage: 4 -- [ $print_seg - idx: $idx ]"
            # zshlog --debug -f "${PROMPT_LOG}"  "Stage: 4 -- [ $seg - index: $idx ] regular segment"
            # Thin separator: append _VS_ unless segment is just before highlighted segment or user segment
            # 1. PreFix section ---
            prefix=""                   ;
                                            # FIX: after OS icon, separator -- regular user
                                            (( idx == 0 && PROMPT_SHOW_OS_ICON ))                                           && prefix="${_VS_}" ;
                                            # FIX: no OS icon  -- no seperator before
                                            (( idx == 0 && ! PROMPT_SHOW_OS_ICON ))                                         && prefix="" ;
                                            # FIX: segment alignment -- space before segments when the segment is AFTER highlight/user segment
                                            (( idx != 0 && idx != last_index && \
                                                ( idx > highlight_index && highlight_index != -1 || idx > user_index && user_index != -1  ) \
                                            ))                                                                              && prefix=" " ;
                                            # FIX: root user -- user or highlight available in prompt and segment is after those
                                            (( $EUID == 0 && user_index != -1       && idx > user_index      ))             && prefix="" ;
                                            (( $EUID == 0 && highlight_index != -1  && idx > highlight_index ))             && prefix="" ;

            # 2. Suffix section ---
            suffix=""                   ;
                                            (( highlight_index == -1 && user_index == -1 ))                                 && suffix="${_VS_}" ;
                                            # FIX: long before highlighted segment or user segment -- append separator with space
                                            (( idx + 1 < highlight_index ))                                                 && suffix="${_VS1}" ;
                                            (( idx + 1 < user_index ))                                                      && suffix="${_VS_}" ;
                                            # FIX: just before highlight/user segment - separator removal -- append no separator
                                            (( idx + 1 == highlight_index || idx + 1 == user_index  ))                      && suffix="" ;

                                            (( idx > highlight_index && highlight_index != -1   ))                          && suffix="${_VS1N}" ;
                                            (( idx > user_index      && user_index != -1        ))                          && suffix="${_VS1N}" ;
                                            # FIX: history/prompt string alignement fix -- add spaceless separator at end
                                            (( idx == last_index ))                                                         && suffix="${_VS_LAST_}"  ;
                                            (( idx == last_index && highlight_index == -1 && user_index == -1 ))            && suffix="${NO_HL_END_SEG}"  ;

            # 3. BG section --
            # change bg to normal even though the user is root when the highlight_index and user_index are seperated by other segments, and this is one of them
            # e.g., PROMPT_LAYOUT=(time user path git) when user=root and highlight=git
            seg_bg="${ROOT_COLOR}"      ;
                                            # FIX: highlighted segment is present before current segment -- normal bg and spaceless separator
                                            (( highlight_index != -1 && idx > highlight_index && idx < user_index ))        && seg_bg="${PROMPT_normal_CLR}"  suffix="${_VS1}" ;
                                            # FIX: user segment is present before current segment -- normal bg and spaceless separator
                                            (( user_index != -1 && idx > user_index && idx < highlight_index ))             && seg_bg="${PROMPT_normal_CLR}"  suffix="${_VS1}" ;
                                            # FIX: GIT segment alignement fix -- case - when before highlighted segment or user segment
                                            (( idx != 0 && ( idx + 1 == highlight_index )  ))                               && seg_bg="${PROMPT_normal_CLR}"  suffix="" ;           # before highlight_index
                                            (( idx != 0 && ( idx + 1 == user_index )  ))                                    && seg_bg="${PROMPT_normal_CLR}"  suffix="" ;           # before highlight_index

                                            (( idx != 0 && ( idx + 1 < highlight_index && user_index != -1  ) ))            && seg_bg="${PROMPT_normal_CLR}"  suffix="${_VS1N}" ;   # before highlight_index
                                            (( idx != 0 && ( idx + 1 < user_index && highlight_index != -1  ) ))            && seg_bg="${PROMPT_normal_CLR}"  suffix="${_VS1N}" ;   # before highlight_index
                                            # FIX: a special normal bg between user_index and highlight_index in any order
                                            (( idx != 0 && highlight_index != -1 && idx > highlight_index ))                && seg_bg="${PROMPT_ROOT_NORMAL}" ;
                                            (( idx != 0 && user_index != -1      && idx > user_index ))                     && seg_bg="${PROMPT_ROOT_NORMAL}" ;

        fi

        RESULT+=("${prefix}${seg_bg}${value}${COLOR_RESET}${suffix}")

        (( idx++ ))
    done

    # Join all SEGMENTS into final PROMPT
    PROMPT="${PROMPT_START}${(j::)RESULT}${PROMPT_END}"

    (( PROMPT_RIGHT_SEGMENTS )) && RPROMPT="${ROOT_TAG}" || { RPROMPT="" && echo "RPROMPT is off!!" ; } ;
}

add-zsh-hook precmd prompt-setup
