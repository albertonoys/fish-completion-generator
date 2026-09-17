# Shared test setup: temp dir, source gencomp, define all dummy commands.
# Source this at the top of each test file.

set -g __gencomp_dir (realpath (mktemp -d))
set -g gencomp_dir "$__gencomp_dir"

# source the repo version, not the installed one
source (status dirname)/../../functions/gencomp.fish

# --- Dummy commands ---

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

# Nested subcommands: top -> {api, portal, db} ; portal -> {packs, cms}
function __gencomp_dummy_nested
    if test (count $argv) -ge 2
        # sub-subcommand level: e.g. __gencomp_dummy_nested portal --help
        switch "$argv[1]"
            case portal
                switch "$argv[2]"
                    case -h --help
                        string trim "
COMMANDS:
    packs    build portal packs
    cms      manage CMS

OPTIONS:
   --env  environment name
"
                    case packs
                        switch "$argv[3]"
                            case -h --help
                                string trim "
OPTIONS:
   --watch  watch for changes
   --dev    development mode
"
                        end
                    case cms
                        switch "$argv[3]"
                            case -h --help
                                string trim "
OPTIONS:
   --theme  theme name
"
                        end
                end
            case api
                switch "$argv[2]"
                    case -h --help
                        string trim "
OPTIONS:
   --port  listen port
"
                end
            case db
                switch "$argv[2]"
                    case -h --help
                        string trim "
OPTIONS:
   --host  database host
"
                end
        end
    else
        switch "$argv[1]"
            case -h --help
                string trim "
COMMANDS:
    api       API tools
    portal    portal tools
    db        database tools
"
        end
    end
end

# commander.js-style help (e.g. claude): wrapped descriptions aligned to a
# deep column, <arg>/[arg] placeholders, a|b aliases, prose mentioning
# "commands", an examples block inside Commands
function __gencomp_dummy_wrapped
    switch "$argv[1]"
        case -h --help
            printf '%s\n' \
                'Usage: wrapped [options] [command]' \
                '' \
                'Options:' \
                '  --add-dir <directories...>            Additional directories to allow tool' \
                '                                        access to' \
                '  --bg, --background                    Start in the background. With' \
                '                                        --resume <session-id>, continues that' \
                '  --restricted                          Removes the built-in' \
                '  --allowedTools, --allowed-tools <tools...>' \
                '      Comma or space-separated list of tool names to allow' \
                '  --exclude-dynamic-system-prompt-sections' \
                '      Move per-machine sections into the first message' \
                '  --name-prefix <prefix>' \
                '      Prefix for auto-generated session names' \
                '                                        tools that run commands or code (Bash,' \
                '                                        PowerShell, REPL and the other' \
                '  -h, --help                            Display help for command' \
                '' \
                'Commands:' \
                '  agents [options]                      Manage background agents' \
                '  doctor                                Check the health. Reads settings in' \
                '                                        the current directory without a trust' \
                '  add [options] <name> <url>  Add a server.' \
                '  ' \
                '  Examples:' \
                '    wrapped add --transport http sentry https://example.com' \
                '  plugin|plugins                        Manage plugins' \
                '  stop|kill <id>                        Stop a background session'
    end
end

# flag lines in other common shapes, plus prose that must not become options
function __gencomp_dummy_flag_lists
    switch "$argv[1]"
        case -h --help
            printf '%s\n' \
                'OPTIONS:' \
                '   -y, --yes, --assume-yes   answer yes to prompts' \
                '   -o FILE, --output=FILE' \
                '   --no-color' \
                '   -q' \
                '   --tools names them, and ignores user settings' \
                '   -x is deprecated' \
                '   --see also the manual'
    end
end
