#!/bin/bash

function CHECK_RESULT() {
    actual_result=$1
    expect_result=${2-0}
    mode=${3-0}
    error_log=$4

    if [ -z "$*" ]; then
        echo "Missing parameter error code."
	((exec_result++))
        return 1
    fi

    if [ "$mode" -eq 0 ]; then
        test "$actual_result"x != "$expect_result"x && {
            test -n "$error_log" && echo "$error_log"
            ((exec_result++))
            echo "${BASH_SOURCE[1]} line ${BASH_LINENO[0]}"
            exit 1;
        }
    else
        test "$actual_result"x == "$expect_result"x && {
            test -n "$error_log" && echo "$error_log"
            ((exec_result++))
            echo "${BASH_SOURCE[1]} line ${BASH_LINENO[0]}"
            exit 1;
        }
    fi
    return 0
}