#!/bin/bash
#
#
WORK_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

docker build -t nurl_test .
docker run -it --rm -v ${WORK_DIR}/t:/data/openresty/nginx/t nurl_test ./go.sh  -v t/*.t
