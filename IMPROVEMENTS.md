# gencomp.fish -- Improvements

## Bug Fixes

### 1. Dead branch + premature `return` in wrap mode (lines 253-264)

**Severity:** Critical

The inner condition is always false because the outer `if` already confirmed the list is non-empty.
Additionally, `return 0` exits the entire function instead of continuing to the next command in `$argv`.

```fish
if count $wrap_commands >/dev/null           # true when --wraps given
    if not count $wrap_commands >/dev/null    # ALWAYS FALSE inside outer if
        complete -C"$command " >/dev/null     # dead code -- never reached
        complete | string match "..." >>$output
    else
        for wrap_command in $wrap_commands    # this always runs
            ...
        end
    end
    return 0    # exits the function, skipping remaining commands in $argv
end
```

**Fix:** Remove the dead inner branch and change `return 0` to `continue`.

---

### 2. Unreachable duplicate help check (lines 192-195)

**Severity:** Low (dead code)

Lines 157-160 already check `_flag_h` and return. The identical block at 192-195 is unreachable.

**Fix:** Remove lines 192-195.

---

### 3. `eval` in edit mode breaks on paths with spaces (lines 214-217)

**Severity:** Moderate

```fish
eval "$EDITOR $path"
```

If `$path` contains spaces or special characters the command breaks.

**Fix:** Use `$EDITOR -- $path` directly (no `eval`).

---

### 4. Wrong description for `--edit` in `completions/gencomp.fish`

**Severity:** Low

```fish
complete -x -c gencomp -l edit -a '(gencomp --list)' -d 'erase generated completions'
```

Description says "erase" but should say "edit a generated completion".

---

## Parser Improvements

### 5. Option regexes don't handle `=VALUE` formats (lines 110-142)

**Severity:** High -- many CLI tools use `--option=VALUE`

All 5 option regex patterns fail on common formats like `--file=FILE` or `--color[=WHEN]`
because `=FILE` is not consumed before the space+description part of the pattern.

**Fix:** Add `(?:=\S+|\[=\S+\])?` after the option name in each pattern.

Before:

```
^ *-(\w)(?:, | )--(\w[\w-]+) +(.*)
```

After:

```
^ *-(\w)(?:, | )--(\w[\w-]+)(?:=\S+|\[=\S+\])? +(.*)
```

Apply the same change to all 5 patterns (short+long, long+short, long-only, short-only, old-style).

---

### 6. Section header regex is too permissive (line 73)

**Severity:** Moderate -- can produce false-positive matches on prose text

Current:

```
^([\w ]* )?commands?( [\w ]*)?
```

Matches ordinary prose like "Use commands to..." or "The commands available are".

**Fix:** Require the line to look like a heading (anchor to end-of-line, allow optional colon):

```
^(?:[\w ]+ )?commands?\s*:?\s*$
```

---

### 9. Multi-line subcommand descriptions break command section parsing (line 104)

**Severity:** Critical -- causes subcommands to be silently dropped

When a subcommand entry in the help output has a multi-line description (e.g. with ANSI
escape codes, separator lines, or wrapped text), the continuation lines don't match any
subcommand pattern. The parser then hits `set section default` (line 104) and leaves the
command section. **Every subcommand listed after that point is silently dropped** (until
something accidentally re-triggers the section header regex).

Reproduces with `iats help`, which has entries like:

```
  instructor                           ----------
[1;36minstructor[0m
----------
[1;36mInstructor tools.[0m

  integration                          Manage integration
```

After parsing the `instructor` line, the next line (`[1;36minstructor[0m`) has no leading
spaces and doesn't match either subcommand regex, so `section` is reset to `default`.
The same happens with the `junction` and `keyValueEncryption` entries.

**Interaction with #6 (permissive regex) makes things worse.** Because the section header
regex is so broad, certain subcommand *descriptions* accidentally re-enter the command
section. For example `cache  List all available commands` triggers it because the
description contains the word "commands". This means parsing is fragmented: subcommands are
captured in random chunks between accidental regex hits and multi-line resets. Verified with
`lxc exec sb-1 -- fish -c "cd /home/sb-1/www/iats/code && iats help"`.

Additionally, `iats help` has **no explicit `COMMANDS:` section header**. The parser only
enters `command` mode at all because the stderr log line `Running command help` matches the
loose regex from #6. If stderr is suppressed or the log format changes, zero subcommands
would be generated.

**Fix (two parts):**

**a) Strip ANSI escape codes before parsing (line 70).**

Add `string replace -ra '\e\[[0-9;]*m' ''` to the pipeline so decoration codes don't
pollute the text:

```fish
eval ... 2>&1 | tr \t ' ' | string replace -ra '\e\[[0-9;]*m' '' | while read -l line
```

**b) Don't reset `section` on non-matching lines (line 104).**

Instead of unconditionally resetting to `default`, only leave the command section when the
line actually looks like the start of an options block (i.e. starts with `-`):

```fish
if string match -qr '^\s+-\w' -- "$line"
    set section default
else
    continue
end
```

This keeps the parser in the command section across empty lines, separator lines, and
multi-line descriptions, while still transitioning to option parsing when real option lines
appear.

---

### 10. Help output without a `COMMANDS:` header produces no subcommands

**Severity:** High -- affects tools that list subcommands without a section header

The parser requires a line matching the `commands?` regex to enter the `command` section.
If the help output lists subcommands directly (as `iats help` does), they are never
recognized as subcommands and fall through to the option regexes where they match nothing.

For `iats`, the parser only works at all by accident (see #9 above). Other tools with
similar output formats (e.g. Symfony Console, Laravel Artisan) would produce zero
subcommand completions.

**Fix:** After stripping ANSI codes, detect indented `name   description` lines even when
`section` is `default`. If the line matches the subcommand pattern (leading whitespace +
word + multi-space gap + description) and we're not already parsing a subcommand, treat it
as an implicit command section.

Alternatively, add a heuristic: if the first non-blank, non-header line matches the
subcommand pattern, auto-enter the `command` section.

---

### 11. Subcommand help fallback when `--use` is custom

**Severity:** High -- blocks `--subcommands` for tools like `iats`

The `--use` template is a single pattern applied to both the top-level invocation and every
recursive subcommand call (`__gencomp_parse` line 87/99 passes the same `$use_command`).

For `iats`:
- Top-level command list: `iats help` (needs `--use '{} help'`)
- Subcommand options: `iats git --help` (needs the default `'{} --help'`)

With a single `--use`, you must choose one or the other. Setting `--use '{} help'` makes
the subcommand calls run `iats git help` (which may not work); using the default makes the
top-level run `iats --help` (which doesn't produce the command list).

**Fix:** When `--use` is set to a custom value and `--subcommands` is active, pass the
default `'{} --help'` as a fallback to `__gencomp_parse`. On recursive subcommand calls,
try the custom template first; if it produces no completions, retry with `'{} --help'`.

```fish
function __gencomp_parse -a cmd sub use_command is_subcmd_parse_mode
    ...
    if test "$is_subcmd_parse_mode" = true
        set -l sub_completions (__gencomp_parse "$cmd" "$words[2]" "$use_command" false)
        if test -z "$sub_completions"; and test "$use_command" != '{} --help'
            set sub_completions (__gencomp_parse "$cmd" "$words[2]" '{} --help' false)
        end
        printf '%s\n' $sub_completions
    end
```

No new flags needed. Usage stays simple:

```fish
gencomp iats --subcommands --use '{} help'
```

This runs `iats help` at the top level. For each discovered subcommand, it first tries
`iats git help`; if that returns nothing, it retries with `iats git --help`.

---

## Code Quality

### 7. Comment typos

| Line | Current      | Correct     |
|------|------------- |-------------|
| 94   | `simething`  | `something` |
| 123  | `shiw`       | `show`      |
| 130  | `shiw`       | `show`      |
| 137  | `shiw`       | `show`      |

---

### 8. `conf.d/gencomp.fish` -- XDG and duplicate path entries

**Severity:** Low

Current:

```fish
set fish_complete_path $fish_complete_path "$HOME/.config/fish/generated_completions"
```

- Ignores `$XDG_CONFIG_HOME`.
- Appends every time the file is sourced, creating duplicate entries.

**Fix:** Derive the path from `$XDG_CONFIG_HOME` (falling back to `$HOME/.config`) and guard with `contains`.

---

## Test Plan

Tests use [fishtape](https://github.com/jorgebucaran/fishtape) and follow the patterns in
`test/gencomp.fish`. Each dummy command is a Fish function that echoes canned help output.

### Dummy commands

Add these to `setup` alongside the existing `__gencomp_dummy_command1`.

```fish
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

function __gencomp_dummy_no_header
    switch "$argv[1]"
        case -h --help
            string trim "
Available tools:

  foo    do foo
  bar    do bar
  baz    do baz
"
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
```

---

### Test cases per improvement

#### #1 -- Wrap mode (dead branch + `return 0`)

```fish
test "wraps: inherit completions from another command"
    gencomp __gencomp_dummy_wrap_source
    gencomp __gencomp_dummy_wrap_target --wraps __gencomp_dummy_wrap_source
    "--verbose" "--quiet" = (complete -C"__gencomp_dummy_wrap_target -" | awk '{print $1}' | sort)
end

test "wraps: multiple target commands are all generated"
    gencomp __gencomp_dummy_wrap_source
    gencomp __gencomp_dummy_wrap_a __gencomp_dummy_wrap_b --wraps __gencomp_dummy_wrap_source
    2 = (gencomp --list | grep -c 'dummy_wrap_[ab]')
end
```

The second test fails before the fix because `return 0` exits after the first command.

#### #2 -- Dead code removal

No test needed (no behavioral change).

#### #3 -- `eval` in edit mode with spaces in path

```fish
test "edit: path with spaces does not error"
    set -g gencomp_dir (mktemp -d)/path\ with\ spaces
    mkdir -p "$gencomp_dir"
    echo "" >"$gencomp_dir/mycmd.fish"
    set -l EDITOR true
    gencomp --edit mycmd
    test $status -eq 0
end
```

#### #4 -- Wrong `--edit` description

No fishtape test (static completion metadata). Visual inspection only.

#### #5 -- `=VALUE` / `[=VALUE]` option parsing

```fish
test "options: --file=FILE parsed correctly"
    (string trim "
complete -c __gencomp_dummy_equals_opts -s f -l file -d 'specify output file'
complete -c __gencomp_dummy_equals_opts -l color -d 'colorize output'
complete -c __gencomp_dummy_equals_opts -l format -d 'output format'
complete -c __gencomp_dummy_equals_opts -s n -d 'NUM                 number of items'
complete -c __gencomp_dummy_equals_opts -s o -l output -d 'FILE      output path'
") = (gencomp __gencomp_dummy_equals_opts --dry-run)
end
```

Before the fix, `--file=FILE` and `--color[=WHEN]` don't match any pattern and are
silently dropped.

> **Note:** `-n NUM` and `-o, --output FILE` have space-separated value placeholders that
> are indistinguishable from the description without `=`. The placeholder ends up in the
> description -- this is acceptable and matches current behavior.

#### #6 -- Section header regex false positives

```fish
test "subcommands: description containing 'commands' is not skipped"
    (string trim "
complete -f -c __gencomp_dummy_false_header -n __fish_use_subcommand -a cache -d 'list all available commands'
complete -f -c __gencomp_dummy_false_header -n __fish_use_subcommand -a show -d 'show a specific command'
complete -f -c __gencomp_dummy_false_header -n __fish_use_subcommand -a delete -d 'delete old commands permanently'
") = (gencomp __gencomp_dummy_false_header --dry-run)
end
```

Before the fix, `cache` is skipped because its description `list all available commands`
matches the `commands?` section-header regex and the line is `continue`d instead of being
parsed as a subcommand.

#### #7 -- Comment typos

No test needed.

#### #8 -- `conf.d/gencomp.fish`

No fishtape test (shell startup config behavior).

#### #9 -- Multi-line subcommand descriptions

```fish
test "subcommands: multi-line descriptions do not break parsing"
    alpha beta gamma delta = (gencomp __gencomp_dummy_multiline --dry-run \
        | string match -r -- '-a (\S+)' | string replace -r '.*-a ' '')
end

test "subcommands: ANSI escape codes do not break parsing"
    alpha beta gamma = (gencomp __gencomp_dummy_ansi --dry-run \
        | string match -r -- '-a (\S+)' | string replace -r '.*-a ' '')
end
```

Before the fix, `gamma` (and `delta`) are dropped because the separator / ANSI lines
between `beta` and `gamma` reset the section to `default`.

#### #10 -- No `COMMANDS:` section header

```fish
test "subcommands: recognized without COMMANDS header"
    foo bar baz = (gencomp __gencomp_dummy_no_header --dry-run \
        | string match -r -- '-a (\S+)' | string replace -r '.*-a ' '')
end
```

Before the fix, zero subcommands are generated because the parser never enters the
`command` section.

#### #11 -- Subcommand help fallback with custom `--use`

```fish
test "use: subcommand falls back to --help when custom template returns nothing"
    gencomp __gencomp_dummy_mixed_help --subcommands --use '{} help'
    "--alpha" = (complete -C"__gencomp_dummy_mixed_help sub1 -" | awk '{print $1}')
    "--beta"  = (complete -C"__gencomp_dummy_mixed_help sub2 -" | awk '{print $1}')
end
```

`__gencomp_dummy_mixed_help` responds to `help` at the top level (listing subcommands) but
only responds to `--help` at the subcommand level. The test verifies that the parser
discovers subcommands via `'{} help'` and then automatically falls back to `'{} --help'`
for each subcommand's options.

---

### Testing gaps (not tied to a specific improvement)

#### All five option formats

The existing tests only exercise `--long, -s` (long then short). Cover the remaining four:

```fish
test "options: -v, --verbose (short then long)"
    1 = (gencomp __gencomp_dummy_all_formats --dry-run \
        | string match -c -- '*-s v*-l verbose*')
end

test "options: --help, -h (long then short)"
    1 = (gencomp __gencomp_dummy_all_formats --dry-run \
        | string match -c -- '*-s h*-l help*')
end

test "options: --version (long only)"
    1 = (gencomp __gencomp_dummy_all_formats --dry-run \
        | string match -c -- '*-l version*')
end

test "options: -q (short only)"
    1 = (gencomp __gencomp_dummy_all_formats --dry-run \
        | string match -c -- '*-s q*')
end

test "options: -debug (old style)"
    1 = (gencomp __gencomp_dummy_all_formats --dry-run \
        | string match -c -- '*-debug*')
end
```

#### `--use` custom help command

```fish
test "use: custom help command"
    1 = (gencomp __gencomp_dummy_use_h --use '{} -h' --dry-run \
        | string match -c -- '*-s v*-l verbose*')
end
```

#### Error handling: non-existent command

```fish
test "error: non-existent command prints error"
    "gencomp: command '__gencomp_nonexistent' is not found" = \
        (gencomp __gencomp_nonexistent 2>&1)
end
```

#### Multiple commands in one invocation

```fish
test "multiple commands generated in one call"
    gencomp __gencomp_dummy_command1 __gencomp_dummy_wrap_source
    2 = (gencomp --list | count)
end
```

---

## Checklist

- [ ] **#1** Fix wrap mode: remove dead inner branch, `return 0` -> `continue`
- [ ] **#2** Remove unreachable duplicate help check (lines 192-195)
- [ ] **#3** Replace `eval "$EDITOR $path"` with direct invocation
- [ ] **#4** Fix `--edit` description in `completions/gencomp.fish`
- [ ] **#5** Add `=VALUE` / `[=VALUE]` handling to all 5 option regex patterns
- [ ] **#6** Tighten section header regex to avoid false positives
- [ ] **#7** Fix comment typos (`shiw`, `simething`)
- [ ] **#8** Fix `conf.d/gencomp.fish`: respect `$XDG_CONFIG_HOME`, deduplicate path
- [ ] **#9** Fix multi-line subcommand descriptions: strip ANSI codes + resilient section tracking
- [ ] **#10** Handle help output that lists subcommands without a `COMMANDS:` header
- [ ] **#11** Add `--help` fallback for subcommand parsing when `--use` is custom
- [ ] Run tests (`fishtape test/gencomp.fish`)
- [ ] Manual dry-run test with a real command to verify `=VALUE` parsing
- [ ] Test with `iats help` output to verify subcommand parsing past `instructor`
- [ ] Test `gencomp iats --subcommands --use '{} help'` (subcommands auto-fallback to `--help`)
