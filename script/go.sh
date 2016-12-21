#!/usr/bin/env bash
# test shell to run resty test
export PATH=${RESTY_PREFIX}/nginx/sbin:$PATH

exec prove "$@"
