_ollama() {
  local cur prev cmd opts commands integrations
  local models

  COMPREPLY=()
  cur="${COMP_WORDS[COMP_CWORD]}"
  prev="${COMP_WORDS[COMP_CWORD-1]}"
  cmd="${COMP_WORDS[1]}"

  commands="serve start create show run stop pull push signin signout list ls ps cp rm launch help"
  integrations="claude cline codex droid opencode openclaw clawdbot moltbot pi"

  _ollama_models() {
    local models
    models=$(ollama list 2>/dev/null | awk 'NR>1 {print $1}')
    COMPREPLY=( $( compgen -W "${models}" -- "${cur}" ) )
  }

  if [ "${#COMP_WORDS[@]}" -eq 2 ]; then
    case "${cur}" in
      -*)
        COMPREPLY=( $( compgen -W "--help --version --nowordwrap --verbose -h -v" -- "${cur}" ) )
        return 0
        ;;
      *)
        COMPREPLY=( $( compgen -W "${commands}" -- "${cur}" ) )
        return 0
        ;;
    esac
  fi

  case "${cmd}" in
    help)
      COMPREPLY=( $( compgen -W "${commands}" -- "${cur}" ) )
      return 0
      ;;

    launch)
      case " ${integrations} " in
        *" ${prev} "*)
          case "${cur}" in
            -*)
              opts="-h -y --help --yes --config --model"
              COMPREPLY=( $( compgen -W "${opts}" -- "${cur}" ) )
              return 0
              ;;
            *)
              COMPREPLY=( $( compgen -W "-h -y --help --yes --config --model" -- "${cur}" ) )
              return 0
              ;;
          esac
          ;;
      esac

      case "${prev}" in
        --model)
          return 0
          ;;
      esac

      case "${cur}" in
        -*)
          opts="-h -y --help --yes --config --model"
          COMPREPLY=( $( compgen -W "${opts}" -- "${cur}" ) )
          return 0
          ;;
        *)
          COMPREPLY=( $( compgen -W "${integrations}" -- "${cur}" ) )
          return 0
          ;;
      esac
      ;;

    serve|start)
      case "${cur}" in
        -*)
          COMPREPLY=( $( compgen -W "-h --help" -- "${cur}" ) )
          return 0
          ;;
      esac
      return 0
      ;;

    create)
      case "${prev}" in
        -f|--file)
          COMPREPLY=( $( compgen -f -- "${cur}" ) )
          return 0
          ;;
      esac

      case "${cur}" in
        -*)
          opts="-h -f -q --help --experimental --file --quantize"
          COMPREPLY=( $( compgen -W "${opts}" -- "${cur}" ) )
          return 0
          ;;
      esac
      return 0
      ;;

    show)
      if [ "${COMP_CWORD}" -eq 2 ] && [ "${prev}" = "show" ]; then
        _ollama_models
        return 0
      fi

      case "${cur}" in
        -*)
          opts="-h -v --help --verbose --license --modelfile --parameters --system --template"
          COMPREPLY=( $( compgen -W "${opts}" -- "${cur}" ) )
          return 0
          ;;
      esac
      return 0
      ;;

    run)
      if [ "${COMP_CWORD}" -eq 2 ] && [ "${prev}" = "run" ]; then
        _ollama_models
        return 0
      fi

      case "${prev}" in
        --format)
          COMPREPLY=( $( compgen -W "json" -- "${cur}" ) )
          return 0
          ;;
        --think)
          COMPREPLY=( $( compgen -W "true false high medium low" -- "${cur}" ) )
          return 0
          ;;
      esac

      case "${cur}" in
        -*)
          opts="-h --help --dimensions --experimental --experimental-websearch --experimental-yolo --format --hidethinking --insecure --keepalive --nowordwrap --think --truncate --verbose --width --height --steps --seed --negative"
          COMPREPLY=( $( compgen -W "${opts}" -- "${cur}" ) )
          return 0
          ;;
      esac
      return 0
      ;;

    stop|cp|rm|list|ls|signin|signout)
      case "${cmd}" in
        stop|cp|rm|list|ls)
          if [ "${COMP_CWORD}" -eq 2 ]; then
            _ollama_models
            return 0
          fi
          ;;
      esac

      case "${cur}" in
        -*)
          COMPREPLY=( $( compgen -W "-h --help" -- "${cur}" ) )
          return 0
          ;;
      esac
      return 0
      ;;

    pull|push)
      case "${cur}" in
        -*)
          COMPREPLY=( $( compgen -W "-h --help --insecure" -- "${cur}" ) )
          return 0
          ;;
      esac
      return 0
      ;;
  esac

  return 0
}

complete -o bashdefault -o default -o nospace -F _ollama ollama 2>/dev/null \
	|| complete -o default -o nospace -F _ollama ollama
