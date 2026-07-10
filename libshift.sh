#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# @file
# @brief Tracking shifts

if [ 'loaded' == "${__libshift_sh__:+loaded}" ]; then
  return 0
fi
__libshift_sh__='loaded'

# @brief the timestamp shift start
SHIFT_START_TIME=''

# @brief just a stub, redefine in ur scripts
# @return 0 on success
shift_prepare() {
    :
}

# @brief starts shift
# @return 0 on success
shift_start() {
    SHIFT_START_TIME="$(date '+%s')"
    printf 'Shift started at: %s\n' \
        "$(date -d "@${SHIFT_START_TIME}" --iso-8601=seconds)"
    shift_prepare
}

# @brief just a stub for cleanup, redefine in ur scripts
# @return 0 on success
shift_cleanup() {
    :
}

# @brief ends shift
# @return 0 on success
shift_end() {
    local shift_stop_time="$(date '+%s')"
    printf 'Shift started at: %s\nShift ended at: %s\nLasted for: %(%H:%M:%S)T\n' \
        "$(date -d "@${SHIFT_START_TIME}" --iso-8601=seconds)" \
        "$(date -d "@${shift_stop_time}" --iso-8601=seconds)" \
        "$((shift_stop_time - SHIFT_START_TIME))"
    shift_cleanup
}
