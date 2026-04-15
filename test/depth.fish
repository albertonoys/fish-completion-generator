source (status dirname)/helpers/setup.fish

# ============================================================
# --depth: multi-level subcommand recursion
# ============================================================

@echo "--- --depth ---"

# depth 1: discovers subcommands and their options (same as --subcommands)
complete --erase __gencomp_dummy_nested
set -l result (gencomp __gencomp_dummy_nested --depth 1 --dry-run)
@test "depth 1: subcommand options parsed" (printf '%s\n' $result | string match -- '*-l port*' | count) -gt 0
# portal's sub-subcommands (packs, cms) should be listed but their options NOT parsed
@test "depth 1: sub-subcommands listed" (printf '%s\n' $result | string match -- '*-a packs*' | count) -gt 0
@test "depth 1: sub-subcommands not recursed" (printf '%s\n' $result | string match -- '*-l watch*' | count) -eq 0

# depth 2: discovers and recurses into sub-subcommands
complete --erase __gencomp_dummy_nested
set -l result (gencomp __gencomp_dummy_nested --depth 2 --dry-run)
@test "depth 2: sub-subcommand options parsed (--watch)" (printf '%s\n' $result | string match -- '*-l watch*' | count) -gt 0
@test "depth 2: sub-subcommand options parsed (--dev)" (printf '%s\n' $result | string match -- '*-l dev*' | count) -gt 0
@test "depth 2: sub-subcommand options parsed (--theme)" (printf '%s\n' $result | string match -- '*-l theme*' | count) -gt 0
@test "depth 2: parent options still parsed" (printf '%s\n' $result | string match -- '*-l env*' | count) -gt 0

# sub-subcommand uses __fish_seen_subcommand_from parent
@test "depth 2: sub-subcommand listed under parent" (printf '%s\n' $result | string match -- '*seen_subcommand_from portal*-a packs*' | count) -gt 0
# sub-subcommand option uses leaf subcommand name
@test "depth 2: sub-subcommand option uses leaf name" (printf '%s\n' $result | string match -- '*seen_subcommand_from packs*-l watch*' | count) -gt 0

# -S is equivalent to --depth 1
complete --erase __gencomp_dummy_nested
set -l result_s (gencomp __gencomp_dummy_nested -S --dry-run | string collect)
set -l result_d (gencomp __gencomp_dummy_nested --depth 1 --dry-run | string collect)
@test "-S equals depth 1" "$result_s" = "$result_d"

# ============================================================
# --only: regex filter for subcommand recursion
# ============================================================

@echo "--- --only ---"

# --only 'portal' with depth 1: only recurse into portal, not api/db
complete --erase __gencomp_dummy_nested
set -l result (echo y | gencomp __gencomp_dummy_nested --only 'portal' --dry-run 2>/dev/null)
# portal's options should be parsed (recursed)
@test "only: matched subcommand is recursed" (printf '%s\n' $result | string match -- '*-l env*' | count) -gt 0
# api's options should NOT be parsed (skipped by filter)
@test "only: non-matched subcommand not recursed" (printf '%s\n' $result | string match -- '*-l port*' | count) -eq 0
# all three subcommands should still be listed as completions
@test "only: all subcommands still listed" (printf '%s\n' $result | string match -- '*__fish_use_subcommand*' | count) -eq 3
complete --erase __gencomp_dummy_nested

# --only with depth 2: recurse 2 levels but only into portal
complete --erase __gencomp_dummy_nested
set -l result (echo y | gencomp __gencomp_dummy_nested --depth 2 --only '^portal$' --dry-run 2>/dev/null)
# portal packs --watch should be found (depth 2 into portal)
@test "only+depth2: sub-subcommand options parsed" (printf '%s\n' $result | string match -- '*-l watch*' | count) -gt 0
# db --host should NOT be found (db not matched by --only)
@test "only+depth2: non-matched still skipped" (printf '%s\n' $result | string match -- '*-l host*' | count) -eq 0
complete --erase __gencomp_dummy_nested

# ============================================================
# Verbose output
# ============================================================

@echo "--- verbose ---"

set -l __verbose_tmp (mktemp)
gencomp __gencomp_dummy_nested --depth 1 --verbose --dry-run 2>$__verbose_tmp >/dev/null
set -l stderr_output (cat $__verbose_tmp)
rm -f $__verbose_tmp
@test "verbose: shows parsing message" (printf '%s\n' $stderr_output | string match -- '*parsing:*' | count) -gt 0
@test "verbose: shows done message" (printf '%s\n' $stderr_output | string match -- '*done:*completions*' | count) -gt 0

# Cleanup
rm -rf "$__gencomp_dir"
