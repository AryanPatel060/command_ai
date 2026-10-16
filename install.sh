#!/usr/bin/env bash
set -e

echo "=== Installing On-Demand Ghost Text AI Autocomplete ==="

# Build C++ binary and train model
make all
make install

# Configure ~/.zshrc
ZSHRC="$HOME/.zshrc"
HOOK_MARKER="# AI AUTOCOMPLETE HOOK"

# Strip previous hook if present
if grep -q "$HOOK_MARKER" "$ZSHRC" 2>/dev/null; then
    sed -i '/# AI AUTOCOMPLETE HOOK/,/# END AI AUTOCOMPLETE HOOK/d' "$ZSHRC"
fi

echo "Updating Zsh configuration in $ZSHRC..."
cat << 'EOF' >> "$ZSHRC"

# AI AUTOCOMPLETE HOOK (ON-DEMAND GHOST TEXT FLOW)
AI_SUGGEST_BIN="$HOME/bin/cmd_suggest"

# 1. Trigger ghost text ONLY when Ctrl+Space or Ctrl+Tab is explicitly pressed
function _ai_trigger_autocomplete() {
    if [[ -n "$BUFFER" ]]; then
        local raw_pred=$("$AI_SUGGEST_BIN" "$BUFFER")
        if [[ -n "$raw_pred" ]]; then
            POSTDISPLAY="$raw_pred"
            local start=$#BUFFER
            local end=$(($#BUFFER + $#POSTDISPLAY))
            region_highlight=("${start} ${end} fg=8")
        else
            POSTDISPLAY=""
            region_highlight=()
        fi
    fi
}
zle -N _ai_trigger_autocomplete

# 2. Accept suggestion on Tab (if ghost text is visible) OR fall back to native Zsh completion
function _ai_accept_or_default_tab() {
    if [[ -n "$POSTDISPLAY" ]]; then
        BUFFER="${BUFFER}${POSTDISPLAY}"
        CURSOR=$#BUFFER
        POSTDISPLAY=""
        region_highlight=()
    else
        zle expand-or-complete
    fi
}
zle -N _ai_accept_or_default_tab

# 3. Accept suggestion on Right Arrow / Ctrl+F (if ghost text is visible) OR move cursor right
function _ai_accept_or_forward_arrow() {
    if [[ -n "$POSTDISPLAY" ]]; then
        BUFFER="${BUFFER}${POSTDISPLAY}"
        CURSOR=$#BUFFER
        POSTDISPLAY=""
        region_highlight=()
    else
        zle forward-char
    fi
}
zle -N _ai_accept_or_forward_arrow

# 4. Dismiss ghost text on Esc key
function _ai_dismiss_suggestion() {
    if [[ -n "$POSTDISPLAY" ]]; then
        POSTDISPLAY=""
        region_highlight=()
    fi
}
zle -N _ai_dismiss_suggestion

# Dismiss ghost text automatically if user continues typing or backspacing
function self-insert() {
    _ai_dismiss_suggestion
    zle .self-insert
}
function backward-delete-char() {
    _ai_dismiss_suggestion
    zle .backward-delete-char
}
zle -N self-insert
zle -N backward-delete-char

# KEYBINDINGS
# Trigger AI Ghost Text: Ctrl+Space (^@) or Ctrl+Tab
bindkey '^@' _ai_trigger_autocomplete
bindkey '^[[1;5I' _ai_trigger_autocomplete
bindkey '^[[27;5;9~' _ai_trigger_autocomplete

# Accept AI Ghost Text (if visible) OR run default Zsh Tab completion
bindkey '^I' _ai_accept_or_default_tab

# Accept AI Ghost Text (if visible) OR move cursor right
bindkey '^[[C' _ai_accept_or_forward_arrow
bindkey '^[OC' _ai_accept_or_forward_arrow
bindkey '^F' _ai_accept_or_forward_arrow

# Dismiss AI Ghost Text: Esc
bindkey '^[' _ai_dismiss_suggestion
# END AI AUTOCOMPLETE HOOK
EOF

echo "=== Setup Complete! ==="
echo "Restart your shell with 'exec zsh' to activate changes."