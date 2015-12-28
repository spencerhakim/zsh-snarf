#/bin/zsh
source ~/.zshrc

echo
echo '************************************************************'
echo 'Downloading zsh-snarf files...'

# Install any pre-reqs
if [[ !$(command -v wget >/dev/null 2>&1) ]]; then
  brew install wget >/dev/null 2>&1
fi

# Install zsh theme
wget 'https://raw.githubusercontent.com/spencerhakim/zsh-snarf/master/snarf.zsh-theme'  \
    -nv -O "$ZSH_CUSTOM/themes/snarf.zsh-theme"

# Install iTerm2 colorscheme
COLORSCHEME=$(wget 'https://raw.githubusercontent.com/spencerhakim/zsh-snarf/master/Monokai%20Snarf.itermcolors' -nv -O -)
defaults write com.googlecode.iterm2 'Custom Color Presets' -dict-add 'Monokai Snarf' "$COLORSCHEME"

# Install font
wget 'https://raw.githubusercontent.com/spencerhakim/zsh-snarf/master/Knack%20Regular%20Nerd%20Font%20Complete.otf'  \
    -nv -O "$HOME/Library/Fonts/Knack Regular Nerd Font Complete.otf"

echo -n 'Finished downloading zsh-snarf files. Remember to edit your ~/.zshrc; you may also need to quit/re-open iTerm2'
echo -n ' for the color preset and font to appear in their respective dropdown lists.'
echo
