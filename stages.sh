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

function handle_stage1_query () {
    local ispname=$1
    local stage=$2
    local site=$3
    local iplist=$4

    AFTERFIRST=
    filtername=input/$stage.$ispname.$site.input 
    sqlname=$stage.$ispname.$site.sql
    rm -f $filtername

    if ! test -f $filtername ; then
        FILTER_PREFIX="PARSE_IP(web100_log_entry.connection_spec.remote_ip) "
        grep -i $ispname $IP2ASNFILE.csv | \
            awk -F, '{print $1,$2}' | \
            while read IP_low IP_high ; do
                if test -n "$AFTERFIRST" ; then echo " OR" ; fi
                FILTER="$FILTER_PREFIX BETWEEN $IP_low AND $IP_high "
                echo -n "        $FILTER" 
                AFTERFIRST=1
            done > $filtername
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
    local stage=$2
    local site=$3
    local iplist=$4

    AFTERFIRST=

    inputcsv=cache/stage1.$ispname.$site.sql.csv
    filtername=input/$stage.$ispname.$site.input
    sqlname=$stage.$ispname.$site.sql

    rm -f $filtername

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
    local stage=$2
    local site=$3
    local iplist=$4

    AFTERFIRST=

    inputcsv=cache/stage2.$ispname.$site.sql.csv
    filtername=input/$stage.$ispname.$site.input
    sqlname=$stage.$ispname.$site.sql

    rm -f $filtername

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


#ISP=cablevision
#ISP=warner
#ISP=rcn
ISP=comcast
#for ISP in cablevision warner rcn comcast ; do
#for ISP in rcn ; do
for ISP in comcast ; do
    # NDT server ip addrs
    handle_stage1_query $ISP        stage1 lga01 "'74.63.50.19','74.63.50.32','74.63.50.47'"
    handle_stage1_query $ISP        stage1 lga02 "'38.106.70.147','38.106.70.160','38.106.70.173'"

    # NPAD (*not* NDT) server ip addrs
    handle_stage2_query $ISP        stage2 lga01 "'74.63.50.10','74.63.50.23','74.63.50.43'"
    handle_stage2_query $ISP        stage2 lga02 "'38.106.70.146','38.106.70.151','38.106.70.172'"

    # NPAD (*not* NDT) server ip addrs
    handle_stage3_query $ISP        stage3 lga01 "'74.63.50.10','74.63.50.23','74.63.50.43'"
    handle_stage3_query $ISP        stage3 lga02 "'38.106.70.146','38.106.70.151','38.106.70.172'"

    ./hops.py $ISP    lga01
    ./hops.py $ISP    lga02

    ./diagram.sh $ISP    lga01 > input/$ISP.lga01.gv
    dot -Tpng input/$ISP.lga01.gv > graphs/$ISP.lga01.png
    ./diagram.sh $ISP lga02 > input/$ISP.lga02.gv
    dot -Tpng input/$ISP.lga02.gv > graphs/$ISP.lga02.png
done

#generate_ispquery warner
#generate_ispquery rcn
#generate_ispquery verizon
