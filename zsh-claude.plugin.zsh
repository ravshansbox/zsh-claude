#!/usr/bin/env zsh

typeset -g _ZSH_CLAUDE_MODEL=""
typeset -g _ZSH_CLAUDE_EFFORT=""

function :model() {
    local choice
    choice="$(print -l claude-haiku-5-5 claude-sonnet-5-5 claude-opus-5-5 claude-fable-5-1 | fzf --layout=reverse --prompt='model> ')"
    [[ -n "$choice" ]] && _ZSH_CLAUDE_MODEL="$choice"
}

function :effort() {
    local choice
    choice="$(print -l low medium high xhigh max | fzf --layout=reverse --prompt='effort> ')"
    [[ -n "$choice" ]] && _ZSH_CLAUDE_EFFORT="$choice"
}

function _zsh_claude_ask() {
    local -a args=(-p --no-session-persistence)
    [[ -n "$_ZSH_CLAUDE_MODEL" ]] && args+=(--model "$_ZSH_CLAUDE_MODEL")
    [[ -n "$_ZSH_CLAUDE_EFFORT" ]] && args+=(--effort "$_ZSH_CLAUDE_EFFORT")
    claude "${args[@]}" -- "$1"
}

function zsh-claude-accept-line() {
    case "$BUFFER" in
        :model|:effort)
            echo
            $BUFFER </dev/tty >/dev/tty
            BUFFER=""
            zle -I
            zle reset-prompt
            ;;
        ": "?*)
            local command
            echo
            command="$(_zsh_claude_ask "Reply with only one shell command, no explanation or code fences. OS: $(uname -s). Shell: zsh. Directory: $PWD. Task: ${BUFFER#: }" </dev/null)"
            zle -I
            BUFFER="$command"
            CURSOR=$#BUFFER
            zle reset-prompt
            ;;
        *)
            zle accept-line
            ;;
    esac
}

zle -N zsh-claude-accept-line
bindkey '^M' zsh-claude-accept-line
bindkey '^J' zsh-claude-accept-line
