#!/bin/bash

# TAB completion for ollama CLI.
#
# Install in /etc/bash_completion.d/, or in your home dir
# and `source <this file>` in your .bashrc.
#
# Needs `jq` and `curl`.
#
# Install `pup` [https://github.com/ericchiang/pup] to
# get ollama library completion.
#
# A few environment variables control processing:
#   _OLLAMA_MODEL_TTL    
#       Minimum number of seconds between model fetches from the
#       ollama server. Default 300s.
#   _OLLAMA_LIBRARY_TTL
#       Minimum number of seconds between model fetches from the
#       ollama library.  Default 3600s.
#   _OLLAMA_QUANTS_TTL
#       Minimum number of seconds between quant fetches from the
#       ollama library.  Default 300s.
#   _OLLAMA_LIBRARY_LIMIT
#       Maximum number of models to retrieve from the ollama
#       library.  Default 10.
#   _OLLAMA_LIBRARY_SORT
#       Sort order for models fetched from the ollama library.
#       One of [newest popular featured].  Default newest.
#   _OLLAMA_QUANTS
#       The list of quantizations used for completion for
#       `ollama create --quantize`.

if [ -z "$BASH_VERSION" ] ; then
  echo "$0: Need bash"
  return 1
fi
if ! command -v jq >&- ; then
  echo "$0: Need jq for model completion"
  return 1
fi
if ! command -v curl >&- ; then
  echo "$0: Need curl for model completion"
  return 1
fi

# restore post exec hook
PROMPT_COMMAND=${PROMPT_COMMAND//_ollama_post_exec ; /}

_OLLAMA_MODELS=""
_OLLAMA_LIBRARY=""
_OLLAMA_MODEL_TTL=${_OLLAMA_MODEL_TTL-300}
_OLLAMA_LIBRARY_TTL=${_OLLAMA_LIBRARY_TTL-3600}
_OLLAMA_QUANTS_TTL=${_OLLAMA_QUANTS_TTL-300}
_OLLAMA_LIBRARY_LIMIT=${_OLLAMA_LIBRARY_LIMIT-10}
_OLLAMA_LIBRARY_SORT=${_OLLAMA_LIBRARY_SORT-newest}     # newest popular featured
_OLLAMA_MODELS_TIMESTAMP=0
_OLLAMA_LIBRARY_TIMESTAMP=0
_OLLAMA_QUANTS_ALL=(
    F32 F16 BF16
    Q2_K Q2_K_S
    Q3_K_S Q3_K_M Q3_K_L
    Q4_0 Q4_1 Q4_1_F16 Q4_K_S Q4_K_M
    Q5_0 Q5_1 Q5_K_S Q5_K_M
    Q6_K
    Q8_0
    IQ1_S IQ1_M
    IQ2_XXS IQ2_XS IQ2_S IQ2_M
    IQ3_XXS IQ3_XS IQ3_S
    IQ4_NL IQ4_XS
)
# The above is all that is supported, but just use a select few for completion.
#_OLLAMA_QUANTS=${_OLLAMA_QUANTS-${_OLLAMA_QUANTS_ALL[@]}}
_OLLAMA_QUANTS=${_OLLAMA_QUANTS-Q4_0 Q4_1 Q4_1_F16 Q8_0 Q4_K_S Q4_K_M F16}

_ollama_fetch_models(){
  _OLLAMA_MODELS="$(curl -s ${OLLAMA_HOST-localhost:11434}/api/tags | jq -r '.models[].name')"
}

_ollama_maybe_fetch_models(){
  [ $[ $(date +%s) - ${_OLLAMA_MODELS_TIMESTAMP-0} ] -lt $_OLLAMA_MODEL_TTL ] && return 0
  _ollama_fetch_models
  _OLLAMA_MODELS_TIMESTAMP=$(date +%s)
}

_ollama_fetch_library_models(){
  ! command -v pup >&- && return 0
  _OLLAMA_LIBRARY=$(echo "{$(echo $(curl -s https://ollama.com/library?sort=${_OLLAMA_LIBRARY_SORT-newest} | 
      pup '#repo ul li a' | 
      sed -ne 's@^<a href="/library/\([^"]*\)".*@"\1:":{"base":"/library/\1"}@p' |
      head -${_OLLAMA_LIBRARY_LIMIT-10}) |
      tr ' ' ,)}")
}

_ollama_maybe_fetch_library_models(){
  [ $[ $(date +%s) - ${_OLLAMA_LIBRARY_TIMESTAMP-0} ] -lt $_OLLAMA_LIBRARY_TTL ] && return 0
  _ollama_fetch_library_models
  _OLLAMA_LIBRARY_TIMESTAMP=$(date +%s)
}

_ollama_maybe_fetch_library(){
  local model completions timestamp library quants
  ! command -v pup >&- && return 0
  [ -z "$_OLLAMA_LIBRARY" ] && {
    _ollama_maybe_fetch_library_models
    [ -z "$_OLLAMA_LIBRARY" ] && return 0
  }
  # we might have to fetch quants.  in the case where the user has typed
  # enough of the model name to uniquely identify it, we can do the fetch.
  model=${COMP_LINE:0:COMP_POINT}
  model=${model##* }
  [[ "$model" == *:* ]] && model=${model%%:*}: || model=${model%%:*}
  completions=( $(compgen -W "$(jq -rn "$_OLLAMA_LIBRARY|keys|.[]")" -- "$model") )
  [ ${#completions[*]} -ne 1 ] && return 0
  model="${completions[0]}"
  # skip if quants were retrieved recently
  timestamp="$(jq -rn "$_OLLAMA_LIBRARY|.\"$model\".timestamp")"
  [ -z "$timestamp" -o "$timestamp" == null ] && timestamp=0
  [ $[ $(date +%s) - $timestamp ] -lt $_OLLAMA_QUANTS_TTL ] && return 0
  library="$(jq -rn "$_OLLAMA_LIBRARY|.\"$model\".base")"
  [ -z "$library" -o "$library" == null ] && return 0
  quants="$(echo $(curl -s https://ollama.com${library}/tags | pup 'section div div div div div div text{}'))"
  [ -z "$quants" -o "$quants" == null ] && return 0
  # add the quants prefixed by the model
  quants=$(eval echo $model{${quants// /,}})
  _OLLAMA_LIBRARY=$(jq -cn "$_OLLAMA_LIBRARY*{\"$model\":{\"quants\":\"$quants\",\"timestamp\":$(date +%s)}}")
}

# ":" is a word break character by default, which messes
# completion attempts for models with tags.  so here we
# massage the potential matches so that bash presents the
# appropriate words.  expects an array of completion
# alternatives in $_OLLAMA_COMPLETE.
_ollama_massage_completions(){
  local comp model tmp
  comp=${COMP_LINE:0:COMP_POINT}
  comp=${comp##* }
  [[ "$comp" != *:* ]] && return 0
  model=${comp%:*}:
  tmp=()
  for i in ${_OLLAMA_COMPLETE[*]} ; do
    [ "${i:0:${#comp}}" == "$comp" ] && {
      t=${i:${#model}}
      [ -n "$t" ] && tmp+=($t)
    }
  done
  _OLLAMA_COMPLETE=("${tmp[@]}")
}

_ollama_complete_models(){
  [ -z "$_OLLAMA_MODELS" ] && return 0
  read -a _OLLAMA_COMPLETE <<< $(tr '\n' ' ' <<< $_OLLAMA_MODELS)
  _ollama_massage_completions
  compgen -W "${_OLLAMA_COMPLETE[*]}" -- "$1"
}

_ollama_complete_library(){
  local model
  [ -z "$_OLLAMA_LIBRARY" ] && return 0
  model=${COMP_LINE:0:COMP_POINT}
  model=${model##* }
  [[ -z "$model" || "$model" != *:* ]] && {
    compgen -W "$(jq -rn "$_OLLAMA_LIBRARY|keys|.[]")" -- "$model"
    return 0
  }
  model="${model%%:*}:"
  _OLLAMA_COMPLETE=( $(jq -rn "$_OLLAMA_LIBRARY|.\"$model\".quants") )
  _ollama_massage_completions
  compgen -W "${_OLLAMA_COMPLETE[*]}" -- "$1"
}

_ollama() {
  local word verb
  _ollama_maybe_fetch_models
  for word in ${COMP_WORDS[@]:1} ; do
    [[ "$word" != -* ]] && {
      verb="$word"
      break
    }
  done
  [ "$verb" == "$2" -a "${COMP_LINE:${#COMP_LINE}-1}" != " " ] && verb="*"
  case "$verb" in
    serve|start)
            COMPREPLY=( $(compgen -W "--help" -- "$2") ) ;
            ;;
    create)
            if [ "${COMP_WORDS[COMP_CWORD-1]}" == --quantize ] ; then
              COMPREPLY=( $(echo "$_OLLAMA_QUANTS" | tr ' ' '\n' | grep -i "^$2") ) ;
            elif [ "${COMP_WORDS[COMP_CWORD-1]}" == --file ] ; then
              COMPREPLY=( $(compgen -f -o filenames -- "$2") ) ;
            else
              COMPREPLY=( $(compgen -W "--help --file --quantize" -- "$2") ) ;
            fi
            _OLLAMA_FLUSH_MODELS_CACHE=1
            ;;
    show)
            if [ "${2:0:1}" == - ] ; then
              COMPREPLY=( $(compgen -W "--help --license --template --modelfile --parameters --system" -- "$2") ) ;
            else
              COMPREPLY=( $(_ollama_complete_models "$2") ) ;
            fi
            ;;
    run)
            if [ "${2:0:1}" == - ] ; then
              COMPREPLY=( $(compgen -W "--help --format --insecure --keepalive --nowordwrap --verbose" -- "$2") ) ;
            elif [ "${COMP_WORDS[COMP_CWORD-1]}" == --format ] ; then
              COMPREPLY=( $(compgen -W "json" -- "$2") ) ;
            else
              COMPREPLY=( $(_ollama_complete_models "$2") ) ;
            fi
            ;;
    stop)
            if [ "${2:0:1}" == - ] ; then
              COMPREPLY=( $(compgen -W "--help" -- "$2") ) ;
            else
              COMPREPLY=( $(_ollama_complete_models "$2") ) ;
            fi
            ;;

    pull)
            if [ "${2:0:1}" == - ] ; then
              COMPREPLY=( $(compgen -W "--help --insecure" -- "$2") ) ;
            else
              _ollama_maybe_fetch_library
              COMPREPLY=( $(_ollama_complete_library "$2") ) ;
            fi
            _OLLAMA_FLUSH_MODELS_CACHE=1
            ;;
    push)
            if [ "${2:0:1}" == - ] ; then
              COMPREPLY=( $(compgen -W "--help --insecure" -- "$2") ) ;
            else
              COMPREPLY=( $(_ollama_complete_models "$2") ) ;
            fi
            ;;
    list|ls)
            if [ "${2:0:1}" == - ] ; then
              COMPREPLY=( $(compgen -W "--help" -- "$2") ) ;
            else
              COMPREPLY=( $(_ollama_complete_models "$2") ) ;
            fi
            ;;
    ps)
            if [ "${2:0:1}" == - ] ; then
              COMPREPLY=( $(compgen -W "--help" -- "$2") ) ;
            else
              COMPREPLY=( $(_ollama_complete_models "$2") ) ;
            fi
            ;;
    cp)
            if [ "${2:0:1}" == - ] ; then
              COMPREPLY=( $(compgen -W "--help" -- "$2") ) ;
            else
              COMPREPLY=( $(_ollama_complete_models "$2") ) ;
            fi
            _OLLAMA_FLUSH_MODELS_CACHE=1
            ;;
    rm)
            if [ "${2:0:1}" == - ] ; then
              COMPREPLY=( $(compgen -W "--help" -- "$2") ) ;
            else
              COMPREPLY=( $(_ollama_complete_models "$2") ) ;
            fi
            _OLLAMA_FLUSH_MODELS_CACHE=1
            ;;
    help)
            COMPREPLY=( $(compgen -W "serve create show run stop pull push list ps cp rm" -- "$2") )
            ;;
    *)      COMPREPLY=( $(compgen -W "serve create show run stop pull push list ps cp rm help" -- "$2") )
            ;;
  esac
}

_ollama_post_exec(){
  [ "$_OLLAMA_FLUSH_MODELS_CACHE" == 1 ] && {
    _OLLAMA_MODELS=""
    _OLLAMA_MODELS_TIMESTAMP=0
    _OLLAMA_FLUSH_MODELS_CACHE=0
  }
  [ "$_OLLAMA_FLUSH_LIBRARY_CACHE" == 1 ] && {
    _OLLAMA_LIBRARY=""
    _OLLAMA_LIBRARY_TIMESTAMP=0
    _OLLAMA_FLUSH_LIBRARY_CACHE=0
  }
}

PROMPT_COMMAND="_ollama_post_exec ; $PROMPT_COMMAND"

complete -F _ollama ollama
