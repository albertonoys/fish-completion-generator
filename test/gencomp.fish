# Setup
set -g __gencomp_dir (realpath (mktemp -d))
set -g gencomp_dir "$__gencomp_dir"

# source the repo version, not the installed one
source (status dirname)/../functions/gencomp.fish

function __gencomp_dummy_command1
    switch "$argv[1]"
        case -h --help
            string trim "
NAME:
   foo

USAGE:
   foo [global options] command [command options] [arguments...]

VERSION:
   0.0.0

COMMANDS:
     new, n     create foo
     list, l    list foo
     edit, e    edit foo
     help, h    Shows a list of commands or help for one command

GLOBAL OPTIONS:
   --help, -h     show help
   --version, -v  print the version
"
        case list
            switch "$argv[2]"
                case -h --help
                    string trim "
NAME:
   foo list - list foo

USAGE:
   foo list [command options] [arguments...]

OPTIONS:
   --fullpath  show file path of foo
"
            end
    end
end

function __gencomp_dummy_equals_opts
    switch "$argv[1]"
        case -h --help
            string trim "
NAME:
   eqcmd

OPTIONS:
   -f, --file=FILE        specify output file
   --color[=WHEN]         colorize output
   --format=FMT           output format
   -n NUM                 number of items
   -o, --output FILE      output path
"
    end
end

function __gencomp_dummy_multiline
    switch "$argv[1]"
        case -h --help
            printf "COMMANDS:\n"
            printf "    alpha       do alpha things\n"
            printf "    beta        ----------\n"
            printf "beta\n"
            printf "----------\n"
            printf "Beta tools.\n"
            printf "\n"
            printf "    gamma       do gamma things\n"
            printf "    delta       do delta things\n"
    end
end

function __gencomp_dummy_ansi
    switch "$argv[1]"
        case -h --help
            printf "COMMANDS:\n"
            printf "    alpha       do alpha things\n"
            printf "    beta        ----------\n"
            printf "\e[1;36mbeta\e[0m\n"
            printf "----------\n"
            printf "\e[1;36mBeta tools.\e[0m\n"
            printf "\n"
            printf "    gamma       do gamma things\n"
    end
end

function __gencomp_dummy_false_header
    switch "$argv[1]"
        case -h --help
            string trim "
COMMANDS:
    cache       list all available commands
    show        show a specific command
    delete      delete old commands permanently
"
    end
end

function __gencomp_dummy_wrap_source
    switch "$argv[1]"
        case -h --help
            string trim "
OPTIONS:
   -v, --verbose  be verbose
   -q, --quiet    be quiet
"
    end
end

# stub targets for wrap tests (gencomp requires type -q to succeed)
function __gencomp_dummy_wrap_target; end
function __gencomp_dummy_wrap_a; end
function __gencomp_dummy_wrap_b; end

function __gencomp_dummy_all_formats
    switch "$argv[1]"
        case -h --help
            string trim "
OPTIONS:
   -v, --verbose     be verbose
   --help, -h        show help
   --version         print version
   -q                quiet mode
   -debug            enable debug
"
    end
end

function __gencomp_dummy_use_h
    switch "$argv[1]"
        case -h
            string trim "
OPTIONS:
   -v, --verbose  be verbose
"
    end
end

function __gencomp_dummy_mixed_help
    switch "$argv[1]"
        case help
            string trim "
COMMANDS:
    sub1    first subcommand
    sub2    second subcommand
"
        case sub1
            switch "$argv[2]"
                case -h --help
                    string trim "
OPTIONS:
   --alpha  alpha option
"
            end
        case sub2
            switch "$argv[2]"
                case -h --help
                    string trim "
OPTIONS:
   --beta  beta option
"
            end
    end
end

# ============================================================
# Original tests (rewritten for fishtape v3)
# ============================================================

@echo "--- original tests ---"

gencomp __gencomp_dummy_command1
@test "generate completions" $status -eq 0

set -l result (complete -C"__gencomp_dummy_command1 " | awk '{print $1}' | sort | string join " ")
@test "complete them" "$result" = "edit help list new"

gencomp __gencomp_dummy_command1 >/dev/null
@test "list completions" (gencomp --list) = __gencomp_dummy_command1

gencomp __gencomp_dummy_command1 >/dev/null
gencomp --erase __gencomp_dummy_command1
@test "erase completions" (count (gencomp --list)) -eq 0

@test "root of completions" (gencomp --root) = "$__gencomp_dir"

set -l expected (string trim "
complete -f -c __gencomp_dummy_command1 -n __fish_use_subcommand -a new -d 'create foo'
complete -f -c __gencomp_dummy_command1 -n __fish_use_subcommand -a list -d 'list foo'
complete -f -c __gencomp_dummy_command1 -n __fish_use_subcommand -a edit -d 'edit foo'
complete -f -c __gencomp_dummy_command1 -n __fish_use_subcommand -a help -d 'Shows a list of commands or help for one command'
complete -c __gencomp_dummy_command1 -s h -l help -d 'show help'
complete -c __gencomp_dummy_command1 -n __fish_no_arguments -s v -l version -d 'print the version'
" | string collect)
set -l actual (gencomp __gencomp_dummy_command1 --dry-run | string collect)
@test "dry-run" "$actual" = "$expected"

complete --erase __gencomp_dummy_command1
gencomp __gencomp_dummy_command1 --subcommands >/dev/null
@test "generate completions of subcommands' option" (complete -C"__gencomp_dummy_command1 list -" | string match -- '*fullpath*' | count) -gt 0
complete --erase __gencomp_dummy_command1

# ============================================================
# #1 -- Wrap mode
# ============================================================

@echo "--- #1 wrap mode ---"

rm -f "$__gencomp_dir"/*.fish
gencomp __gencomp_dummy_wrap_source >/dev/null
gencomp __gencomp_dummy_wrap_target --wraps __gencomp_dummy_wrap_source >/dev/null
source "$__gencomp_dir/__gencomp_dummy_wrap_target.fish"
set -l result (complete -C"__gencomp_dummy_wrap_target -" | awk '{print $1}' | sort | string join " ")
@test "wraps: inherit completions from another command" "$result" = "-q --quiet -v --verbose"
gencomp --erase __gencomp_dummy_wrap_source __gencomp_dummy_wrap_target

for f in "$__gencomp_dir"/*.fish; rm -f "$f"; end 2>/dev/null
gencomp __gencomp_dummy_wrap_source >/dev/null
gencomp __gencomp_dummy_wrap_a __gencomp_dummy_wrap_b --wraps __gencomp_dummy_wrap_source >/dev/null
set -l result (gencomp --list | sort | string join " ")
@test "wraps: multiple target commands are all generated" "$result" = "__gencomp_dummy_wrap_a __gencomp_dummy_wrap_b __gencomp_dummy_wrap_source"
gencomp --erase __gencomp_dummy_wrap_source __gencomp_dummy_wrap_a __gencomp_dummy_wrap_b

# ============================================================
# #5 -- =VALUE option parsing
# ============================================================

@echo "--- #5 =VALUE options ---"

set -l result (gencomp __gencomp_dummy_equals_opts --dry-run)
@test "options: --file=FILE parsed" (string match -- "*-l file*" $result | count) -gt 0
@test "options: --color[=WHEN] parsed" (string match -- "*-l color*" $result | count) -gt 0
@test "options: --format=FMT parsed" (string match -- "*-l format*" $result | count) -gt 0

# ============================================================
# #6 -- Section header false positives
# ============================================================

@echo "--- #6 section header ---"

set -l result (gencomp __gencomp_dummy_false_header --dry-run | string replace -rf '.*-a (\S+).*' '$1' | string join " ")
@test "subcommands: description containing 'commands' is not skipped" "$result" = "cache show delete"

# ============================================================
# #9 -- Multi-line descriptions & ANSI
# ============================================================

@echo "--- #9 multi-line ---"

set -l result (gencomp __gencomp_dummy_multiline --dry-run | string replace -rf '.*-a (\S+).*' '$1' | string join " ")
@test "subcommands: multi-line descriptions do not break parsing" "$result" = "alpha beta gamma delta"

set -l result (gencomp __gencomp_dummy_ansi --dry-run | string replace -rf '.*-a (\S+).*' '$1' | string join " ")
@test "subcommands: ANSI escape codes do not break parsing" "$result" = "alpha beta gamma"

# ============================================================
# #11 -- --help fallback for subcommands
# ============================================================

@echo "--- #11 help fallback ---"

complete --erase __gencomp_dummy_mixed_help
gencomp __gencomp_dummy_mixed_help --subcommands --use '{} help' >/dev/null
set -l result1 (complete -C"__gencomp_dummy_mixed_help sub1 -" | awk '{print $1}')
set -l result2 (complete -C"__gencomp_dummy_mixed_help sub2 -" | awk '{print $1}')
@test "use: subcommand falls back to --help (sub1)" "$result1" = "--alpha"
@test "use: subcommand falls back to --help (sub2)" "$result2" = "--beta"
complete --erase __gencomp_dummy_mixed_help

# ============================================================
# All five option formats
# ============================================================

@echo "--- option formats ---"

set -l result (gencomp __gencomp_dummy_all_formats --dry-run)
@test "options: -v, --verbose (short then long)" (string match -- "*-s v*-l verbose*" $result | count) -gt 0
@test "options: --help, -h (long then short)" (string match -- "*-s h*-l help*" $result | count) -gt 0
@test "options: --version (long only)" (string match -- "*-l version*" $result | count) -gt 0
@test "options: -q (short only)" (string match -- "*-s q*" $result | count) -gt 0
@test "options: -debug (old style)" (string match -- "*debug*" $result | count) -gt 0

# ============================================================
# --use custom help command
# ============================================================

@echo "--- --use ---"

set -l result (gencomp __gencomp_dummy_use_h --use '{} -h' --dry-run)
@test "use: custom help command" (string match -- "*-s v*-l verbose*" $result | count) -gt 0

# ============================================================
# Error handling
# ============================================================

@echo "--- error handling ---"

set -l result (gencomp __gencomp_nonexistent 2>&1)
@test "error: non-existent command prints error" "$result" = "gencomp: command '__gencomp_nonexistent' is not found"

# ============================================================
# Multiple commands in one invocation
# ============================================================

@echo "--- multiple commands ---"

rm -f "$__gencomp_dir"/*.fish
gencomp __gencomp_dummy_command1 __gencomp_dummy_wrap_source >/dev/null
@test "multiple commands generated in one call" (gencomp --list | count) -eq 2
gencomp --erase __gencomp_dummy_command1 __gencomp_dummy_wrap_source

# Cleanup
rm -rf "$__gencomp_dir"
