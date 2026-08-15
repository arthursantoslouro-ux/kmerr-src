#!/bin/sh

CONFIG="${HOME}/.kr_conf"

# Colors
reset='\033[0m'
red='\033[1;31m'
green='\033[1;32m'

# Default actions
SUCCESS=""
FAILED=""
END=""

# Create configuration file if it doesn't exist
if [ ! -f "$CONFIG" ]; then
cat << 'EOF' > "$CONFIG"
# kr_conf
# WARNING: SUCCESS, FAILED and END contain shell commands

# This file is automatically created by kmrror.
# It is used to customize actions when a command succeeds, fails,
# or finishes.

# SUCCESS is executed when the command finishes successfully.
SUCCESS=""

# FAILED is executed when the command fails.
FAILED=""

# END is executed when the command finishes, regardless of its result.
END=""

# You can also define actions for specific exit codes.
# Example:
# ON_127="echo 'Command not found'"
# ON_126="echo 'Permission denied'"
EOF
fi

# Load configuration
. "$CONFIG"


error() {
    printf '%b[ ERROR ] command failed%b\n' "$red" "$reset"
}


help() {
    printf '%s\n' \
        "kmrror - ferramenta de diagnóstico" \
        "" \
        "Uso:" \
        "  kmrror [opções] comando [argumentos...]" \
        "" \
        "Opções:" \
        "  -h, --help              Mostra ajuda" \
        "  -v, --version           Mostra versão" \
        "  --success COMMAND       Ação em caso de sucesso" \
        "  --success=COMMAND       Ação em caso de sucesso" \
        "  --failed COMMAND        Ação em caso de falha" \
        "  --failed=COMMAND        Ação em caso de falha" \
        "  --end COMMAND           Ação executada ao terminar" \
        "  --end=COMMAND           Ação executada ao terminar" \
        "  --                    Fim das opções do kmrror" \
        "" \
        "Exemplos:" \
        "  kmrror apt update" \
        "  kmrror --success 'echo OK' true" \
        "  kmrror --failed 'echo ERRO' false" \
        "  kmrror --end 'echo terminou' sleep 5" \
        "  kmrror --end='termux-toast \"terminou\"' sleep 5"
}


mostrar_erro() {
    case "$1" in
        127)
            echo "Command not found"
            ;;
        126)
            echo "Permission denied: cannot execute file"
            ;;
        130)
            echo "Command interrupted by user (Ctrl+C)"
            ;;
        139)
            echo "Segmentation fault"
            ;;
        *)
            echo "Unknown error (exit code: $1)"
            ;;
    esac
}


# Parse kmrror options
while [ "$#" -gt 0 ]; do
    case "$1" in

        -h|--help)
            help
            exit 0
            ;;

        -v|--version)
            printf '%s\n' "kmrror 0.1.1"
            exit 0
            ;;

        --success)
            if [ "$#" -lt 2 ]; then
                printf '%b[ ERROR ] --success requires a command%b\n' \
                    "$red" "$reset" >&2
                exit 2
            fi

            SUCCESS="$2"
            shift 2
            ;;

        --success=*)
            SUCCESS="${1#*=}"
            shift
            ;;

        --failed)
            if [ "$#" -lt 2 ]; then
                printf '%b[ ERROR ] --failed requires a command%b\n' \
                    "$red" "$reset" >&2
                exit 2
            fi

            FAILED="$2"
            shift 2
            ;;

        --failed=*)
            FAILED="${1#*=}"
            shift
            ;;

        --end)
            if [ "$#" -lt 2 ]; then
                printf '%b[ ERROR ] --end requires a command%b\n' \
                    "$red" "$reset" >&2
                exit 2
            fi

            END="$2"
            shift 2
            ;;

        --end=*)
            END="${1#*=}"
            shift
            ;;

        --)
            shift
            break
            ;;

        *)
            break
            ;;

    esac
done


checar() {
    "$@"
    codigo=$?

    if [ "$codigo" -eq 0 ]; then
        printf '%b[ ok ] command completed%b\n' "$green" "$reset"

        if [ -n "$SUCCESS" ]; then
            eval "$SUCCESS"
        fi
    else
        error

        if [ -n "$FAILED" ]; then
            eval "$FAILED"
        fi

        # Execute action for specific exit code
        acao=$(eval "printf '%s' \"\${ON_$codigo}\"")

        if [ -n "$acao" ]; then
            eval "$acao"
        fi
    fi

    # END always runs
    if [ -n "$END" ]; then
        eval "$END"
    fi

    return "$codigo"
}


# No command
if [ "$#" -eq 0 ]; then
    printf '%b[ ERROR ] no command specified%b\n' "$red" "$reset"
    printf '%s\n' "Use 'kmrror --help' for help."
    exit 2
fi


# Execute monitored command
checar "$@"
exit $?
