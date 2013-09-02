#!/usr/bin/env bash

_=${SCRIPT_ROOT:?ERROR: set SCRIPT_ROOT before running this script.}

if ! test -f $SCRIPT_ROOT/.setup_passed ; then
    $SCRIPT_ROOT/setup.sh 
fi

mkdir -p graphs
mkdir -p cache
mkdir -p input
mkdir -p sql
mkdir -p tmp

set -x
set -e

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
    local prefix=$1
    local site=$2
    local ispname=$3
    local stage=stage1
    local iplist=

    set +x
    iplist=$( get_three_ips ndt.iupui $site )
    set -x

    filtername=input/$stage.$prefix.$site.$ispname.input 
    sqlname=$stage.$prefix.$site.$ispname.sql
    #rm -f $filtername

    if test "$ispname" = "cox" ; then
        ispname=" cox"
    elif test "$ispname" = "verizon" ; then
        ispname="AS701 "
    fi

    AFTERFIRST=
    if ! test -f $filtername ; then
        FILTER_PREFIX="PARSE_IP(web100_log_entry.connection_spec.remote_ip) "
        #FILTER_PREFIX="PARSE_IP(connection_spec.client_ip) "
        set +x
        grep -i "$ispname" $IP2ASNFILE.csv | \
            awk -F, '{print $1,$2}' | \
            while read IP_low IP_high ; do
                if test -n "$AFTERFIRST" ; then echo " OR" ; fi
                FILTER="$FILTER_PREFIX BETWEEN $IP_low AND $IP_high "
                echo -n "$FILTER" 
                AFTERFIRST=1
            done | tail -1500 > $filtername
            # TODO:
            # TODO: generalize above, to remove tail, so we can allow all prefixes above.
            # TODO: 
        set -x
    fi

    if ! test -f sql/$sqlname ; then
        m4 -DISP_FILTER_FILENAME=$filtername \
           -DDATETABLE=[m_lab.2013_08] \
           -DSERVERIPS="$iplist" \
            tmpl/stage1-ndt.m4.sql > sql/$sqlname
    fi

    QV=$SCRIPT_ROOT/queryview.py 
    $QV --query sql/$sqlname --noplot

}

function handle_stage2_query () {
    local prefix=$1
    local site=$2
    local ispname=$3
    local stage=stage2
    local iplist=

    iplist=$( get_three_ips npad.iupui $site )


    inputcsv=cache/stage1.$prefix.$site.$ispname.sql.csv
    filtername=input/$stage.$prefix.$site.$ispname.input 
    sqlname=$stage.$prefix.$site.$ispname.sql

    #rm -f $filtername

    AFTERFIRST=
    if ! test -f $filtername ; then

        FILTER_PREFIX=""
        set +x
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
        set -x
    fi

    if ! test -f sql/$sqlname ; then
        m4 -DSTAGE2_FILTER_FILENAME=$filtername \
           -DDATETABLE=[m_lab.2013_08] \
           -DSERVERIPS="$iplist" \
            tmpl/stage2-ndt.m4.sql > sql/$sqlname
    fi

    QV=$SCRIPT_ROOT/queryview.py 
    $QV -v --query sql/$sqlname --noplot 

}

function handle_stage3_query () {
    local prefix=$1
    local site=$2
    local ispname=$3
    local stage=stage3
    local iplist=

    iplist=$( get_three_ips npad.iupui $site )

    inputcsv=cache/stage2.$prefix.$site.$ispname.sql.csv
    filtername=input/$stage.$prefix.$site.$ispname.input 
    sqlname=$stage.$prefix.$site.$ispname.sql

    #rm -f $filtername

    AFTERFIRST=
    if ! test -f $filtername ; then

        FILTER_PREFIX=""
        set +x
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
        set -x
    fi

    if ! test -f sql/$sqlname ; then
        m4 -DSTAGE3_FILTER_FILENAME=$filtername \
           -DDATETABLE=[m_lab.2013_08] \
           -DSERVERIPS="$iplist" \
            tmpl/stage3-ndt.m4.sql > sql/$sqlname
    fi

    QV=$SCRIPT_ROOT/queryview.py 
    $QV -v --query sql/$sqlname --noplot 

}

PREFIX=${1:?HELP: Prefix name, such as city.}
SITE=${2:?HELP: Please provide an M-Lab site name, i.e. lga01, lax01, etc.}
ISPLIST=${3:?HELP: Please provide a short ISP name, i.e. warner, comcast, verizon}

for ISP in $ISPLIST ; do

    # stage1: get measurements from client-ips in ASN-to-IP ranges for $ISP
    # stage2: collect all client-ips to find traceroutes
    # stage3: use traceroute test_ids to find all hops along traces.
    handle_stage1_query $PREFIX $SITE $ISP
    handle_stage2_query $PREFIX $SITE $ISP
    handle_stage3_query $PREFIX $SITE $ISP

    # if stage1 or stage3 files are newer than tshops or avghops
    stage1=cache/stage1.$PREFIX.$SITE.$ISP.sql.csv
    stage3=cache/stage3.$PREFIX.$SITE.$ISP.sql.csv
    tshops=cache/tshops.$PREFIX.$SITE.$ISP.csv

    if test $stage1 -nt $tshops || test $stage3 -nt $tshops ; then
        # NOTE: this takes the longest, so only run if necessary.
        $SCRIPT_ROOT/support/hops.py    $PREFIX $SITE $ISP
    fi

    $SCRIPT_ROOT/support/diagram.sh $PREFIX $SITE $ISP 

    $SCRIPT_ROOT/support/plots.sh   $PREFIX $SITE $ISP

done
