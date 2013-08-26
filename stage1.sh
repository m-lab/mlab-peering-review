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
set -e
set -x

function generate_ispquery () {
    local ISPNAME=$1
    AFTERFIRST=
    rm -f $ISPNAME.input

    if ! test -f $ISPNAME.input ; then
        FILTER_PREFIX="PARSE_IP(web100_log_entry.connection_spec.remote_ip) "
        grep -i $ISPNAME $IP2ASNFILE.csv | \
            awk -F, '{print $1,$2}' | \
            while read IP_low IP_high ; do
                if test -n "$AFTERFIRST" ; then echo " OR" ; fi
                FILTER="$FILTER_PREFIX BETWEEN $IP_low AND $IP_high "
                echo -n "        $FILTER" 
                AFTERFIRST=1
            done > $ISPNAME.input
    fi

    if ! test -f sql/$ISPNAME.s1.lga01.sql ; then
        m4 -DISP_FILTER_FILENAME=$ISPNAME.input \
           -DDATETABLE=[m_lab.2013_08] \
           -DSERVERIPS="'74.63.50.19','74.63.50.32','74.63.50.47'" \
            sql/stage1-ndt.m4.sql > sql/$ISPNAME.s1.lga01.sql
    fi
    if ! test -f sql/$ISPNAME.s1.lga02.sql ; then
        m4 -DISP_FILTER_FILENAME=$ISPNAME.input \
           -DDATETABLE=[m_lab.2013_08] \
           -DSERVERIPS="'38.106.70.147','38.106.70.160','38.106.70.173'" \
            sql/stage1-ndt.m4.sql > sql/$ISPNAME.s1.lga02.sql
    fi

    QV=./queryview.py 
    $QV --query $ISPNAME.s1.lga01 \
        --noplot \
        --timestamp day_timestamp \
        -l junk

    $QV --query $ISPNAME.s1.lga02 \
        --noplot \
        --timestamp day_timestamp \
        -l junk
}

generate_ispquery comcast
generate_ispquery cablevision
#generate_ispquery warner
#generate_ispquery rcn
#generate_ispquery verizon
