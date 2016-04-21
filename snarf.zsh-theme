#!/usr/bin/env zsh
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
# Required Oh-My-Zsh plugins: battery
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
  FA_ROOT=$'\uf071' # currently "fa-warning" triangle with exclamation
  DI_NODE=$'\ue718'
  DI_DNX=$'\ue77f'
  DI_RUBY=$'\ue791'
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

# Find project file in PWD tree
prompt_proj_tree() {
  setopt extended_glob
  setopt null_glob
  files=( (../)#$1 )
  echo -n "${files[-1]}"
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
  [[ $1 -ne 0 ]] && symbols+="%{%F{1}%}$FA_X" # red X
  [[ $(jobs -l | wc -l) -gt 0 ]] && symbols+="%{%F{3}%}$FA_JOBS" # yellow "background jobs icon"

  if [[ $UID -eq 0 ]]; then
    bg=000; fg=001 # red on black for root
  else
    bg=008; fg=007 # otherwise white on bright black
  fi

  symbols+="%{$FG[$fg]%}%#"
  prompt_segment $bg NONE "$symbols"
}

# Project environment: node/dnx/ruby version
prompt_proj_env() {

  local version icon
  if [[ -f $(prompt_proj_tree package.json) ]]; then
    version=$(node -v 2>/dev/null) || version='MISSING'
    icon=$DI_NODE

  elif [[ -f $(prompt_proj_tree project.json) ]]; then
    version=$(dnx --version 2>/dev/null | sed -ne 's/.*Version:[[:space:]]*\([[:digit:]]\..*\)/v\1/p') || version='MISSING'
    icon=$DI_DNX

  elif [[ -f $(prompt_proj_tree Gemfile) ]]; then
    version=$(ruby -e 'print "v"+RUBY_VERSION' 2>/dev/null) || version='MISSING'
    icon=$DI_RUBY

  else
    return
  fi

  prompt_segment 005 000 "$icon $version" # magenta is project environment
}

# Dir: current working directory
prompt_dir() {
  local dir
  if [[ $PWD == "/" ]]; then
    # In root
    dir="$FA_ROOT "
  elif [[ ${PWD##~} != $PWD ]]; then
    # In $HOME or subdir
    dir=${PWD/~/$FA_HOME }
  else
    dir=${PWD/\//$FA_ROOT  $PL_DIR_SEPARATOR }
  fi

  dir=`echo -n $dir | sed -e "s/\// $PL_DIR_SEPARATOR /g"`
  prompt_segment 004 000 "$dir" # blue is dir
}

# Git: branch/detached head, dirty status
prompt_git() {
  if [[ ! $(command -v git) || $(git config --get oh-my-zsh.hide-status) -eq 1 ]]; then
    return
  fi

  if $(git rev-parse --is-inside-work-tree >/dev/null 2>&1); then
    local dirty=$(parse_git_dirty)
    if [[ -n $dirty ]]; then
      prompt_segment 003 000 # yellow is dirty
    else
      prompt_segment 002 000 # green is clean
    fi

    local repo_path="$(git rev-parse --git-dir 2>/dev/null)"
    local mode
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

    local branch_name=$(prompt_truncate 15 "$(git_current_branch)")
    echo -n "$DI_GIT ${branch_name}${vcs_info_msg_0_%% }${mode}"
  fi
}

#######################################################################################################################
### Main prompt
build_prompt() {
  prompt_context $?
  prompt_proj_env
  prompt_dir
  prompt_git
  prompt_end
}

PROMPT='%{%f%b%k%}$(build_prompt) '
RPROMPT='%{%F{8}%}%@ $(battery_pct_prompt)%{%f%}'
