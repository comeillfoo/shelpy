#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# @file
# @brief Logging helpers

if [ 'loaded' == "${__liblog_sh__:+loaded}" ]; then
	return 0
fi
__liblog_sh__='loaded'


# @brief log message with the specified level
# @param[in] 1: log level
# @param[in] 2: message format
# @param[in] 3+: format arguments
# @param[out] &2: printed message
# @return 0 on success
log_log()
{
	local level="$1"
	local fmt="$2"
	shift 2
	printf "[%8s]: ${fmt}" "${level}" "$@" >&2
}


# @brief log an emergency condition; the system is probably dead
# @param[in] 1: message format
# @param[in] 2+: format arguments
# @param[out] &2: printed message
# @return 0 on success
log_emerg()
{
	log_log 'EMERG' "$@"
}


# @brief log a problem that requires immediate attention
# @param[in] 1: message format
# @param[in] 2+: format arguments
# @param[out] &2: printed message
# @return 0 on success
log_alert()
{
	log_log 'ALERT' "$@"
}


# @brief log a critical condition
# @param[in] 1: message format
# @param[in] 2+: format arguments
# @param[out] &2: printed message
# @return 0 on success
log_crit()
{
	log_log 'CRITICAL' "$@"
}


# @brief log a error
# @param[in] 1: message format
# @param[in] 2+: format arguments
# @param[out] &2: printed message
# @return 0 on success
log_err()
{
	log_log 'ERROR' "$@"
}


# @brief log a warning
# @param[in] 1: message format
# @param[in] 2+: format arguments
# @param[out] &2: printed message
# @return 0 on success
log_warn()
{
	log_log 'WARN' "$@"
}


# @brief log a normal, but perhaps noteworthy, condition
# @param[in] 1: message format
# @param[in] 2+: format arguments
# @param[out] &2: printed message
# @return 0 on success
log_notice()
{
	log_log 'NOTICE' "$@"
}


# @brief log an informational message
# @param[in] 1: message format
# @param[in] 2+: format arguments
# @param[out] &2: printed message
# @return 0 on success
log_info()
{
	log_log 'INFO' "$@"
}


# @brief log a debug message
# @param[in] 1: message format
# @param[in] 2+: format arguments
# @param[out] &2: printed message
# @return 0 on success
log_debug()
{
	log_log 'DEBUG' "$@"
}

