#!/bin/bash

set -eu

dir=`dirname $0`

basedir="${dir}/.."

modulename=`dirname $basedir`
modulename=`dirname $modulename`
modulename=`basename $modulename`
cat<<EOM
======================================================================
Installing "${modulename}"
======================================================================
EOM

if test -r /vagrant/.vagrantenv
   then echo "Loading Vagrant environment"
        source /vagrant/.vagrantenv
fi

sudo=/usr/bin/sudo
if test -x $sudo
   then sudo="$sudo -E"
   else sudo=
fi

# Ensure that there is a fresh Jenkins log file - later we will check for SEVERE messages
test -r /etc/logrotate.d/jenkins && sudo logrotate -f /etc/logrotate.d/jenkins

test -d /etc/puppet/modules/jenkins || $sudo puppet module install rtyler/jenkins

$sudo puppet apply ${basedir}/puppet/init.pp

# First check whether there are SEVERE errors during Jenkins restart
if egrep '^SEVERE: ' /var/log/jenkins/jenkins.log; then
    echo
    echo Stopping Jenkins execution due to installation errors >&2
    exit 1
fi

set +u # Avoid hassles if $TEST_SKIP is not set!
if test -z "${TEST_SKIP}" -o "${TEST_SKIP}" != "false"
   then sleeptime=60
        echo "Sleeping ${sleeptime}s until Jenkins is up and running"
        sleep $sleeptime
        $dir/test.pl
fi
set -u
