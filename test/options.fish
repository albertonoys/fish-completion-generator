source (status dirname)/helpers/setup.fish

# ============================================================
# Option format parsing
# ============================================================

@echo "--- =VALUE options ---"

set -l result (gencomp __gencomp_dummy_equals_opts --dry-run)
@test "options: --file=FILE parsed" (string match -- "*-l file*" $result | count) -gt 0
@test "options: --color[=WHEN] parsed" (string match -- "*-l color*" $result | count) -gt 0
@test "options: --format=FMT parsed" (string match -- "*-l format*" $result | count) -gt 0

@echo "--- all five formats ---"

set -l result (gencomp __gencomp_dummy_all_formats --dry-run)
@test "options: -v, --verbose (short then long)" (string match -- "*-s v*-l verbose*" $result | count) -gt 0
@test "options: --help, -h (long then short)" (string match -- "*-s h*-l help*" $result | count) -gt 0
@test "options: --version (long only)" (string match -- "*-l version*" $result | count) -gt 0
@test "options: -q (short only)" (string match -- "*-s q*" $result | count) -gt 0
@test "options: -debug (old style)" (string match -- "*debug*" $result | count) -gt 0

@echo "--- --use custom help ---"

set -l result (gencomp __gencomp_dummy_use_h --use '{} -h' --dry-run)
@test "use: custom help command" (string match -- "*-s v*-l verbose*" $result | count) -gt 0

# Cleanup
rm -rf "$__gencomp_dir"
