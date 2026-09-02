# gencomp takes a command name, never a path. fish offers directories at command
# position (implicit cd), and abbreviations, which gencomp cannot parse (it
# requires `type -q`), so drop both.
function __gencomp_complete_commands --description 'Commands and functions gencomp can parse'
    __fish_complete_command | string match -rv '^[^\t]*/|\tdirectory$|\tAbbreviation: '
end

complete -c gencomp -f
complete -c gencomp -f -a '(__gencomp_complete_commands)'

complete -x -c gencomp -l edit -a '(gencomp --list)' -d 'edit a generated completion'
complete -x -c gencomp -l erase -a '(gencomp --list)' -d 'erase generated completions'
complete -x -c gencomp -s d -l dry-run -d 'print completions without saving'
complete -x -c gencomp -s f -l force -d 'overwrite an existing completion without asking'
complete -x -c gencomp -s l -l list -d 'list generated completions'
complete -x -c gencomp -s r -l root -d 'print the directory to save completions'
complete -x -c gencomp -s S -l subcommands -d 'generate completion for subcommands'
complete -x -c gencomp -s u -l use -d 'use the specified command to get usage'
complete -x -c gencomp -s w -l wraps -d 'inherit existing completions'
complete -x -c gencomp -s F -l fish-version -a '3 4' -d 'target fish major version'
complete -x -c gencomp -s v -l verbose -d 'show progress on stderr'
complete -x -c gencomp -s h -l help -d 'show this help'
