# Fish completion for eds. Install:
#   cp eds.fish ~/.config/fish/completions/eds.fish

set -l commands con_check stat history migrate new validate verify init version help

complete -c eds -f
complete -c eds -n "not __fish_seen_subcommand_from $commands" -a "$commands" -d "eds command"
complete -c eds -n "__fish_seen_subcommand_from migrate" -a "down" -d "Roll back the last migration"
complete -c eds -n "__fish_seen_subcommand_from migrate" -a "dry-run" -d "List pending without applying"
complete -c eds -n "__fish_seen_subcommand_from migrate" -a "force" -d "Bypass checksum drift check"
complete -c eds -n "__fish_seen_subcommand_from migrate validate verify" -a "json" -d "JSON output"
complete -c eds -n "__fish_seen_subcommand_from migrate validate verify" -a "-f --path" -d "Custom migrations directory"
complete -c eds -n "__fish_seen_subcommand_from stat con_check" -a "json" -d "JSON output"