#
# Sets key bindings.
#
# Authors:
#   Sorin Ionescu <sorin.ionescu@gmail.com>
#

# Return if requirements are not found.
if [[ "$TERM" == 'dumb' ]]; then
  return 1
fi

#
# Options
#

# Beep on error in line editor.
setopt BEEP

#
# Variables
#

# Treat these characters as part of a word.
WORDCHARS='*?_-.[]~&;!#$%^(){}<>'

# Use human-friendly identifiers.
zmodload zsh/terminfo
typeset -gA key_info
key_info=(
  'Control'      '\C-'
  'ControlLeft'  '\e[1;5D \e[5D \e\e[D \eOd'
  'ControlRight' '\e[1;5C \e[5C \e\e[C \eOc'
  'Escape'       '\e'
  'Meta'         '\M-'
  'Backspace'    "^?"
  'Delete'       "^[[3~"
  'F1'           "$terminfo[kf1]"
  'F2'           "$terminfo[kf2]"
  'F3'           "$terminfo[kf3]"
  'F4'           "$terminfo[kf4]"
  'F5'           "$terminfo[kf5]"
  'F6'           "$terminfo[kf6]"
  'F7'           "$terminfo[kf7]"
  'F8'           "$terminfo[kf8]"
  'F9'           "$terminfo[kf9]"
  'F10'          "$terminfo[kf10]"
  'F11'          "$terminfo[kf11]"
  'F12'          "$terminfo[kf12]"
  'Insert'       "$terminfo[kich1]"
  'Home'         "$terminfo[khome]"
  'PageUp'       "$terminfo[kpp]"
  'End'          "$terminfo[kend]"
  'PageDown'     "$terminfo[knp]"
  'Up'           "$terminfo[kcuu1]"
  'Left'         "$terminfo[kcub1]"
  'Down'         "$terminfo[kcud1]"
  'Right'        "$terminfo[kcuf1]"
  'BackTab'      "$terminfo[kcbt]"
)

# Set empty $key_info values to an invalid UTF-8 sequence to induce silent
# bindkey failure.
for key in "${(k)key_info[@]}"; do
  if [[ -z "$key_info[$key]" ]]; then
    key_info[$key]='�'
  fi
done

#
# External Editor
#

# Allow command line editing in an external editor.
autoload -Uz edit-command-line
zle -N edit-command-line

#
# Functions
#

# Exposes information about the Zsh Line Editor via the $editor_info associative
# array.
function editor-info {
  # Clean up previous $editor_info.
  unset editor_info
  typeset -gA editor_info

  if [[ "$KEYMAP" == 'vicmd' ]]; then
    zstyle -s ':antigen:bundle:joshuarubin:zsh-editor:keymap:alternate' format 'REPLY'
    editor_info[keymap]="$REPLY"
  else
    zstyle -s ':antigen:bundle:joshuarubin:zsh-editor:keymap:primary' format 'REPLY'
    editor_info[keymap]="$REPLY"

    if [[ "$ZLE_STATE" == *overwrite* ]]; then
      zstyle -s ':antigen:bundle:joshuarubin:zsh-editor:keymap:primary:overwrite' format 'REPLY'
      editor_info[overwrite]="$REPLY"
    else
      zstyle -s ':antigen:bundle:joshuarubin:zsh-editor:keymap:primary:insert' format 'REPLY'
      editor_info[overwrite]="$REPLY"
    fi
  fi

  unset REPLY

  zle reset-prompt
  zle -R
}
zle -N editor-info

# Updates editor information when the keymap changes.
function zle-keymap-select {
  zle editor-info
}
zle -N zle-keymap-select

# Disables terminal application mode and updates editor information.
function zle-line-finish {
  # The terminal must be in application mode when ZLE is active for $terminfo
  # values to be valid.
  if (( $+terminfo[rmkx] )); then
    # Disable terminal application mode.
    echoti rmkx
  fi

  # Update editor information.
  zle editor-info
}
zle -N zle-line-finish

# Toggles vi insert mode and updates editor information.
function insert-mode {
  zle .insert-mode
  zle editor-info
}
zle -N insert-mode

# Enters vi insert mode and updates editor information.
function vi-insert {
  zle .vi-insert
  zle editor-info
}
zle -N vi-insert

# Moves to the first non-blank character then enters vi insert mode and updates
# editor information.
function vi-insert-bol {
  zle .vi-insert-bol
  zle editor-info
}
zle -N vi-insert-bol

# Enters vi replace mode and updates editor information.
function vi-replace  {
  zle .vi-replace
  zle editor-info
}
zle -N vi-replace

# Displays an indicator when completing.
function expand-or-complete-with-indicator {
  local indicator
  zstyle -s ':antigen:bundle:joshuarubin:zsh-editor:completing' format 'indicator'
  print -Pn "$indicator"
  zle expand-or-complete
  zle redisplay
}
zle -N expand-or-complete-with-indicator

# Inserts 'sudo ' at the beginning of the line.
function prepend-sudo {
  if [[ "$BUFFER" != su(do|)\ * ]]; then
    BUFFER="sudo $BUFFER"
    (( CURSOR += 5 ))
  fi
}
zle -N prepend-sudo

# Reset to default key bindings.
bindkey -d

#
# Vi Key Bindings
#

# Edit command in an external editor.
bindkey -M vicmd "v" edit-command-line

# Undo/Redo
bindkey -M vicmd "u" undo
bindkey -M vicmd "$key_info[Control]R" redo

if (( $+widgets[history-incremental-pattern-search-backward] )); then
  bindkey -M vicmd "?" history-incremental-pattern-search-backward
  bindkey -M vicmd "/" history-incremental-pattern-search-forward
  bindkey -M viins '^r' history-incremental-pattern-search-backward 
else
  bindkey -M vicmd "?" history-incremental-search-backward
  bindkey -M vicmd "/" history-incremental-search-forward
  bindkey -M viins '^r' history-incremental-search-backward 
fi

#
# Vi Key Bindings
#

bindkey -M "viins" "$key_info[Home]" beginning-of-line
bindkey -M "viins" "$key_info[End]" end-of-line

bindkey -M "viins" "$key_info[Insert]" insert-mode
bindkey -M "viins" "$key_info[Delete]" delete-char
bindkey -M "viins" "$key_info[Backspace]" backward-delete-char

bindkey -M "viins" "$key_info[Left]" backward-char
bindkey -M "viins" "$key_info[Right]" forward-char

# Expand history on space.
bindkey -M "viins" ' ' magic-space

# Clear screen.
bindkey -M "viins" "$key_info[Control]L" clear-screen

# Expand command name to full path.
for key in "$key_info[Escape]"{E,e}
  bindkey -M "viins" "$key" expand-cmd-path

# Duplicate the previous word.
for key in "$key_info[Escape]"{M,m}
  bindkey -M "viins" "$key" copy-prev-shell-word

# Use a more flexible push-line.
for key in "$key_info[Control]Q" "$key_info[Escape]"{q,Q}
  bindkey -M "viins" "$key" push-line-or-edit

# Bind Shift + Tab to go to the previous menu item.
bindkey -M "viins" "$key_info[BackTab]" reverse-menu-complete

# Complete in the middle of word.
bindkey -M "viins" "$key_info[Control]I" expand-or-complete

# Display an indicator when completing.
# bindkey -M "viins" "$key_info[Control]I" expand-or-complete-with-indicator

# Insert 'sudo ' at the beginning of the line.
bindkey -M "viins" "$key_info[Control]X$key_info[Control]S" prepend-sudo

# emacs style
bindkey '^a' beginning-of-line
bindkey '^e' end-of-line

bindkey '^[[H' beginning-of-line
bindkey '^[[F' end-of-line

#
# Layout
#

# Set the key layout.
bindkey -v

unset key{,map,bindings}
