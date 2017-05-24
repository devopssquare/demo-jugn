#!/bin/bash

set +e
set -u

test -r ~/.vagrantenv && cp -p ~/.vagrantenv .

exec vagrant up "$@"
