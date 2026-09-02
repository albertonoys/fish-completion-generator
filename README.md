# fish-completion-generator

Generate completions for [fish shell](https://fishshell.com) by parsing `--help` output.

## Install

With [Fisher](https://github.com/jorgebucaran/fisher):

```fish
fisher install albertonoys/fish-completion-generator
```

## Usage

```
gencomp - generate fish-shell completions from --help output

Usage: gencomp [options] <command>...
       gencomp --list | --edit <cmd> | --erase <cmd>...

Options:
  -d, --dry-run          print generated completions to stdout
  -f, --force            overwrite an existing completion without asking
  -S, --subcommands      also parse and complete subcommands (depth 1)
  -D, --depth <N>        recurse N levels into subcommands (default: 0)
  -O, --only <regex>     only recurse into matching subcommands (implies -S)
  -u, --use <template>   command to get usage (default: '{} --help')
                         {} is replaced with 'command [subcommand]'
  -w, --wraps <cmd>      copy completions from another command
  -F, --fish-version <N> target fish major version (default: auto)
  -v, --verbose          show progress on stderr

Management:
  -l, --list             list generated completions
      --edit <cmd>       open a generated completion in $EDITOR
      --erase <cmd>...   delete generated completions
  -r, --root             print the completions directory
  -h, --help             show this help

Variables:
  gencomp_dir            override the completions directory
                         (default: $XDG_CONFIG_HOME/fish/generated_completions)

Examples:
  gencomp peco                             parse peco --help
  gencomp ghq --subcommands                parse subcommands (1 level)
  gencomp mycli -S --depth 2 --use '{} help' recurse 2 levels deep
  gencomp mycli -D2 --only 'serve.*' --use '{} help'
                                       only recurse into serve*
  gencomp bd --use '{} -h'                 custom help invocation
  gencomp mycli -S --use '{} help'         top-level 'help', subcommands '--help'
  gencomp my-git --wraps git               inherit git completions
  gencomp mycmd --wraps othercmd -F 3      target Fish 3.x format
  gencomp mycmd --dry-run                  preview without saving
```

## Overwriting existing completions

Completions are generated into a temporary file first, so an existing one is
never clobbered silently. If the new output differs from what is already on
disk, `gencomp` prints the diff (using [delta](https://github.com/dandavison/delta)
when available, otherwise `diff`) and asks before replacing it — defaulting to
**keeping the existing file**. Regenerating identical content is a no-op.

`gencomp` also warns when the command already has a completion file earlier on
`$fish_complete_path` (`~/.config/fish/completions`, vendor completions, ...),
since fish loads the first match and the generated file would never be used.

Use `--force` to skip the prompt. When there is no terminal to prompt on (a
script, a pipeline, CI), `gencomp` refuses to overwrite and keeps the existing
file unless `--force` is given.

## Credits

Fork of [ryotako/fish-completion-generator](https://github.com/ryotako/fish-completion-generator), unmaintained since 2017.

## License

[MIT](LICENCE)
