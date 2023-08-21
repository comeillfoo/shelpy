#!/usr/bin/env bash

FILENAME=${1}
shift
START="${1-1:2}"
END="${2:-3:4}"

S_R=${START%:*}
S_C=${START##*:}
E_R=${END%:*}
E_C=${END##*:}
NR="$(wc -l < "${FILENAME}")"
LAST_LENGTH=$(sed "${E_R}q;d" "${FILENAME}" | wc -m)
REST=$((LAST_LENGTH - E_C))


echo "${S_R}:${S_C} ${E_R}:${E_C} ${NR}:${LAST_LENGTH}"
if [ "${S_R}" -le 0 ] || [ "${S_R}" -gt "${E_R}" ] \
    || [ "${S_R}" -gt "${NR}" ] || [ "${REST}" -lt 0 ]; then
    exit 22
fi

sed -n "${S_R},${E_R}p" "${FILENAME}" \
    | sed "0,/^.\{${S_C}\}/{s/^.\{${S_C}\}//}" - \
    | sed "s/.\{${REST}\}$//g" -
