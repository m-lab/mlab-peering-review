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


export TZ=UTC
set -x
set -e

OUTPUT1=sorted/sorted.${PREFIX1}.${SITE1}.${ISP1}.csv
OUTPUT2=sorted/sorted.${PREFIX2}.${SITE2}.${ISP2}.csv

# Start with uplink names for column names
COL1=$UPL1
COL2=$UPL2

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

./queryview.py --merge $OUTPUT1 \
               --merge $OUTPUT2 \
               --output out.N.csv --timestamp ts

PREFIX=$PREFIX1
if test "$PREFIX1" != "$PREFIX2" ; then
    PREFIX="${PREFIX1}vs${PREFIX2}"
fi
SITE=$SITE1
if test "$SITE1" != "$SITE2" ; then
    SITE="${SITE1}vs${SITE2}"
fi
ISP=$ISP1
if test "$ISP1" != "$ISP2" ; then
    ISP="${ISP1}vs${ISP2}"
fi

TZ=UTC $SCRIPT_ROOT/queryview.py --timestamp ts \
            -l ${COL1}_95percentile -C darkblue \
            -l ${COL2}_95percentile -C darkred \
            --style '-' \
            --csv out.N.csv \
            --output graphs/n.${PREFIX}.${SITE}.${ISP}.png \
            --datefmt "%H" \
            --title  "${ISP} to $UPL" \
            --ylabel "Download Rate (Mbps)" \
            --xlabel "Eastern Time (UTC-4)" \
            --offset $(( 6*3600 )) \
            --ymax 68

