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
  -S, --subcommands      also parse and complete subcommands
  -u, --use <template>   command to get usage (default: '{} --help')
                         {} is replaced with 'command [subcommand]'
  -w, --wraps <cmd>      copy completions from another command
  -F, --fish-version <N> target fish major version (default: auto)

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
  gencomp ghq --subcommands                parse subcommands recursively
  gencomp bd --use '{} -h'                 custom help invocation
  gencomp iats -S --use '{} help'          top-level 'help', subcommands '--help'
  gencomp my-git --wraps git               inherit git completions
  gencomp mycmd --wraps othercmd -F 3      target Fish 3.x format
  gencomp mycmd --dry-run                  preview without saving
```

## Credits

Fork of [ryotako/fish-completion-generator](https://github.com/ryotako/fish-completion-generator), unmaintained since 2017.

## License

[MIT](LICENCE)
