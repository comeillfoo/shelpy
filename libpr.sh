#!/usr/bin/env bash

if [ -n "${_LIB_PR_SH_}" ]; then
	return
fi
readonly _LIB_PR_SH_=1


_pr_common()
{
	echo -e "$(printf '%6s' "${1}"):\t${2}" 1>&2
}

_PR_LEVELS=(emerg alert crit err warn notice info debug)

# define functions
for _pr_level in "${_PR_LEVELS[@]}"; do
	eval "pr_${_pr_level}()
	{
		_pr_common ${_pr_level^^} \${1}
	}
	"
done
