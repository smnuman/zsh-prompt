#!/usr/bin/env zsh
# 🌀 Set prompt dynamically at each shell

# Function to make a thick separator
function thick_element {
    local element="$1"
    local bg1="$2" fg1="$3"     # element begining colors
    local bg2="$4" fg2="$5"     # element end colors
    echo "%K{${bg1}}%F{${fg1}}${element}%K{${bg2}}%F{${fg2}}${element}%f%k"
}

function thin_element {
    local element="$1"
    local bg="$2" fg="$3"       # element in colors
    local spc="${4:-""}"        # optional space before & after element

    if [[ -n "$bg" ]]; then
        echo "%K{${bg}}${spc}%F{${fg}}${element}%f${spc}%k"
    else
        echo "${spc}%F{${fg}}${element}%f${spc}"
    fi
}

function set_icons {
    # 🌀 OS icon
    OS_ICON=""
    case "$OSTYPE" in
        darwin*)    OS_ICON=$'\uF179' ;;  # macOS
        linux*)
                    if [[ -r /etc/os-release ]]; then
                        . /etc/os-release
                        case "$ID" in
                            ubuntu) OS_ICON=$'\uF31B' ;;  # Ubuntu icon (Nerd Font)
                            *)      OS_ICON=$'\uF17C' ;;  # Generic Linux
                        esac
                    else
                        OS_ICON=$'\uF17C'  # fallback generic Linux
                    fi
                    ;;
        msys*|cygwin*|win32) OS_ICON=$'\uF17A' ;;  # Windows (Git Bash or WSL)
        *)          OS_ICON="❓" ;;
    esac
    ICON_BRANCH=$'\uE0A0'
    ICON_CLEAN="✓"
    ICON_DIRTY="✗"
    ICON_AHEAD="↑"
    ICON_BEHIND="↓"
    ICON_UPSTREAM="⎋"       # green
    ICON_NO_UPSTREAM="⎋"    # red
    ICON_MERGE="🔀"
    ICON_REBASE="⟳"
}

# Helper function to set icons
function set_elements {
    _VS_GIT_=$(thin_element $'\uE0B1' "15" "black") # "%K{15}%F{black}"$'\uE0B1'"%f%k"  # › (thin angle bracket separator)
    RIGHT_POINTING=$(thin_element $'\uE0B0' "" "15") # "%F{15}"$'\uE0B0'"%f"  # Right-pointing arrow filled

    if [[ $(id -u) -eq 0 ]]; then
        ROOT_TAG=%B$(thin_element "[ROOT]" "230" "red" " ")%b
        ROOT_PATH_ELEMENT="%/"
        _VS_=$(thin_element $'\uE0B1' "cyan" "black")       # › (thin angle bracket separator)
        myOS=$(thin_element "${OS_ICON}" "cyan" "red" " ")
        LEFT_SEPARATOR=$(thick_element $'\uE0B0' "black" "cyan" "red" "black")
        RIGHT_SEPARATOR=$(thick_element $'\uE0B0' "black" "red" "15" "black")
    else
        ROOT_TAG=""
        ROOT_PATH_ELEMENT="%~"
        _VS_=$(thin_element $'\uE0B1' "15" "black")       # › (thin angle bracket separator)
        myOS=$(thin_element "${OS_ICON}" "15" "blue" " ")
        LEFT_SEPARATOR=$(thick_element $'\uE0B0' "black" "15" "cyan" "black")
        RIGHT_SEPARATOR=$(thick_element $'\uE0B0' "black" "cyan" "15" "black")
    fi
}

# Helper function to set prompt colours
function set_prompt_colours {
    COLOR_RESET="%f %k"
    PROMPT_COLOR_RESET="%f"
    if [[ $(id -u) -eq 0 ]]; then
        ROOT_COLOR="%K{cyan} %F{15}"
        ROOT_PATH_COLOR="%K{red} %F{15}"
        ROOT_PROMPT_COLOR=" %F{red}"
    else
        ROOT_COLOR="%K{15} %F{241}"
        ROOT_PATH_COLOR="%K{cyan} %F{blue}"
        ROOT_PROMPT_COLOR=" %F{yellow}"
    fi
    PROMPT_FG_MAIN=cyan
    PROMPT_BG_MAIN=black
    PROMPT_FG_ROOT=red
    PROMPT_BG_ROOT=230
    PROMPT_FG_TIME=241
    PROMPT_BG_TIME=15
}

# ----------------=== launching functions at shell change ===----------------
if [[ "$__last_uid" != "$(id -u)" ]]; then
    set_icons
    set_elements
    set_prompt_colours
    __last_uid="$(id -u)"
fi
# --------------------------------=== end ===--------------------------------
