source (status dirname)/helpers/setup.fish

# ============================================================
# conf.d puts the completions directory on $fish_complete_path
# ============================================================

@echo "--- conf.d ---"

set -l before $fish_complete_path
set -lx XDG_CONFIG_HOME (mktemp -d)
set -g fish_complete_path $before

source (status dirname)/../conf.d/gencomp.fish

@test "conf.d: adds the completions directory" -n (contains -- "$XDG_CONFIG_HOME/fish/generated_completions" $fish_complete_path; and echo yes)
@test "conf.d: adds no empty entry" (contains -- "" $fish_complete_path; and echo bad; or echo ok) = ok

source (status dirname)/../conf.d/gencomp.fish
@test "conf.d: sourcing twice does not duplicate" (count (string match -- "$XDG_CONFIG_HOME/fish/generated_completions" $fish_complete_path)) -eq 1

set -g fish_complete_path $before
