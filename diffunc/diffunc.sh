#!/usr/bin/env bash

FILENAMES=( "${1}" "${2}" )
shift 2
FUNCTION="${1}"
shift
DIFF_FLAGS="${*:--updrN -x '*.orig' -x '*.rej'}"

echo ${DIFF_FLAGS}
diff "${DIFF_FLAGS}" \
    <(./fseek.sh "${FILENAMES[0]}" "$(./getfunc.sh "${FILENAMES[0]}" "${FUNCTION}")") \
    <(./fseek.sh "${FILENAMES[1]}" "$(./getfunc.sh "${FILENAMES[1]}" "${FUNCTION}")")
