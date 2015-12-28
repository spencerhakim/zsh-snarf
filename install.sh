#/bin/sh

if [[ "$0" != "zsh" ]]; then
  echo 'Please run this script with zsh'
  exit 1
fi

# Important for $ZSH_CUSTOM, as it's not exported for some reason
source ~/.zshrc

echo
echo '************************************************************'
echo 'Downloading zsh-snarf files...'

# Install any pre-reqs
[[ ! $(command -v wget) ]] && brew install wget

# Install zsh theme
wget 'https://raw.githubusercontent.com/spencerhakim/zsh-snarf/master/snarf.zsh-theme'  \
    -nv -O "$ZSH_CUSTOM/themes/snarf.zsh-theme"

# Install iTerm2 colorscheme, but only on OS X
if [[ $(uname) == 'Darwin' ]]; then
  COLORSCHEME=$(wget 'https://raw.githubusercontent.com/spencerhakim/zsh-snarf/master/Monokai%20Snarf.itermcolors' -nv -O -)
  defaults write com.googlecode.iterm2 'Custom Color Presets' -dict-add 'Monokai Snarf' "$COLORSCHEME"
fi

# Install font
if [[ $(uname) == 'Darwin' ]]; then
  FONT_DIR="$HOME/Library/Fonts" # OS X
else
  FONT_DIR="$HOME/.fonts" # Linux
fi
mkdir -p "$FONT_DIR"
wget 'https://raw.githubusercontent.com/spencerhakim/zsh-snarf/master/Knack%20Regular%20Nerd%20Font%20Complete.otf'  \
    -nv -O "$FONT_DIR/Knack Regular Nerd Font Complete.otf"

echo -n 'Finished downloading zsh-snarf files. Remember to edit your ~/.zshrc; you may also need to quit/re-open iTerm2'
echo -n ' for the color preset and font to appear in their respective dropdown lists.'
echo
