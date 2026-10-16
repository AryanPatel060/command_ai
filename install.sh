#!/usr/bin/env bash
set -e

echo "=== Building Terminal AI Autocomplete ==="

# Build C++ executable and train model
make all
make install

# Configure ~/.zshrc
ZSHRC="$HOME/.zshrc"
HOOK_MARKER="# AI AUTOCOMPLETE HOOK"

if ! grep -q "$HOOK_MARKER" "$ZSHRC" 2>/dev/null; then
    echo "Adding hooks to $ZSHRC..."
    cat << 'EOF' >> "$ZSHRC"

# AI AUTOCOMPLETE HOOK
AI_SUGGEST_BIN="$HOME/bin/cmd_suggest"

function _ai_update_suggestion() {
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
    else
        POSTDISPLAY=""
        region_highlight=()
    fi
}

function _ai_accept_suggestion() {
    if [[ -n "$POSTDISPLAY" ]]; then
        BUFFER="${BUFFER}${POSTDISPLAY}"
        CURSOR=$#BUFFER
        POSTDISPLAY=""
        region_highlight=()
        _ai_update_suggestion
    else
        zle expand-or-complete
    fi
}
zle -N _ai_accept_suggestion

function _ai_dismiss_suggestion() {
    POSTDISPLAY=""
    region_highlight=()
}
zle -N _ai_dismiss_suggestion

function self-insert() {
    zle .self-insert
    _ai_update_suggestion
}
function backward-delete-char() {
    zle .backward-delete-char
    _ai_update_suggestion
}

zle -N self-insert
zle -N backward-delete-char

bindkey '^I' _ai_accept_suggestion
bindkey '^[' _ai_dismiss_suggestion
EOF
    echo "Zsh hooks added!"
else
    echo "Zsh hooks already configured in $ZSHRC"
fi

echo "=== Setup Complete! ==="
echo "Run 'source ~/.zshrc' to start using inline AI suggestions."