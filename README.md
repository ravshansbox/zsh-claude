# zsh-claude

A zsh plugin that turns a description into a shell command with [Claude Code](https://code.claude.com), straight from your shell prompt.

## Requirements

- zsh
- `claude` on your `PATH`
- [fzf](https://github.com/junegunn/fzf) on your `PATH`

## Install

### Manual

Clone the repository:

```zsh
git clone https://github.com/ravshansbox/zsh-claude.git ~/.zsh-claude
```

Add this line to `~/.zshrc`:

```zsh
source ~/.zsh-claude/zsh-claude.plugin.zsh
```

Then open a new terminal.

### Oh My Zsh

Clone the repository into your custom plugins folder:

```zsh
git clone https://github.com/ravshansbox/zsh-claude.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-claude
```

Add `zsh-claude` to the plugins list in `~/.zshrc`:

```zsh
plugins=(... zsh-claude)
```

Then open a new terminal.

## Upgrade

Pull the latest version, then open a new terminal.

Manual install:

```zsh
git -C ~/.zsh-claude pull
```

Oh My Zsh:

```zsh
git -C ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-claude pull
```

## Usage

Start a line with `: ` (a colon and a space) to turn a description into a shell command:

```zsh
: find files over 100MB
```

Your line stays on screen and the command appears in a new prompt below it, so you can check it before you press Enter to run it. Claude is told your OS, shell and current directory.

Each request runs on its own and is not saved, so Claude does not remember earlier requests. Requests are not saved to your shell history either.

Pick a model from a list:

```zsh
:model
```

Pick an effort level from a list:

```zsh
:effort
```

Your choices last until you close the terminal. Until you pick one, Claude uses its own defaults.

All other lines run as normal shell commands.

## Known limits

- Do not load this alongside another plugin that rebinds Enter, such as the forge plugin.

## Tests

```zsh
zsh tests/plugin.test.zsh
```

The tests use a fake `claude` and `fzf`, so they do not call Claude.
