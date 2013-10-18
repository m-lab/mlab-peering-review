#!/usr/bin/env bash


mkdir -p sorted
mkdir -p graphs
mkdir -p cache
mkdir -p input
mkdir -p sql
mkdir -p tmp

PREFIX1=${1:?HELP: Prefix name, such as city.}
SITE1=${2:?HELP: Please provide an M-Lab site name, i.e. lga01, lax01, etc.}
ISP1=${3:?HELP: Please provide a short ISP name, i.e. warner, comcast, verizon}
UPL1=${4:?Help: uplink one}

PREFIX2=${5:?HELP: Prefix name, such as city.}
SITE2=${6:?HELP: Please provide an M-Lab site name, i.e. lga01, lax01, etc.}
ISP2=${7:?HELP: Please provide a short ISP name, i.e. warner, comcast, verizon}
UPL2=${8:?Help: uplink one}

UPL=$UPL1
if test "$UPL1" != "$UPL2" ; then 
    UPL="${UPL1} and ${UPL2}"
fi

function capitalize () {
    local word=$1
    echo $( tr '[:lower:]' '[:upper:]' <<< ${word:0:1} )${word:1}
}

export TZ=UTC
set -x
set -e

OUTPUT1=sorted/sorted.${PREFIX1}.${SITE1}.${ISP1}.csv
OUTPUT2=sorted/sorted.${PREFIX2}.${SITE2}.${ISP2}.csv

# Start with uplink names for column names
COL1=$( capitalize ${ISP1}_over_${UPL1}_- )
COL2=$( capitalize ${ISP2}_over_${UPL2}_- )

# if that doesn't work, use ISP, Prefix, or Site names
if test x"$COL1" = x"$COL2" ; then 
    COL1=$ISP1
    COL2=$ISP2
fi
if test x"$COL1" = x"$COL2" ; then 
    COL1=$PREFIX1
    COL2=$PREFIX2
fi
if test x"$COL1" = x"$COL2" ; then 
    COL1=$SITE1
    COL2=$SITE2
fi

sed -e 's/SITE/'${COL1}'/g' cache/stageN.${PREFIX1}.${SITE1}.${ISP1}.sql.csv > $OUTPUT1
sed -e 's/SITE/'${COL2}'/g' cache/stageN.${PREFIX2}.${SITE2}.${ISP2}.sql.csv > $OUTPUT2


PREFIX=$PREFIX1
if test "$PREFIX1" != "$PREFIX2" ; then
    PREFIX="${PREFIX1}vs${PREFIX2}"
fi
SITE=$SITE1
if test "$SITE1" != "$SITE2" ; then
    SITE="${SITE1}vs${SITE2}"
fi
ISP=$ISP1
ISPCAP=$( capitalize $ISP1 )
if test "$ISP1" != "$ISP2" ; then
    ISP="${ISP1}vs${ISP2}"
    C1=$( capitalize $ISP1 )
    C2=$( capitalize $ISP2 )
    ISPCAP="$C1 vs $C2"
fi

./queryview.py --merge $OUTPUT1 \
               --merge $OUTPUT2 \
               --output cache/n.${PREFIX}.${SITE}.${ISP}.csv \
               --timestamp ts

PCT=95th
TZ=UTC $SCRIPT_ROOT/queryview.py --timestamp ts \
            -l ${COL1}_${PCT}_percentile -C darkblue \
            -l ${COL2}_${PCT}_percentile -C darkred \
            --count_column ${COL1}_count \
            --count_column ${COL2}_count \
            --csv cache/n.${PREFIX}.${SITE}.${ISP}.csv \
            --output graphs/n.$PCT.${PREFIX}.${SITE}.${ISP}.png \
            --style '-' \
            --marker '' \
            --datefmt "%H" \
            --title  "${ISPCAP} Downloads in $PREFIX" \
            --ylabel "Download Rate (Mbps)" \
            --xlabel "Eastern Time (UTC-4)" \
            --offset $(( 6*3600 )) \
            --scale 0.000278  \
            --fillbetween \
            --smoothing 5,3 \
            --ymax 35
            # --overlay \
            #\ --count_ymax 350 \ --ymax 120

