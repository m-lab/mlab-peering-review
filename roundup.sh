#!/usr/bin/env bash


# extra NewYork         : 'rcn'
# extra LosAngeles      : 
# extra Chicago         : 'mediacom', 'rcn', 'wideopenwest'
# extra SanFrancisco    : 'sonic', 'webpass'
# extra WashingtonDC    : 'rcn'
# extra Dallas          : 'suddenlink'
# extra Atlanta         : 

set -x 
set -e

function run_or_exit () {
    local cmd=$1
    echo $cmd
    if ! $cmd ; then
        echo "ERROR: non-zero exit"
        exit 1
    fi
}

function run_stages () {
    local city=$1
    local site=$2
    local isp=$3
    cmd=$( printf "$SCRIPT_ROOT/support/stages.sh %-12s %s %s" "$city" "$site" "$isp")
    run_or_exit "$cmd"
}

# NOTE: sets the root dir for all subsequent scripts
export SCRIPT_ROOT=$PWD

cat isplist.input | while read city site isp ; do 
    run_stages "$city" "$site" "$isp"
done || exit 1

# NOTE: runs comparisons between the individual data created above.
$SCRIPT_ROOT/support/followup.sh
$SCRIPT_ROOT/support/followup_avg.sh
