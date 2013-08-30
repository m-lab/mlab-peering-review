#!/usr/bin/env bash


SITE1=${1:?Help: provide m-lab site name}
SITE2=${2:?Help: provide m-lab site name}
ISPLIST=${3:?Help: provide ISP name}

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
    local ispname=$1
    local site=$2
    local stage=stageN
    local iplist=

    iplist=$( get_three_ips ndt.iupui $site )

    filtername=input/stage1.$ispname.$site.input 
    sqlname=$stage.$ispname.$site.sql
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

    if ! test -f sql/$sqlname ; then
        # TODO: set literal ts to first day of next month, so that the ts is always greater than DATETABLE dates.
        PTS=`TZ=UTC python -c 'import time; print int(time.mktime(time.strptime("20130901T00:00", "%Y%m%dT%H:%M")))'`
        m4 -DISP_FILTER_FILENAME=$filtername \
           -DDATETABLE=[m_lab.2013_08] \
           -DSERVERIPS="$iplist" \
           -DSITE=$site \
           -DPIVOT_TS=$PTS \
           -DOFFSET=72000 \
            tmpl/stageN-ndt.m4.sql > sql/$sqlname
    fi

    QV=./queryview.py 
    $QV --query sql/$sqlname --noplot
}

mkdir -p sorted

set -x
for ISP in $ISPLIST ; do

    handle_stageN_query $ISP $SITE1
    handle_stageN_query $ISP $SITE2

    OUTPUT1=sorted/${SITE1}2${ISP}.csv
    OUTPUT2=sorted/${SITE2}2${ISP}.csv

    sed -e 's/SITE/'${SITE1}'/g' cache/stageN.$ISP.$SITE1.sql.csv | sort -g > $OUTPUT1
    sed -e 's/SITE/'${SITE2}'/g' cache/stageN.$ISP.$SITE2.sql.csv | sort -g > $OUTPUT2

    ./queryview.py --merge $OUTPUT1 \
                   --merge $OUTPUT2 \
                   --output out.N.csv --timestamp ts
    sort -g out.N.csv > out1.N.csv

    ./queryview.py --timestamp ts \
            -l ${SITE1}_avg -C green \
            -l ${SITE2}_avg -C orange \
            -l ${SITE1}_median -C blue \
            -l ${SITE1}_q90 -C lightblue \
            -l ${SITE2}_median -C red \
            -l ${SITE2}_q90 -C pink \
            --style '-' \
            --csv out1.N.csv \
            --output graphs/n.$ISP.${SITE1}.${SITE2}.png \
            --datefmt "%H" \
            --title "${ISP} Download Rates" \
            --ylabel "Mbps" \
            --xlabel "Eastern Time (UTC-4)" \
            --ymax 68

done

