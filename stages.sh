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
find_command dot


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
mkdir -p graphs
mkdir -p cache
mkdir -p input
mkdir -p sql

set -e
set -x

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

function handle_stage1_query () {
    local ispname=$1
    local site=$2
    local stage=stage1
    local iplist=

    iplist=$( get_three_ips ndt.iupui $site )

    filtername=input/$stage.$ispname.$site.input 
    sqlname=$stage.$ispname.$site.sql
    rm -f $filtername

    if test "$ispname" = "cox" ; then
        ispname=" cox"
    elif test "$ispname" = "verizon" ; then
        ispname="AS701 "
    fi

    AFTERFIRST=
    if ! test -f $filtername ; then
        FILTER_PREFIX="PARSE_IP(web100_log_entry.connection_spec.remote_ip) "
        #FILTER_PREFIX="PARSE_IP(connection_spec.client_ip) "
        grep -i "$ispname" $IP2ASNFILE.csv | \
            awk -F, '{print $1,$2}' | \
            while read IP_low IP_high ; do
                if test -n "$AFTERFIRST" ; then echo " OR" ; fi
                FILTER="$FILTER_PREFIX BETWEEN $IP_low AND $IP_high "
                echo -n "$FILTER" 
                AFTERFIRST=1
            done | tail -1500 > $filtername
    fi

    if ! test -f sql/$sqlname ; then
        m4 -DISP_FILTER_FILENAME=$filtername \
           -DDATETABLE=[m_lab.2013_08] \
           -DSERVERIPS="$iplist" \
            tmpl/stage1-ndt.m4.sql > sql/$sqlname
    fi

    QV=./queryview.py 
    $QV --query sql/$sqlname --noplot

}

function handle_stage2_query () {
    local ispname=$1
    local site=$2
    local stage=stage2
    local iplist=

    iplist=$( get_three_ips npad.iupui $site )

    inputcsv=cache/stage1.$ispname.$site.sql.csv
    filtername=input/$stage.$ispname.$site.input
    sqlname=$stage.$ispname.$site.sql

    rm -f $filtername

    AFTERFIRST=
    if ! test -f $filtername ; then

        FILTER_PREFIX=""
        grep -v day_timestamp $inputcsv | awk -F, '{print $1,$2,$3}' | \
            while read ts server_ip client_ip ; do
                if test -z "$AFTERFIRST" ; then 
                    echo "connection_spec.client_ip IN("
                fi
                if test -n "$AFTERFIRST" ; then 
                    echo "," ; 
                fi

                #FILTER="( $ts BETWEEN "$(( $ts-300))" AND "$(( $ts+300 ))" AND
                #          connection_spec.client_ip='$client_ip' )"
                FILTER="'$client_ip'"
                echo -n "    $FILTER" 
                AFTERFIRST=1
            done > $filtername
            echo ")" >> $filtername
    fi

    if ! test -f sql/$sqlname ; then
        m4 -DSTAGE2_FILTER_FILENAME=$filtername \
           -DDATETABLE=[m_lab.2013_08] \
           -DSERVERIPS="$iplist" \
            tmpl/stage2-ndt.m4.sql > sql/$sqlname
    fi

    QV=./queryview.py 
    $QV -v --query sql/$sqlname --noplot 

}

function handle_stage3_query () {
    local ispname=$1
    local site=$2
    local stage=stage3
    local iplist=

    iplist=$( get_three_ips npad.iupui $site )

    inputcsv=cache/stage2.$ispname.$site.sql.csv
    filtername=input/$stage.$ispname.$site.input
    sqlname=$stage.$ispname.$site.sql

    rm -f $filtername

    AFTERFIRST=
    if ! test -f $filtername ; then

        FILTER_PREFIX=""
        grep -v day_timestamp $inputcsv | tr '' ' ' | sed -e 's/ $//g' | awk -F, '{print $1,$2,$3,$4}' | \
            while read ts server_ip client_ip test_id ; do
                if test -z "$AFTERFIRST" ; then 
                    echo "test_id IN("
                fi
                if test -n "$AFTERFIRST" ; then 
                    echo "," ; 
                fi
                FILTER="'$test_id'"
                echo -n " $FILTER" 
                AFTERFIRST=1
            done > $filtername
            echo ")" >> $filtername
    fi

    if ! test -f sql/$sqlname ; then
        m4 -DSTAGE3_FILTER_FILENAME=$filtername \
           -DDATETABLE=[m_lab.2013_08] \
           -DSERVERIPS="$iplist" \
            tmpl/stage3-ndt.m4.sql > sql/$sqlname
    fi

    QV=./queryview.py 
    $QV -v --query sql/$sqlname --noplot 

}



# NYC - cablevision, time warner, rcn, comcast, verizon
# LAX - time warner, charter, cox, verizon, at&t 
# ORD - comcast, rcn, wide open west?
# NUQ - comcast, -- astound, 
# IAD - 
# DFW - 

SITE=${1:?HELP: Please provide an M-Lab site name, i.e. lga01, lax01, etc.}
ISPLIST=${2:?HELP: Please provide a short ISP name, i.e. warner, comcast, verizon}

#ISP=cablevision
#ISP=warner
#ISP=rcn
#ISP=comcast
#for ISP in cablevision warner comcast ; do

for ISP in $ISPLIST ; do

    # get measurements from client-ips based on ASN-to-IP ranges for $ISP
    handle_stage1_query $ISP $SITE

    # collect all client-ips to find traceroutes
    handle_stage2_query $ISP $SITE

    # use traceroute test_ids to find all hops along traces.
    handle_stage3_query $ISP $SITE

    ./hops.py   $ISP $SITE

    ./diagram.sh $ISP $SITE > input/$ISP.$SITE.gv
    dot -Tpng input/$ISP.$SITE.gv > graphs/$ISP.$SITE.png

done
