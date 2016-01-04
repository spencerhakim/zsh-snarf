#!/bin/sh

if [[ "$0" != "zsh" ]]; then
  echo 'Please run this script with zsh'
  exit 1
fi

_download () {

  # Hack for dev - I don't want this script breaking/changing my files
  if [[ -L "$2" ]]; then
    echo "Skipping $1 due to symlink at $2"
    return
  fi

  echo "Downloading $1..."
  curl -fSL# "$1" -o "$2"
}

# Important for $ZSH_CUSTOM, as it's not exported for some reason
source ~/.zshrc

echo
echo '************************************************************'
echo 'Installing zsh-snarf...'

# Install zsh theme
mkdir -p "$ZSH_CUSTOM/themes/"

_download                                                                 \
  'https://raw.github.com/spencerhakim/zsh-snarf/master/snarf.zsh-theme'  \
  "$ZSH_CUSTOM/themes/snarf.zsh-theme"

# Install iTerm2 colorscheme, but only on OS X
if [[ $(uname) == 'Darwin' ]]; then
  _download                                                                             \
    'https://raw.github.com/spencerhakim/zsh-snarf/master/Monokai%20Snarf.itermcolors'  \
    "$TMPDIR/Monokai Snarf.itermcolors"

  COLORSCHEME=$(cat "$TMPDIR/Monokai Snarf.itermcolors")
  defaults write com.googlecode.iterm2 'Custom Color Presets' -dict-add 'Monokai Snarf' "$COLORSCHEME"
fi

# Install font
if [[ $(uname) == 'Darwin' ]]; then
  FONT_DIR="$HOME/Library/Fonts" # OS X
else
  FONT_DIR="$HOME/.fonts" # Linux
fi
mkdir -p "$FONT_DIR"

_download                                                                                             \
  'https://raw.github.com/spencerhakim/zsh-snarf/master/Knack%20Regular%20Nerd%20Font%20Complete.otf' \
  "$FONT_DIR/Knack Regular Nerd Font Complete.otf"

echo '************************************************************'
echo -n 'Finished installing zsh-snarf. Remember to edit your ~/.zshrc; you may also need to quit/re-open iTerm2'
echo -n ' for the color preset and font to appear in their respective dropdown lists.'
echo
