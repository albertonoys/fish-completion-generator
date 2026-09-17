source (status dirname)/helpers/setup.fish

# ============================================================
# Subcommand discovery and parsing
# ============================================================

@echo "--- subcommand basics ---"

complete --erase __gencomp_dummy_command1
gencomp __gencomp_dummy_command1 --subcommands >/dev/null
@test "subcommands: option parsed" (complete -C"__gencomp_dummy_command1 list -" | string match -- '*fullpath*' | count) -gt 0
complete --erase __gencomp_dummy_command1

@echo "--- section header false positives ---"

set -l result (gencomp __gencomp_dummy_false_header --dry-run | string replace -rf '.*-a (\S+).*' '$1' | string join " ")
@test "subcommands: description containing 'commands' is not skipped" "$result" = "cache show delete"

@echo "--- multi-line descriptions & ANSI ---"

set -l result (gencomp __gencomp_dummy_multiline --dry-run | string replace -rf '.*-a (\S+).*' '$1' | string join " ")
@test "subcommands: multi-line descriptions do not break parsing" "$result" = "alpha beta gamma delta"

set -l result (gencomp __gencomp_dummy_ansi --dry-run | string replace -rf '.*-a (\S+).*' '$1' | string join " ")
@test "subcommands: ANSI escape codes do not break parsing" "$result" = "alpha beta gamma"

@echo "--- commander-style help (wrapped, placeholders, aliases) ---"

set -l out (gencomp __gencomp_dummy_wrapped --dry-run)
set -l result (string replace -rf '.*-a (\S+).*' '$1' -- $out | string join " ")
@test "subcommands: prose and wrapped lines are not subcommands" "$result" = "agents doctor add plugin plugins stop kill"
@test "subcommands: <arg>/[arg] placeholders stripped from description" (string match -- "*-a add -d 'Add a server.'" $out | count) -eq 1
@test "options: wrapped line starting with --flag is not an option" (string match -- "*-l resume*" $out | count) -eq 0
@test "options: <arg> placeholder stripped from description" (string match -- "*-l add-dir -d 'Additional directories to allow tool'" $out | count) -eq 1

@test "options: flag lists and next-line descriptions are all found" (string match -- '* -l *' $out | string replace -r '^complete -c \S+ ' '' | string join ";") = "-l add-dir -d 'Additional directories to allow tool';-l bg -l background -d 'Start in the background. With';-l restricted -d 'Removes the built-in';-l allowedTools -l allowed-tools;-l exclude-dynamic-system-prompt-sections;-l name-prefix;-s h -l help -d 'Display help for command'"

set -l out (gencomp __gencomp_dummy_flag_lists --dry-run | string replace -r '^complete -c \S+ ' '' | string join ";")
@test "options: flag lists found, prose starting with a flag rejected" "$out" = "-s y -l yes -l assume-yes -d 'answer yes to prompts';-s o -l output;-l no-color;-s q"

@echo "--- --help fallback ---"

complete --erase __gencomp_dummy_mixed_help
gencomp __gencomp_dummy_mixed_help --subcommands --use '{} help' >/dev/null
set -l result1 (complete -C"__gencomp_dummy_mixed_help sub1 -" | awk '{print $1}')
set -l result2 (complete -C"__gencomp_dummy_mixed_help sub2 -" | awk '{print $1}')
@test "use: subcommand falls back to --help (sub1)" "$result1" = "--alpha"
@test "use: subcommand falls back to --help (sub2)" "$result2" = "--beta"
complete --erase __gencomp_dummy_mixed_help

@echo "--- wraps ---"

rm -f "$__gencomp_dir"/*.fish
gencomp __gencomp_dummy_wrap_source >/dev/null
gencomp __gencomp_dummy_wrap_target --wraps __gencomp_dummy_wrap_source >/dev/null
source "$__gencomp_dir/__gencomp_dummy_wrap_target.fish"
# LC_ALL=C so the order does not depend on the runner's collation
set -l result (complete -C"__gencomp_dummy_wrap_target -" | awk '{print $1}' | env LC_ALL=C sort | string join " ")
@test "wraps: inherit completions from another command" "$result" = "--quiet --verbose -q -v"
gencomp --erase __gencomp_dummy_wrap_source __gencomp_dummy_wrap_target

for f in "$__gencomp_dir"/*.fish; rm -f "$f"; end 2>/dev/null
gencomp __gencomp_dummy_wrap_source >/dev/null
gencomp __gencomp_dummy_wrap_a __gencomp_dummy_wrap_b --wraps __gencomp_dummy_wrap_source >/dev/null
set -l result (gencomp --list | env LC_ALL=C sort | string join " ")
@test "wraps: multiple target commands are all generated" "$result" = "__gencomp_dummy_wrap_a __gencomp_dummy_wrap_b __gencomp_dummy_wrap_source"
gencomp --erase __gencomp_dummy_wrap_source __gencomp_dummy_wrap_a __gencomp_dummy_wrap_b

# Cleanup
rm -rf "$__gencomp_dir"
