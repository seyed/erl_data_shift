# Bash completion for eds. Install:
#   source /path/to/eds-completion.bash
# or copy to /etc/bash_completion.d/eds (Linux) or
# $(brew --prefix)/etc/bash_completion.d/eds (macOS with bash-completion).

_eds_complete() {
    local cur prev commands
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"

    commands="con_check stat history migrate new validate verify init version help"
    migrate_subcommands="down dry-run force json -f --path"

    if [ "$COMP_CWORD" -eq 1 ]; then
        COMPREPLY=( $(compgen -W "${commands} --version --help -h" -- "${cur}") )
        return 0
    fi

    if [ "${COMP_WORDS[1]}" = "migrate" ]; then
        COMPREPLY=( $(compgen -W "${migrate_subcommands}" -- "${cur}") )
        return 0
    fi

    case "${COMP_WORDS[1]}" in
        validate|verify)
            COMPREPLY=( $(compgen -W "json -f --path" -- "${cur}") )
            ;;
        stat|con_check)
            COMPREPLY=( $(compgen -W "json" -- "${cur}") )
            ;;
        new)
            COMPREPLY=()
            ;;
    esac
}

complete -F _eds_complete eds