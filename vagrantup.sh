#!/bin/bash

set +e
set -u

test -r ~/.vagrantenv && cp -p ~/.vagrantenv .
source ./.vagrantenv

cmd=up
test $# -gt 0 && cmd=$1 && shift

exec vagrant ${cmd} "$@"
