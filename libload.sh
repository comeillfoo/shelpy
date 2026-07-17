#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# @file
# @brief Pretty loaders

if [ 'loaded' == "${__libload_sh__:+loaded}" ]; then
  return 0
fi
__libload_sh__='loaded'

_RED="$(tput setaf 1)"
_GRN="$(tput setaf 2)"
_BLD="$(tput bold)"
_RST="$(tput sgr0)"

# @brief dots loader states
_DOTS=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
# @brief number of loader states
_DOTS_NR="${#_DOTS[@]}"

# @brief jobs' queue
declare -A _JOBS
# @brief jobs' args
declare -A _JOBS_ARGS


# @brief tests if process still running
# @param[in] 1: process's pid
# @return 0 if running
_is_job_running()
{
	kill -0 "$1" &>/dev/null
}


# @brief waits for process exit code
# @param[in] 1: process's pid
# @return process's exit code
_job_exit_code()
{
	wait "$1" &>/dev/null
}


# @brief synchronously run job with dots loader
# @param[in] @: args
# @return job's exit code
load_dots_sync()
{
	# @brief iterator
	local i=0
	# @brief exit status
	local rc
	# @brief job pid
	local jobpid
	# @brief exit print
	local esign="${_GRN}${_BLD}\u2713${_RST}"

	{ "$@" & } 2>/dev/null
	jobpid="$!"
	while _is_job_running "${jobpid}"; do
		tput sc
		printf '%s %s ' "${_DOTS[${i}]}" "$@"
		i="$(((i + 1) % _DOTS_NR))"
		sleep 0.1s
		tput rc
		tput el
	done
	_job_exit_code "${jobpid}"
	rc="$?"

	if [ "${rc}" -ne 0 ]; then esign="${_RED}${_BLD}\u2717${_RST}"; fi
	printf '\r%b ' "${esign}"
	printf '%s ' "$@"
	echo
	return "${rc}"
}


# @brief starts an asynchronous job with dots loader
# @param[in] @: args
# @return 0 on success
load_dots_async()
{
	# @brief job's pid
	local jobpid
	{ "$@" & } 2>/dev/null
	jobpid="$!"
	_JOBS_ARGS["${jobpid}"]="$(printf '%s ' "$@")"
	_JOBS["${jobpid}"]='-1'
}


# @brief monitors asynchronous jobs' status
# @return 0 if all jobs succeed
load_monitor()
{
	# @brief job pid
	local jobpid
	# @brief loader states iterator
	local i=0
	# @brief should exit
	local should_exit='false'
	# @brief exit print
	local esign

	tput sc
	while ! "${should_exit}"; do
		tput rc
		tput el
		tput sc
		should_exit='true'
		for jobpid in "${!_JOBS[@]}"; do
			if [ "${_JOBS[${jobpid}]}" -lt 0 ] && _is_job_running "${jobpid}"; then
				# TODO: print args
				printf '%s %s\n' "${_DOTS[${i}]}" "${_JOBS_ARGS[${jobpid}]}"
				should_exit='false'
				continue
			fi
			if [ "${_JOBS[${jobpid}]}" -lt 0 ]; then
				_job_exit_code "${jobpid}"
				_JOBS["${jobpid}"]="$?"
			fi

			esign="${_GRN}${_BLD}\u2713${_RST}"
			if [ "${_JOBS[${jobpid}]}" -ne 0 ]; then esign="${_RED}${_BLD}\u2717${_RST}"; fi
			printf '%b %s\n' "${esign}" "${_JOBS_ARGS[${jobpid}]}"
		done
		i="$(((i + 1) % _DOTS_NR))"
		sleep 0.1s
	done

	# clean jobs queue
	declare -gA _JOBS
	declare -gA _JOBS_ARGS
}
