#!/usr/bin/env zsh
# 🌀 Set prompt dynamically at each shell

# Return the current history mode icon for the prompt
function history_mode_icon() {
    local spc=" "
    if setopt | grep -q sharehistory; then
        echo "${spc}🌎"   # Shared mode
    else
        echo "${spc}🔏"   # Private mode
    fi
}

# Function to make a thick separator
function thick_element {
    local element="$1" post_spc="${6:-""}"
    local bg1="$2" fg1="$3"     # element begining colors
    local bg2="$4" fg2="$5"     # element end colors
    echo "%K{${bg1}}%F{${fg1}}${element}%K{${bg2}}%F{${fg2}}${element}%f${post_spc}%k"
}

# Function to make a thin separator
function thin_element {
    local element="$1"
    local bg="$2" fg="$3"       # element in colors
    local pre_spc="${4:-""}"    # optional space before element
    local post_spc="${5:-""}"   # optional space after element

    if [[ -n "$bg" ]]; then
        echo "%K{${bg}}${pre_spc}%F{${fg}}${element}%f${post_spc}"     # the %k termiantion is in the next element, by design
    else
        echo "%F{${fg}}${element}%f"
        # echo "${element}"
    fi
}

function set_icons {
    # 🌀 OS icon
    OS_ICON=${CUSTOM_OS_ICON:-""}
    [[ -n "$OS_ICON" ]] ||
    case "$OSTYPE" in
        darwin*)                OS_ICON=$'\uF179' ;;                    # macOS
        linux*)
                                if [[ -r /etc/os-release ]]; then
                                    . /etc/os-release
                                    case "$ID" in
                                        ubuntu) OS_ICON=$'\uF31B' ;;    # Ubuntu icon (Nerd Font)
                                        *)      OS_ICON=$'\uF17C' ;;    # Generic Linux
                                    esac
                                else
                                    OS_ICON=$'\uF17C'                   # fallback generic Linux
                                fi
                                ;;
        msys*|cygwin*|win32)    OS_ICON=$'\uF17A' ;;                    # Windows (Git Bash or WSL)
        *)                      OS_ICON="❓" ;;                         # Unknown OS
    esac
    ICON_HIST=$(type history_mode_icon >/dev/null 2>&1 && history_mode_icon || echo "")
    ICON_BRANCH=$'\uE0A0'
    ICON_CLEAN="✓"             # in green
    ICON_DIRTY="✗"             # in red
    ICON_AHEAD="↑"
    ICON_BEHIND="↓"
    ICON_UPSTREAM="⎋"          # in green
    ICON_NO_UPSTREAM="⎋"       # in red
    ICON_MERGE="🔀"
    ICON_REBASE="⟳"
    PRE_SPACE=" "
    POST_SPACE=" "
    NO_SPACE=""
}

# Helper function to reset dynamic elements used in prompt-init.zsh
function set_dynamic_elements {
    V_ENVIRON="${${VIRTUAL_ENV:t}:-}"
    NODE_INFO="$(command -v node >/dev/null 2>&1 && node --version 2>/dev/null)"
}

# Helper function to set various elements used in the prompt-segments
function set_elements {

    _VS_GIT_=$(thin_element                  $'\uE0B1'      "${_VS_GIT_BG}"         "${PROMPT_EL_FG}"           "${PRE_SPACE}"              "${POST_SPACE}"     ) # › (thin angle bracket separator for git segment internals)
    RIGHT_POINTING=$(thin_element            $'\uE0B0'      ""                      "${PROMPT_normal_BG}"                               ) # Right-pointing arrow filled
    _VS1N=$(thin_element                     $'\uE0B1'      "${PROMPT_normal_BG}"   "${PROMPT_EL_FG}"           ""                          "${POST_SPACE}"     ) # › (thin angle bracket separator 1: without pre-space)
    _VS2N=$(thin_element                     $'\uE0B1'      "${PROMPT_normal_BG}"   "${PROMPT_EL_FG}"                                   )                               # › (thin angle bracket separator 2: without any space pre- or -post)

    if [[ $(id -u) -eq 0 ]]; then
        # root user elements
        (( PROMPT_SHOW_OS_ICON )) && \
        OS_ELEMENT=$(thin_element            "${OS_ICON}"   "${PROMPT_OS_ROOT_BG}"  "${PROMPT_OS_ROOT_FG}"      "${PRE_SPACE}"              "${POST_SPACE}"     ) || \
        OS_ELEMENT=$(thin_element            ""             "${PROMPT_OS_ROOT_BG}"  "${PROMPT_OS_ROOT_FG}"                                                      )
        ROOT_TAG=%B$(thin_element            "[ROOT]"       "230"                   "${PROMPT_OS_ROOT_FG}"      "${PRE_SPACE}"          )%b
        ROOT_SEPARATOR=$(thin_element        $'\uE0B1'      "${PROMPT_ROOT_BG}"     "${PROMPT_EL_FG}"                                   )
        ROOT_PATH_ELEMENT="%/"
        _VS_=$(thin_element                  $'\uE0B1'      "${PROMPT_HL_BG}"       "${PROMPT_EL_FG}"                                   ) # › (thin angle bracket separator)
        _VS1=$(thin_element                  $'\uE0B1'      "${PROMPT_OS_ROOT_BG}"  "${PROMPT_EL_FG}"           ""                          "${POST_SPACE}"     ) # › (thin angle bracket separator 1: without pre-space)
        _VS2=$(thin_element                  $'\uE0B1'      "${PROMPT_OS_ROOT_BG}"  "${PROMPT_EL_FG}"                                   ) # › (thin angle bracket separator 2: without any space pre- or -post)
        NO_HL_END_SEG=$(thick_element        $'\uE0B0'      "${PROMPT_EL_FG}"       "${PROMPT_ROOT_PreHL_BG}"   "${PROMPT_normal_BG}"       "${PROMPT_EL_FG}"       )
        PRE_HL_MIDDLE=$(thick_element        $'\uE0B0'      "${PROMPT_EL_FG}"       "${PROMPT_ROOT_FG}"         "${PROMPT_ROOT_BG}"         "${PROMPT_EL_FG}"       )
        PRE_HIGHLIGHT=$(thick_element        $'\uE0B0'      "${PROMPT_EL_FG}"       "${PROMPT_HL_BG}"           "${PROMPT_ROOT_BG}"         "${PROMPT_EL_FG}"       )
        POST_HIGHLIGHT=$(thick_element       $'\uE0B0'      "${PROMPT_EL_FG}"       "${PROMPT_ROOT_BG}"         "${PROMPT_normal_BG}"       "${PROMPT_EL_FG}"   " " )
        POST_HIGHLIGHT_LAST=$(thick_element  $'\uE0B0'      "${PROMPT_EL_FG}"       "${PROMPT_ROOT_BG}"         "${PROMPT_normal_BG}"       "${PROMPT_EL_FG}"       )
        PROMPT_normal_CLR="%K{${PROMPT_ROOT_PreHL_BG}}%F{${PROMPT_ROOT_PreHL_FG}}"
        NONE_ELEMENT="${NO_HL_END_SEG}"
    else
        # regular user elements
        (( PROMPT_SHOW_OS_ICON )) && \
        OS_ELEMENT=$(thin_element            "${OS_ICON}"   "${PROMPT_normal_BG}"   "${PROMPT_OS_FG}"           "${PRE_SPACE}"              "${POST_SPACE}"         ) || \
        OS_ELEMENT=$(thin_element            ""             "${PROMPT_normal_BG}"   "${PROMPT_OS_FG}"                                   )
        ROOT_TAG=""
        ROOT_PATH_ELEMENT="%~"
        _VS_=$(thin_element                  $'\uE0B1'      "${PROMPT_normal_BG}"   "${PROMPT_EL_FG}"                                   )                               # › (thin angle bracket separator)
        _VS1=$(thin_element                  $'\uE0B1'      "${PROMPT_normal_BG}"   "${PROMPT_EL_FG}"           ""                          "${POST_SPACE}"         )   # › (thin angle bracket separator 1: without pre-space)
        _VS2=$(thin_element                  $'\uE0B1'      "${PROMPT_normal_BG}"   "${PROMPT_EL_FG}"                                   )                               # › (thin angle bracket separator 2: without any space pre- or -post)
        NO_HL_END_SEG=$(thin_element         $'\uE0B1'      "${PROMPT_normal_BG}"   "${PROMPT_EL_FG}"                                   )   # › (thin angle bracket separator 1: without pre-space)
        PRE_HIGHLIGHT=$(thick_element        $'\uE0B0'      "${PROMPT_EL_FG}"       "${PROMPT_normal_BG}"       "${PROMPT_HL_BG}"           "${PROMPT_EL_FG}"       )
        POST_HIGHLIGHT=$(thick_element       $'\uE0B0'      "${PROMPT_EL_FG}"       "${PROMPT_HL_BG}"           "${PROMPT_normal_BG}"       "${PROMPT_EL_FG}"   " " )
        POST_HIGHLIGHT_LAST=$(thick_element  $'\uE0B0'      "${PROMPT_EL_FG}"       "${PROMPT_HL_BG}"           "${PROMPT_normal_BG}"       "${PROMPT_EL_FG}"       )
        PROMPT_normal_CLR="%K{${PROMPT_normal_BG}}%F{${PROMPT_normal_FG}}"
        NONE_ELEMENT="${_VS_}"
    fi

    _VS_LAST_=$(thin_element                  $'\uE0B1'      "${PROMPT_normal_BG}"   "${PROMPT_EL_FG}"                                  )                               # › (thin angle bracket separator 2: without any space pre- or -post)

    PROMPT_TIME="${PROMPT_TIME_FORMAT:=%*}"
    PROMPT_USER="%n${${USER_WITH_MACHINE:#0}:+@%m}"

    V_ENVIRON="${${VIRTUAL_ENV:t}:-}"
    NODE_INFO="$(command -v node >/dev/null 2>&1 && node --version 2>/dev/null)"

    # GIT_DETAILS=$([[ -d .git && -f "$ZDOTDIR/prompt/prompt-git-status.zsh" ]] && git_prompt_segment || echo "") # not yet available here
}

# Helper function to set prompt colours
function set_prompt_colours {
    COLOR_RESET="%f %k"
    PROMPT_COLOR_RESET="%f"

    _VS_GIT_BG="${PROMPT_HIGHLIGHT_COLOR:-cyan}"
    [[ $PROMPT_HIGHLIGHT == git ]] || _VS_GIT_BG="15"

    PROMPT_HL_BG="${PROMPT_HIGHLIGHT_BODY:-"cyan"}"
    PROMPT_HL_FG="${PROMPT_HIGHLIGHT_TEXT:-"blue"}"

    PROMPT_normal_BG="${PROMPT_GENERAL_BODY:-"15"}"
    PROMPT_normal_FG="${PROMPT_GENERAL_TEXT:-"241"}" # or black

    PROMPT_ROOT_BG="${PROMPT_GENERAL_ROOT_BODY:-"red"}"
    PROMPT_ROOT_FG="${PROMPT_GENERAL_ROOT_TEXT:-"15"}"

    PROMPT_ROOT_PreHL_BG="${PROMPT_ROOT_PreHL_BODY:-"cyan"}"
    PROMPT_ROOT_PreHL_FG="${PROMPT_ROOT_PreHL_TEXT:-"15"}"

    PROMPT_ROOT_NORMAL="%K{${PROMPT_normal_BG}}%F{${PROMPT_normal_FG}}"

    PROMPT_EL_FG="${PROMPT_ELEMENT_COLOR:-"black"}"

    PROMPT_OS_ROOT_BG="${PROMPT_OS_ROOT_BODY:-"cyan"}"
    PROMPT_OS_ROOT_FG="${PROMPT_OS_ROOT_COLOR:-"red"}"
    PROMPT_OS_FG="${PROMPT_OS_COLOR:-"blue"}"

    PROMPT_PROMPT_FG="${PROMPT_PROMPT_COLOR:-"yellow"}"

    PROMPT_FG_MAIN=cyan
    PROMPT_BG_MAIN=black
    PROMPT_FG_ROOT=red
    PROMPT_BG_ROOT=230
    PROMPT_FG_TIME=241
    PROMPT_BG_TIME=15

    if [[ $(id -u) -eq 0 ]]; then
        ROOT_COLOR="%K{${PROMPT_ROOT_PreHL_BG:-cyan}} %F{${PROMPT_ROOT_PreHL_FG:-15}}"
        ROOT_PATH_COLOR="%K{${PROMPT_ROOT_BG:-red}} %F{${PROMPT_ROOT_FG:-15}}"
        ROOT_PROMPT_COLOR=" %F{${PROMPT_OS_ROOT_FG:-red}}"
    else
        ROOT_COLOR="%K{${PROMPT_normal_BG:-15}} %F{${PROMPT_normal_FG:-241}}"
        ROOT_PATH_COLOR="%K{${PROMPT_HL_BG:-cyan}} %F{${PROMPT_HL_FG:-blue}}"
        ROOT_PROMPT_COLOR=" %F{${PROMPT_PROMPT_FG:-yellow}}"
    fi
}

# ----------------=== launching functions at shell change ===----------------
if [[ "$__last_uid" != "$(id -u)" ]]; then
    set_icons
    set_prompt_colours
    # set_elements
    __last_uid="$(id -u)"
fi
# --------------------------------=== end ===--------------------------------
