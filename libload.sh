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
_DOTS='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'

# @brief hole loader states
_HOLE='⣾⣽⣻⢿⡿⣟⣯⣷'

# @brief wave loader states
_WAVE='▁▂▃▄▅▆▇██▇▆▅▄▃▂▁'

# @brief jobs' queue
declare -A _JOBS
# @brief jobs' args
declare -A _JOBS_ARGS
# @brief jobs' loader
declare -A _JOBS_LOADER


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


# @brief synchronously run job with specified loder
# @param[in] 1: name  of the variable with loader states
# @param[in] 2+: args
# @return job's exit code
_load_loader_sync()
{
	# @brief loader states
	local loader="$1"; shift
	# @brief number of loader states
	local loader_nr="${#loader}"
	# @brief iterator
	local i=0
	# @brief exit status
	local rc
	# @brief job pid
	local jobpid
	# @brief exit print
	local esign="${_GRN}${_BLD}\u2713${_RST}"

	coproc { "$@"; }
	jobpid="${COPROC_PID}"
	while _is_job_running "${jobpid}"; do
		while read -u "${COPROC[0]}" -t 0 line; do
			read -u "${COPROC[0]}" -e line
			echo "${line}"
		done
		tput sc
		printf '%s %s ' "${loader:${i}:1}" "$@"
		i="$(((i + 1) % loader_nr))"
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


# @brief synchronously run job with dots loader
# @param[in] @: args
# @return job's exit code
load_dots_sync()
{
	_load_loader_sync "${_DOTS}" "$@"
}


# @brief synchronously run job with hole loader
# @param[in] @: args
# @return job's exit code
load_hole_sync()
{
	_load_loader_sync "${_HOLE}" "$@"
}


# @brief synchronously run job with wave loader
# @param[in] @: args
# @return job's exit code
load_wave_sync()
{
	_load_loader_sync "${_WAVE}" "$@"
}


# @brief starts an asynchronous job with the specified loader
# @param[in] 1: loader
# @param[in] 2+: args
# @return 0 on success
_load_loader_async()
{
	# @brief loader states
	local loader="$1"; shift
	# @brief job's pid
	local jobpid
	{ "$@" & } 2>/dev/null
	jobpid="$!"
	_JOBS_ARGS["${jobpid}"]="$(printf '%s ' "$@")"
	_JOBS["${jobpid}"]='-1'
	_JOBS_LOADER["${jobpid}"]="${loader}"
}


# @brief starts an asynchronous job with dots loader
# @param[in] @: args
# @return 0 on success
load_dots_async()
{
	_load_loader_async "${_DOTS}" "$@"
}


# @brief starts an asynchronous job with hole loader
# @param[in] @: args
# @return 0 on success
load_hole_async()
{
	_load_loader_async "${_HOLE}" "$@"
}


# @brief starts an asynchronous job with wave loader
# @param[in] @: args
# @return 0 on success
load_wave_async()
{
	_load_loader_async "${_WAVE}" "$@"
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
	# @brief loader states
	local loader
	# @brief loader number of states
	local loader_nr

	tput sc
	while ! "${should_exit}"; do
		tput rc
		tput el
		tput sc
		should_exit='true'
		for jobpid in "${!_JOBS[@]}"; do
			loader="${_JOBS_LOADER[${jobpid}]}"
			loader_nr="${#loader}"
			if [ "${_JOBS[${jobpid}]}" -lt 0 ] && _is_job_running "${jobpid}"; then
				printf '%s %s\n' "${loader:$((i % loader_nr)):1}" "${_JOBS_ARGS[${jobpid}]}"
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
		i="$((i + 1))"
		sleep 0.1s
	done

	# clean jobs queue
	declare -gA _JOBS
	declare -gA _JOBS_ARGS
	declare -gA _JOBS_LOADER
}
