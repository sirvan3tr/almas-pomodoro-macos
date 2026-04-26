import Foundation

/// Shell completion script generation.
///
/// Pure functions that take a shell name and return the script body.
/// No I/O happens here — the caller (CLIRunner) is responsible for
/// printing. That keeps the generator testable end-to-end.
enum Completions {

    enum Shell: String, CaseIterable, Equatable {
        case zsh
        case bash
        case fish
    }

    enum GenerateError: Error, Equatable, CustomStringConvertible {
        case unknownShell(String)

        var description: String {
            switch self {
            case .unknownShell(let raw):
                let supported = Shell.allCases.map(\.rawValue).joined(separator: ", ")
                return "Unknown shell \(String(reflecting: raw)). Supported: \(supported)."
            }
        }
    }

    static func parseShell(_ raw: String) throws -> Shell {
        guard let s = Shell(rawValue: raw.lowercased()) else {
            throw GenerateError.unknownShell(raw)
        }
        return s
    }

    static func script(for shell: Shell) -> String {
        switch shell {
        case .zsh:  return zsh
        case .bash: return bash
        case .fish: return fish
        }
    }

    // MARK: - Templates

    private static let zsh = #"""
    #compdef almaspom
    # Almas Pomodoro — zsh completions
    #
    # Install:
    #   almaspom completions zsh > "${fpath[1]}/_almaspom"
    #   compinit
    # Or via Makefile:
    #   make completions

    _almaspom() {
        local -a subcommands
        subcommands=(
            'stop:Stop the running timer'
            'status:Print current state'
            'dismiss:Acknowledge a finished timer'
            'preset:Start a saved preset'
            'presets:List or modify saved presets'
            'ping:Check the GUI is reachable'
            'completions:Generate shell completion script'
        )

        _arguments -C \
            '(- *)'{-h,--help}'[Show help]' \
            '(- *)--version[Print version]' \
            '1: :->cmd' \
            '*:: :->args'

        case $state in
            cmd)
                _describe -t commands 'almaspom command' subcommands
                ;;
            args)
                case $words[1] in
                    preset)
                        local -a presets
                        # Pull saved preset names from a running app, ignoring failures.
                        presets=( ${(f)"$(almaspom presets 2>/dev/null | awk '{NF--; sub(/ +$/,""); print}')"} )
                        _describe -t presets 'preset' presets
                        ;;
                    presets)
                        _values 'subcommand' \
                            'list[List saved presets]' \
                            'add[Add a preset]' \
                            'rm[Remove a preset]'
                        ;;
                    completions)
                        _values 'shell' 'zsh' 'bash' 'fish'
                        ;;
                esac
                ;;
        esac
    }

    compdef _almaspom almaspom
    """#

    private static let bash = #"""
    # Almas Pomodoro — bash completions
    #
    # Install:
    #   almaspom completions bash > /usr/local/etc/bash_completion.d/almaspom
    # Or source from your bashrc:
    #   eval "$(almaspom completions bash)"

    _almaspom() {
        local cur prev cmd
        COMPREPLY=()
        cur="${COMP_WORDS[COMP_CWORD]}"
        prev="${COMP_WORDS[COMP_CWORD-1]}"
        cmd="${COMP_WORDS[1]}"

        if [[ ${COMP_CWORD} -eq 1 ]]; then
            COMPREPLY=( $(compgen -W "stop status dismiss preset presets ping completions --help --version" -- "$cur") )
            return 0
        fi

        case "$cmd" in
            preset)
                local presets
                presets=$(almaspom presets 2>/dev/null | awk '{NF--; sub(/ +$/,""); print}')
                COMPREPLY=( $(compgen -W "$presets" -- "$cur") )
                ;;
            presets)
                if [[ ${COMP_CWORD} -eq 2 ]]; then
                    COMPREPLY=( $(compgen -W "list add rm" -- "$cur") )
                fi
                ;;
            completions)
                COMPREPLY=( $(compgen -W "zsh bash fish" -- "$cur") )
                ;;
        esac
        return 0
    }

    complete -F _almaspom almaspom
    """#

    private static let fish = #"""
    # Almas Pomodoro — fish completions
    #
    # Install:
    #   almaspom completions fish > ~/.config/fish/completions/almaspom.fish

    function __almaspom_presets
        almaspom presets 2>/dev/null | string replace -r ' +[^ ]+$' ''
    end

    complete -c almaspom -f
    complete -c almaspom -n __fish_use_subcommand -a stop        -d 'Stop the running timer'
    complete -c almaspom -n __fish_use_subcommand -a status      -d 'Print current state'
    complete -c almaspom -n __fish_use_subcommand -a dismiss     -d 'Acknowledge a finished timer'
    complete -c almaspom -n __fish_use_subcommand -a preset      -d 'Start a saved preset'
    complete -c almaspom -n __fish_use_subcommand -a presets     -d 'List or modify presets'
    complete -c almaspom -n __fish_use_subcommand -a ping        -d 'Check the GUI is reachable'
    complete -c almaspom -n __fish_use_subcommand -a completions -d 'Generate shell completion script'

    complete -c almaspom -n '__fish_seen_subcommand_from preset' -a '(__almaspom_presets)'

    complete -c almaspom -n '__fish_seen_subcommand_from presets' -a 'list add rm'

    complete -c almaspom -n '__fish_seen_subcommand_from completions' -a 'zsh bash fish'

    complete -c almaspom -s h -l help    -d 'Show help'
    complete -c almaspom      -l version -d 'Print version'
    complete -c almaspom -s i -l intent  -d 'Set the session intent'
    complete -c almaspom      -l as      -d 'Label this ad-hoc session'
    """#
}
