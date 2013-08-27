#!/usr/bin/env bash

function find_command () {
    local command=$1
    if ! type -P $command &> /dev/null ; then
        echo "ERROR: could no locate '$command' in current PATH"
        echo "ERROR: either install $command, or update PATH"
        exit 1
    fi
}

find_command wget
find_command m4

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

function generate_ispquery () {
    local ISPNAME=$1
    AFTERFIRST=
    rm -f input/$ISPNAME.input

    if ! test -f input/$ISPNAME.input ; then
        FILTER_PREFIX="PARSE_IP(web100_log_entry.connection_spec.remote_ip) "
        grep -i $ISPNAME $IP2ASNFILE.csv | \
            awk -F, '{print $1,$2}' | \
            while read IP_low IP_high ; do
                if test -n "$AFTERFIRST" ; then echo " OR" ; fi
                FILTER="$FILTER_PREFIX BETWEEN $IP_low AND $IP_high "
                echo -n "        $FILTER" 
                AFTERFIRST=1
            done > input/$ISPNAME.input
    fi

    if ! test -f sql/$ISPNAME.lga01.sql ; then
        m4 -DISP_FILTER_FILENAME=input/$ISPNAME.input \
           -DDATETABLE=[m_lab.2013_08] \
           -DSERVERIPS="'74.63.50.19','74.63.50.32','74.63.50.47'" \
            tmpl/ndt-tmpl-generic.m4.sql > sql/$ISPNAME.lga01.sql
    fi
    if ! test -f sql/$ISPNAME.lga02.sql ; then
        m4 -DISP_FILTER_FILENAME=input/$ISPNAME.input \
           -DDATETABLE=[m_lab.2013_08] \
           -DSERVERIPS="'38.106.70.147','38.106.70.160','38.106.70.173'" \
            tmpl/ndt-tmpl-generic.m4.sql > sql/$ISPNAME.lga02.sql
    fi

    mkdir -p graphs
    QV=./queryview.py 
    $QV --query $ISPNAME.lga01 \
        --count test_count \
        --timestamp day_timestamp \
        -l med_rate \
        --ylabel "Mbps" \
        --title "LGA01 - Internap" \
        --output graphs/$ISPNAME.lga01.png

    $QV --query $ISPNAME.lga02 \
        --count test_count \
        --timestamp day_timestamp \
        -l med_rate \
        --ylabel "Mbps" \
        --title "LGA02 - Cogent" \
        --output graphs/$ISPNAME.lga02.png
}

generate_ispquery comcast
generate_ispquery cablevision
#generate_ispquery warner
#generate_ispquery rcn
#generate_ispquery verizon
