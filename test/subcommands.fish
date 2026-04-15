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
set -l result (complete -C"__gencomp_dummy_wrap_target -" | awk '{print $1}' | sort | string join " ")
@test "wraps: inherit completions from another command" "$result" = "-q --quiet -v --verbose"
gencomp --erase __gencomp_dummy_wrap_source __gencomp_dummy_wrap_target

for f in "$__gencomp_dir"/*.fish; rm -f "$f"; end 2>/dev/null
gencomp __gencomp_dummy_wrap_source >/dev/null
gencomp __gencomp_dummy_wrap_a __gencomp_dummy_wrap_b --wraps __gencomp_dummy_wrap_source >/dev/null
set -l result (gencomp --list | sort | string join " ")
@test "wraps: multiple target commands are all generated" "$result" = "__gencomp_dummy_wrap_a __gencomp_dummy_wrap_b __gencomp_dummy_wrap_source"
gencomp --erase __gencomp_dummy_wrap_source __gencomp_dummy_wrap_a __gencomp_dummy_wrap_b

# Cleanup
rm -rf "$__gencomp_dir"
