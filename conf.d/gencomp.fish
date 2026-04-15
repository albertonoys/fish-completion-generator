if test -n "$XDG_CONFIG_HOME"
    set -l _gencomp_path "$XDG_CONFIG_HOME/fish/generated_completions"
else
    set -l _gencomp_path "$HOME/.config/fish/generated_completions"
end
if not contains -- "$_gencomp_path" $fish_complete_path
    set fish_complete_path $fish_complete_path "$_gencomp_path"
end
