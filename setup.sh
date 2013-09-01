#!/usr/bin/env bash

function find_command () {
    local command=$1
    if ! type -P $command &> /dev/null ; then
        echo "ERROR: could no locate '$command' in current PATH"
        echo "ERROR: either install $command, or update PATH"
        exit 1
    fi
}

set -e

find_command wget
find_command m4
find_command dot

# NOTE: if deps are not there, this will fail.
./queryview.py --checkdeps

set -x

IP2ASNFILE=GeoIPASNum2
if ! test -f $IP2ASNFILE.zip ; then
    wget http://download.maxmind.com/download/geoip/database/asnum/$IP2ASNFILE.zip
fi
if ! test -f $IP2ASNFILE.csv ; then
    unzip $IP2ASNFILE.zip
    if test $? -ne 0 ; then
        echo "Error: failed to unzip $IP2ASNFILE.zip"
        exit 1
    fi
fi

touch .setup_passed
