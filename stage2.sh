#!/usr/bin/env bash

set -e
set -x

function generate_ispquery () {
    local ISPNAME=$1
    AFTERFIRST=
    stage1input=$ISPNAME.s1
    stage2output=$ISPNAME.s2
    stage2sql=$ISPNAME.s2

    rm -f $stage2output

    if ! test -f $stage2output.lga01.input ; then

        FILTER_PREFIX=""
        awk -F, '{print $1,$2,$3}' $stage1input | \
            while read ts server_ip client_ip ; do
                if test -n "$AFTERFIRST" ; then echo " OR" ; fi

                FILTER="( $ts BETWEEN "$(( $ts-120))" AND "$(( $ts+120 ))" AND
                          connection_spec.client_ip='$client_ip' )"
                echo -n "        $FILTER" 
                AFTERFIRST=1
            done > $stage2output
    fi

    # '38.106.70.146','38.106.70.151','38.106.70.172'
    # '74.63.50.10','74.63.50.23','74.63.50.43'

    if ! test -f sql/$stage2sql.lga01.sql ; then
        m4 -DISP_FILTER_FILENAME=$stage2output \
           -DDATETABLE=[m_lab.2013_08] \
           -DSERVERIPS="'74.63.50.19','74.63.50.32','74.63.50.47'" \
            sql/stage2-ndt.m4.sql > sql/$stage2sql.lga01.sql
    fi
    if ! test -f sql/$stage2sql.lga02.sql ; then
        m4 -DISP_FILTER_FILENAME=$stage2output \
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
