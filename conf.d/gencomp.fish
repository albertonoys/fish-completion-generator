# `set -l` inside an if/else block is scoped to that block, so compute the path
# at script scope -- otherwise the variable is empty by the time it is used and
# an empty entry gets appended to $fish_complete_path instead of the directory.
set -l _gencomp_path "$HOME/.config/fish/generated_completions"
test -n "$XDG_CONFIG_HOME"
and set _gencomp_path "$XDG_CONFIG_HOME/fish/generated_completions"

if not contains -- "$_gencomp_path" $fish_complete_path
    set -a fish_complete_path "$_gencomp_path"
end
