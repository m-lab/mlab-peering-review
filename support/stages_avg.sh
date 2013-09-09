#!/usr/bin/env bash


function lookup_ip () {
    local host=$1
    PYSCRIPT="import socket; print socket.gethostbyname('"$host"')"
    ip=$( python -c "$PYSCRIPT" 2> /dev/null )
    if test $? -eq 0 ; then
        echo $ip
    fi
}

function get_three_ips () {
    local service=$1
    local site=$2
    local iplist=
    AFTERFIRST=
    for mlab in mlab1 mlab2 mlab3 ; do
        if test -n "$AFTERFIRST" ; then iplist+=","; fi
        hn="$service.$mlab.$site.measurement-lab.org"
        ip=$( lookup_ip $hn )
        iplist+="'$ip'"
        AFTERFIRST=1
    done
    echo $iplist
}

function handle_stageN_query () {
    local prefix=$1
    local site=$2
    local ispname=$3
    local stage=stageN
    local iplist=

    iplist=$( get_three_ips ndt.iupui $site )

    filtername=input/stageN.$prefix.$site.$ispname.input 
    sqlname=$stage.$prefix.$site.$ispname.sql
    counts_sqlname=$stage.$prefix.$site.$ispname.sql
    rm -f $filtername

    if test "$ispname" = "cox" ; then
        ispname=" cox"
    elif test "$ispname" = "verizon" ; then
        ispname="AS701 "
    fi

    IP2ASNFILE=GeoIPASNum2
    AFTERFIRST=
    if ! test -f $filtername ; then
        #FILTER_PREFIX="PARSE_IP(connection_spec.client_ip) "
        FILTER_PREFIX="PARSE_IP(web100_log_entry.connection_spec.remote_ip) "
        grep -i "$ispname" $IP2ASNFILE.csv | \
            awk -F, '{print $1,$2}' | \
            while read IP_low IP_high ; do
                if test -n "$AFTERFIRST" ; then echo " OR" ; fi
                FILTER="$FILTER_PREFIX BETWEEN $IP_low AND $IP_high "
                echo -n "$FILTER" 
                AFTERFIRST=1
            done | tail -1500 > $filtername
    fi

    if ! test -f sql/$sqlname || test $filtername -nt sql/$sqlname ; then
        m4 -DISP_FILTER_FILENAME=$filtername \
           -DDATETABLE=[m_lab.2013_08] \
           -DSERVERIPS="$iplist" \
           -DSITE=$site \
           -DTSBIN=1800 \
           -DOFFSET=36000 \
            tmpl/stageN-ndt.m4.sql > sql/$sqlname

        #for rate in 30 40 50 60 80 100 120 200 800 ; do
        #    m4 -DISP_FILTER_FILENAME=$filtername \
        #       -DDATETABLE=[m_lab.2013_08] \
        #       -DSERVERIPS="$iplist" \
        #       -DSITE=$site \
        #       -DTSBIN=1800 \
        #       -DOFFSET=36000 \
        #        tmpl/stageN-counts.m4.sql > sql/c.$counts_sqlname
        #done
    fi

    QV=./queryview.py 
    $QV --query sql/$sqlname --noplot
    #sleep 5
    #$QV --query sql/c.$sqlname --noplot
}

mkdir -p sorted
mkdir -p graphs
mkdir -p cache
mkdir -p input
mkdir -p sql
mkdir -p tmp

PREFIX=${1:?HELP: Prefix name, such as city.}
SITE1=${2:?HELP: Please provide an M-Lab site name, i.e. lga01, lax01, etc.}
ISPLIST=${3:?HELP: Please provide a short ISP name, i.e. warner, comcast, verizon}

export TZ=UTC
set -x
set -e

for ISP in $ISPLIST ; do

    echo site1 $PREFIX $SITE1 $ISP
    handle_stageN_query $PREFIX $SITE1 $ISP

    OUTPUT1=sorted/sorted.${PREFIX}.${SITE1}.${ISP}.csv

done

