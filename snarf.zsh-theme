# vim:ft=zsh ts=2 sw=2 sts=2
#
# Snarf's Theme
# A Powerline-segmented theme for Oh-My-Zsh, based on Agnoster's Theme
#
### README ############################################################################################################
#
# In order for this theme to render correctly, you will need a "Nerd Font"-patched typeface with Devicons, Font Awesome,
# and Powerline symbols patched in. See [ryanoasis/nerd-fonts](https://github.com/ryanoasis/nerd-fonts) for more info.
#
# I also recommend a Monokai theme and, if you're using Mac OS X, [iTerm 2](http://www.iterm2.com/) over Terminal.app
# as it has significantly better color fidelity.
#
# Required plugins: battery, jsontools
# Required software: GNU utilities (important if on Mac OS X; install them via `brew`)
#
#######################################################################################################################

CURRENT_BG='NONE'

# Special Nerd Font characters
() {
  local LC_ALL="" LC_CTYPE="en_US.UTF-8"

  # Don't use emoji here, they have their own colors and feel out of place
  FA_X=$'\uf00d'
  FA_JOBS=$'\uf1da' # currently "fa-history" rewinding clock icon
  FA_HOME=$'\uf015'
  DI_NODE=$'\ue718'
  DI_DNX=$'\ue77f'
  DI_GIT=$'\ue725'
  PL_SEGMENT_SEPARATOR=$'\ue0b0'
  PL_DIR_SEPARATOR=$'\ue0b1'
}

#######################################################################################################################
### Segment drawing
# A few utility functions to make it easy and re-usable to draw segmented prompts

# Begins a segment
# - Takes two arguments, background and foreground. Both can be omitted, rendering default background/foreground.
# - http://www.calmar.ws/vim/256-xterm-24bit-rgb-color-chart.html
prompt_segment() {
  local bg fg
  [[ -n $1 ]] && bg="$BG[$1]" || bg="%k"
  [[ -n $2 ]] && fg="$FG[$2]" || fg="%f"
  if [[ $CURRENT_BG != 'NONE' && $1 != $CURRENT_BG ]]; then
    echo -n " %{$bg$FG[$CURRENT_BG]%}$PL_SEGMENT_SEPARATOR%{$fg%} "
  else
    echo -n "%{$bg%}%{$fg%} "
  fi
  CURRENT_BG=$1
  [[ -n $3 ]] && echo -n $3
}

# End the prompt, closing any open segments
prompt_end() {
  if [[ -n $CURRENT_BG ]]; then
    echo -n " %{%k$FG[$CURRENT_BG]%}$PL_SEGMENT_SEPARATOR"
  else
    echo -n "%{%k%}"
  fi
  echo -n "%{%f%}"
  CURRENT_BG=''
}

# Truncates the second argument to the length of the first and adds an ellipsis
prompt_truncate() {
  if [[ ${#2} -ge ${1}+3 ]]; then
    printf "%.${1}s..." "${2}"
  else
    printf "%s" "${2}"
  fi
}

# Trim whitespace
prompt_trim() {
  echo -en "$1" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'
}

# Test if command exists
prompt_command() {
  command -v $1 >/dev/null 2>&1
}

#######################################################################################################################
### Prompt components
# Each component will draw itself, and hide itself if no information needs to be shown

# Context:
# - was there an error
# - are there background jobs?
# - root or not?
prompt_context() {
  local symbols bg fg
  symbols=()
  [[ $RETVAL -ne 0 ]] && symbols+="%{%F{1}%}$FA_X" # red X
  [[ $(jobs -l | wc -l) -gt 0 ]] && symbols+="%{%F{3}%}$FA_JOBS" # yellow "background jobs icon"

  if [[ $UID -eq 0 ]]; then
    bg=000; fg=001 # red on black for root
  else
    bg=008; fg=007 # otherwise white on bright black
  fi

  symbols+="%{$FG[$fg]%}%#"
  prompt_segment $bg NONE "$symbols"
}

# Node: version
prompt_node() {
  if[[ $(prompt_command node) -ne 0 ]]; then
    return
  fi

  local nodeVers=$(node -v 2>/dev/null)
  if [[ -f package.json && $(cat package.json | is_json) -eq "True" && -n $nodeVers ]]; then
    prompt_segment 005 000 "$DI_NODE $nodeVers" # magenta is node
  fi
}

# DNX: version
prompt_dnx() {
  if[[ $(prompt_command dnx) -ne 0 ]]; then
    return
  fi

  local dnxVers=$(dnx --version 2>/dev/null | sed -ne 's/.*Version:[[:space:]]*\([[:digit:]]\..*\)/\1/p')
  if [[ -f project.json && $(cat project.json | is_json) -eq "True" && -n dnxVers ]]; then
    prompt_segment 005 000 "$DI_DNX v$dnxVers"
  fi
}

# Dir: current working directory
prompt_dir() {
  local dir=${PWD/~/$FA_HOME }
  dir=`echo -n $dir | sed -e "s/\// $PL_DIR_SEPARATOR /g"`

  prompt_segment 004 000 "$dir" # blue is dir
}

# Git: branch/detached head, dirty status
prompt_git() {
  if[[ $(prompt_command git) -ne 0 ]]; then
    return
  fi

  local ref dirty mode repo_path
  repo_path=$(git rev-parse --git-dir 2>/dev/null)

  if $(git rev-parse --is-inside-work-tree >/dev/null 2>&1); then
    dirty=$(parse_git_dirty)
    ref=$(git symbolic-ref HEAD 2> /dev/null) || ref="➦ $(git rev-parse --short HEAD 2> /dev/null)"
    if [[ -n $dirty ]]; then
      prompt_segment 003 000 # yellow is dirty
    else
      prompt_segment 002 000 # green is clean
    fi

    if [[ -e "${repo_path}/BISECT_LOG" ]]; then
      mode=" <B>"
    elif [[ -e "${repo_path}/MERGE_HEAD" ]]; then
      mode=" >M<"
    elif [[                                                           \
      -e "${repo_path}/rebase" || -e "${repo_path}/rebase-apply" ||   \
      -e "${repo_path}/rebase-merge" || -e "${repo_path}/../.dotest"  \
    ]]; then
      mode=" >R>"
    fi

    setopt promptsubst
    autoload -Uz vcs_info

    zstyle ':vcs_info:*' enable git
    zstyle ':vcs_info:*' get-revision true
    zstyle ':vcs_info:*' check-for-changes true
    zstyle ':vcs_info:*' stagedstr '✚'
    zstyle ':vcs_info:*' unstagedstr '●'
    zstyle ':vcs_info:*' formats ' %u%c'
    zstyle ':vcs_info:*' actionformats ' %u%c'
    vcs_info

    local branch_name=${ref/refs\/heads\//$DI_GIT }
    branch_name=$(prompt_truncate 15 "$branch_name")

    echo -n "${branch_name}${vcs_info_msg_0_%% }${mode}"
  fi
}

#######################################################################################################################
### Main prompt
build_prompt() {
  RETVAL=$?
  prompt_context
  prompt_node
  prompt_dnx
  prompt_dir
  prompt_git
  prompt_end
}

PROMPT='%{%f%b%k%}$(build_prompt) '
RPROMPT='%{%F{8}%}%@ $(battery_pct_prompt)%{%f%}'
