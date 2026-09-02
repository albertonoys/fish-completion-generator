source (status dirname)/helpers/setup.fish

# ============================================================
# Overwrite protection: never clobber an existing completion
# without showing the diff and asking first
# ============================================================

@echo "--- overwrite protection ---"

set -l target "$gencomp_dir/__gencomp_dummy_command1.fish"

gencomp __gencomp_dummy_command1 >/dev/null
@test "overwrite: first generate writes the file" -f "$target"

gencomp __gencomp_dummy_command1 >/dev/null
@test "overwrite: regenerating identical content succeeds" $status -eq 0

echo "# hand-edited" >>$target
gencomp __gencomp_dummy_command1 >/dev/null 2>&1
@test "overwrite: refuses to clobber without a terminal" $status -eq 1
@test "overwrite: existing file is kept" (tail -1 $target) = "# hand-edited"

gencomp --force __gencomp_dummy_command1 >/dev/null
@test "overwrite: --force succeeds" $status -eq 0
@test "overwrite: --force replaces the hand edit" (grep -c hand-edited $target) -eq 0

gencomp --dry-run __gencomp_dummy_command1 >/dev/null
@test "overwrite: --dry-run never touches the file" (grep -c hand-edited $target) -eq 0

# ============================================================
# Shadowing: warn when an earlier $fish_complete_path entry
# already provides completions for the command
# ============================================================

@echo "--- shadow detection ---"

set -l early (mktemp -d)
set -l old_complete_path $fish_complete_path
set -g fish_complete_path $early $gencomp_dir

set -l quiet (gencomp __gencomp_dummy_command1 --force 2>&1 >/dev/null | string collect)
@test "shadow: no warning when nothing shadows" -z "$quiet"

echo "# handwritten" >$early/__gencomp_dummy_command1.fish
set -l warned (gencomp __gencomp_dummy_command1 --force 2>&1 >/dev/null | string collect)
@test "shadow: warns about the shadowing file" -n (echo $warned | string match -r "is loaded before")
@test "shadow: names the shadowing file" -n (echo $warned | string match -r "$early/__gencomp_dummy_command1.fish")
@test "shadow: still generates the file" -f "$gencomp_dir/__gencomp_dummy_command1.fish"

set -g fish_complete_path $old_complete_path
