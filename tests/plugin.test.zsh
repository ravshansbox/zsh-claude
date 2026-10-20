#!/usr/bin/env zsh

typeset -g failures=0
typeset -g tmp_dir="$(mktemp -d)"
typeset -g calls_file="$tmp_dir/calls"

cat > "$tmp_dir/claude" <<EOF
#!/usr/bin/env zsh
print -r -- "\$*" >> "$calls_file"
[[ -n "\$CLAUDE_REPLY" ]] && print -r -- "\$CLAUDE_REPLY"
EOF
chmod +x "$tmp_dir/claude"

cat > "$tmp_dir/fzf" <<'EOF'
#!/usr/bin/env zsh
print -r -- "$*" > "${0:h}/fzf_args"
cat > "${0:h}/fzf_items"
[[ -z "$FZF_PICK" ]] && exit 130
grep -m1 -- "$FZF_PICK" "${0:h}/fzf_items"
EOF
chmod +x "$tmp_dir/fzf"

path=("$tmp_dir" $path)
typeset -g plugin_file="${0:A:h:h}/zsh-claude.plugin.zsh"
source "$plugin_file"

function assert_eq() {
    if [[ "$2" == "$3" ]]; then
        print "ok - $1"
    else
        print "not ok - $1"
        print "  expected: $3"
        print "  actual:   $2"
        failures=$((failures + 1))
    fi
}

function calls() { cat "$calls_file" 2>/dev/null }

typeset -g zle_calls=""
function zle() { zle_calls+="$1 " }

function generate() {
    zle_calls=""
    : > "$calls_file"
    BUFFER=": $1"
    CLAUDE_REPLY="ls -la" zsh-claude-accept-line >/dev/null
}

typeset -g task="Reply with only one shell command, no explanation or code fences. OS: $(uname -s). Shell: zsh. Directory: $PWD. Task:"

generate "list files"
assert_eq "command request puts the command in a new prompt" "$BUFFER" "ls -la"
assert_eq "command request keeps the line on screen and does not run it" "$zle_calls" "-I reset-prompt "
assert_eq "command request sends OS, shell and directory without saving a session" "$(calls)" "-p --no-session-persistence -- $task list files"

FZF_PICK=opus :model
assert_eq "models are listed from smallest to largest" "$(print -r -- ${(f)"$(<$tmp_dir/fzf_items)"})" "claude-haiku-5-5 claude-sonnet-5-5 claude-opus-5-5 claude-fable-5-1"
FZF_PICK=xhigh :effort
assert_eq "lists show in the given order from the top" "$(cat "$tmp_dir/fzf_args")" "--layout=reverse --prompt=effort> "
generate "list files"
assert_eq "command request uses the chosen model and effort" "$(calls)" "-p --no-session-persistence --model claude-opus-5-5 --effort xhigh -- $task list files"

FZF_PICK= :model
FZF_PICK= :effort
generate "list files"
assert_eq "cancelling a list keeps the previous choice" "$(calls)" "-p --no-session-persistence --model claude-opus-5-5 --effort xhigh -- $task list files"

HISTSIZE=100
generate "secret task"
assert_eq "command request is not saved to history" "$(fc -ln 1 2>/dev/null)" ""

zle_calls=""
BUFFER=":foo"
zsh-claude-accept-line
assert_eq "other colon lines run as shell commands" "$zle_calls" "accept-line "

unfunction zle

zmodload zsh/zpty
function complete() {
    local out
    zpty tab "zsh -f -i"
    zpty -w tab "autoload -Uz compinit; compinit -u -D; source ${(q)plugin_file}; show() { print -rn -- \"\${(U):-buf}=\$BUFFER=\${(U):-end}\" }; zle -N show; bindkey '^Xs' show"
    zpty -n -w tab "$1"$'\t\x18s'
    zpty -r -m tab out '*BUF=*=END*'
    zpty -d tab
    print -r -- "${${out##*BUF=}%%=END*}"
}

assert_eq "tab completes :model" "$(complete :mo)" ":model "
assert_eq "tab completes :effort" "$(complete :ef)" ":effort "

rm -rf "$tmp_dir"
exit $((failures > 0))
