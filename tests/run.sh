#!/bin/sh

# Thanks to <https://github.com/thinca/vim-themis>, zlib License

log() { echo "$*" 1>&2; }

: "${EXRC_RUNTIME:=$(dirname "$(dirname "$(realpath "$0")")")}"
: "${EXRC_VIM:=vim}"
: "${EXRC_ARGS:=-e -s}"
: "${EXRC_LOG_FILE:=test.log}"

export EXRC_LOG_FILE
export EXRC_CI=1

script="$EXRC_RUNTIME/tests/run.vim"

log ": \"$EXRC_VIM\" -u NONE -i NONE -n -N $EXRC_ARGS -c \"source $script\""
"$EXRC_VIM" -u NONE -i NONE -n -N $EXRC_ARGS -c "source $script"
res=$?

cat "$EXRC_LOG_FILE" || exit 2
echo
[ $res -ne 0 ] && exit 1
exit 0
