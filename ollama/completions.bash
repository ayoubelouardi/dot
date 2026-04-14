#!/usr/bin/env bash

if [ -z "$BASH_VERSION" ] ; then
  echo "$0: Need bash"
  return 1
fi

command -v jq >&- || { echo "$0: Need jq for model completion" >&2; }
command -v curl >&- || { echo "$0: Need curl for model completion" >&2; }

PROMPT_COMMAND=${PROMPT_COMMAND//_ollama_post_exec ; /}

_OLLAMA_COMMANDS="serve create show run stop pull push signin signout list ps cp rm launch help"
_OLLAMA_QUANTS="Q4_0 Q4_1 Q4_1_F16 Q8_0 Q4_K_S Q4_K_M F16"
_OLLAMA_LAUNCH_AGENTS="claude cline codex droid opencode openclaw pi"

_OLLAMA_SERVE_OPTS="-h --help --nowordwrap"
_OLLAMA_CREATE_OPTS="-h --help --experimental -f --file -q --quantize"
_OLLAMA_SHOW_OPTS="-h --help --license --modelfile --parameters --system --template -v --verbose"
_OLLAMA_RUN_OPTS="-h --help --dimensions --experimental --experimental-websearch --experimental-yolo --format --hidethinking --insecure --keepalive --nowordwrap --think --truncate --verbose --width --height --steps --seed --negative"
_OLLAMA_PULL_OPTS="-h --help --insecure"
_OLLAMA_PUSH_OPTS="-h --help --insecure"
_OLLAMA_DEFAULT_OPTS="-h --help"

_ollama_desc(){
  case "$1" in
    serve|start)  echo "Start Ollama" ;;
    create)       echo "Create a model" ;;
    show)        echo "Show information for a model" ;;
    run)         echo "Run a model" ;;
    stop)        echo "Stop a running model" ;;
    pull)        echo "Pull a model from a registry" ;;
    push)        echo "Push a model to a registry" ;;
    signin)      echo "Sign in to ollama.com" ;;
    signout)     echo "Sign out from ollama.com" ;;
    list|ls)     echo "List models" ;;
    ps)          echo "List running models" ;;
    cp)          echo "Copy a model" ;;
    rm)          echo "Remove a model" ;;
    launch)      echo "Launch the Ollama menu or an integration" ;;
    help)        echo "Help about any command" ;;
    *)           echo "" ;;
  esac
}

_ollama_help(){
  local cmd
  printf "\nUsage: ollama [command]\n\n"
  printf "Available Commands:\n"
  for cmd in $_OLLAMA_COMMANDS ; do
    printf "  %-12s %s\n" "$cmd" "$(_ollama_desc "$cmd")"
  done
  printf "\nFlags:\n"
  printf "  %-12s %s\n" "-h, --help" "help for ollama"
  printf "  %-12s %s\n" "--nowordwrap" "Don't wrap words to the next line automatically"
  printf "  %-12s %s\n" "--verbose" "Show timings for response"
  printf "  %-12s %s\n" "-v, --version" "Show version information"
  printf "\nUse \"ollama [command] --help\" for more information about a command.\n"
}

_OLLAMA_MODELS=""
_OLLAMA_LIBRARY=""
_OLLAMA_MODEL_TTL=${_OLLAMA_MODEL_TTL-300}
_OLLAMA_LIBRARY_TTL=${_OLLAMA_LIBRARY_TTL-3600}
_OLLAMA_QUANTS_TTL=${_OLLAMA_QUANTS_TTL-300}
_OLLAMA_LIBRARY_LIMIT=${_OLLAMA_LIBRARY_LIMIT-10}
_OLLAMA_LIBRARY_SORT=${_OLLAMA_LIBRARY_SORT-newest}
_OLLAMA_MODELS_TIMESTAMP=0
_OLLAMA_LIBRARY_TIMESTAMP=0

_ollama_fetch_models(){
  _OLLAMA_MODELS="$(curl -s ${OLLAMA_HOST-localhost:11434}/api/tags 2>/dev/null | jq -r '.models[].name' 2>/dev/null)"
}

_ollama_maybe_fetch_models(){
  [ $[ $(date +%s) - ${_OLLAMA_MODELS_TIMESTAMP-0} ] -lt $_OLLAMA_MODEL_TTL ] && return 0
  _ollama_fetch_models
  _OLLAMA_MODELS_TIMESTAMP=$(date +%s)
}

_ollama_complete_models(){
  [ -z "$_OLLAMA_MODELS" ] && return 0
  local -a complete
  read -a complete <<< $(tr '\n' ' ' <<< $_OLLAMA_MODELS)
  compgen -W "${complete[*]}" -- "$1"
}

_ollama_complete_library(){
  [ -z "$_OLLAMA_LIBRARY" ] && return 0
  local cur="${COMP_WORDS[COMP_CWORD]}"
  compgen -W "$(echo $_OLLAMA_LIBRARY | jq -r 'keys[]' 2>/dev/null)" -- "$cur"
}

_ollama(){
  local cur prev
  COMPREPLY=()
  cur=${COMP_WORDS[COMP_CWORD]}
  prev=${COMP_WORDS[COMP_CWORD-1]}
  _ollama_maybe_fetch_models

  if [ ${COMP_CWORD} -eq 1 ]; then
    COMPREPLY=( $(compgen -W "$_OLLAMA_COMMANDS" -- "$cur") )
    return 0
  fi

  if [[ "$cur" == -* ]]; then
    case "${COMP_WORDS[1]}" in
      serve|start)  COMPREPLY=( $(compgen -W "$_OLLAMA_SERVE_OPTS" -- "$cur") ); return 0 ;;
      create)        COMPREPLY=( $(compgen -W "$_OLLAMA_CREATE_OPTS" -- "$cur") ); return 0 ;;
      show)          COMPREPLY=( $(compgen -W "$_OLLAMA_SHOW_OPTS" -- "$cur") ); return 0 ;;
      run)           COMPREPLY=( $(compgen -W "$_OLLAMA_RUN_OPTS" -- "$cur") ); return 0 ;;
      pull)          COMPREPLY=( $(compgen -W "$_OLLAMA_PULL_OPTS" -- "$cur") ); return 0 ;;
      push)         COMPREPLY=( $(compgen -W "$_OLLAMA_PUSH_OPTS" -- "$cur") ); return 0 ;;
      stop|signin|signout|list|ls|ps|cp|rm|launch|help)
                      COMPREPLY=( $(compgen -W "$_OLLAMA_DEFAULT_OPTS" -- "$cur") ); return 0 ;;
    esac
    return 0
  fi

  case "$prev" in
    --format)     COMPREPLY=( $(compgen -W "json" -- "$cur") ); return 0 ;;
    --think)      COMPREPLY=( $(compgen -W "true false high medium low" -- "$cur") ); return 0 ;;
    --quantize)   COMPREPLY=( $(echo "$_OLLAMA_QUANTS" | tr ' ' '\n' | grep -i "^$cur") ); return 0 ;;
    --file|-f)    COMPREPLY=( $(compgen -f -- "$cur") ); return 0 ;;
    --model)      _ollama_complete_models "$cur"; return 0 ;;
    --keepalive|--dimensions|--width|--height|--steps|--seed|--negative|--negative)
                      return 0 ;;
  esac

  case "${COMP_WORDS[1]}" in
    serve|start|signin|signout|help)  COMPREPLY=() ;;
    create|show|run|stop|push|cp|rm|list|ls|ps)
      _ollama_complete_models "$cur" ;;
    pull)
      _ollama_complete_library "$cur" ;;
    launch)
      COMPREPLY=( $(compgen -W "$_OLLAMA_LAUNCH_AGENTS" -- "$cur") )
  esac
}

_ollama_post_exec(){
  [ "$_OLLAMA_FLUSH_MODELS_CACHE" = 1 ] && {
    _OLLAMA_MODELS=""
    _OLLAMA_MODELS_TIMESTAMP=0
    _OLLAMA_FLUSH_MODELS_CACHE=0
  }
  [ "$_OLLAMA_FLUSH_LIBRARY_CACHE" = 1 ] && {
    _OLLAMA_LIBRARY=""
    _OLLAMA_LIBRARY_TIMESTAMP=0
    _OLLAMA_FLUSH_LIBRARY_CACHE=0
  }
}

PROMPT_COMMAND="_ollama_post_exec ; $PROMPT_COMMAND"

_ollama_real() {
  command ollama "$@"
}

ollama() {
  case "$1" in
    help|"")  _ollama_help ;;
    *)         _ollama_real "$@" ;;
  esac
}

complete -o bashdefault -o default -o nospace -F _ollama ollama 2>/dev/null \
  || complete -o default -o nospace -F _ollama ollama
