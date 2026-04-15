source (status dirname)/helpers/setup.fish

# ============================================================
# Core operations: generate, list, erase, root, dry-run, errors
# ============================================================

@echo "--- generate & manage ---"

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

@echo "--- error handling ---"

set -l result (gencomp __gencomp_nonexistent 2>&1)
@test "error: non-existent command prints error" "$result" = "gencomp: command '__gencomp_nonexistent' is not found"

@echo "--- multiple commands ---"

rm -f "$__gencomp_dir"/*.fish
gencomp __gencomp_dummy_command1 __gencomp_dummy_wrap_source >/dev/null
@test "multiple commands generated in one call" (gencomp --list | count) -eq 2
gencomp --erase __gencomp_dummy_command1 __gencomp_dummy_wrap_source

# Cleanup
rm -rf "$__gencomp_dir"
