#!/usr/bin/env bash

PREFIX1=${1:?HELP: First Prefix name, such as city.}
SITE1=${2:?HELP: First M-Lab site name, i.e. lga01, lax01, etc.}
ISP1=${3:?HELP: First short ISP name, i.e. warner, comcast, verizon}
COLOR1=${4:?HELP: First color, i.e. red, blue, green, etc.}
PROVIDER1=${5:?HELP: First site provider}

PREFIX2=${6:?HELP: Second Prefix name, such as city.}
SITE2=${7:?HELP: Second M-Lab site name, i.e. lga01, lax01, etc.}
ISP2=${8:?HELP: Second short ISP name, i.e. warner, comcast, verizon}
COLOR2=${9:?HELP: Second color, i.e. red, blue, green, etc.}
PROVIDER2=${10:?HELP: Second site provider.}

export TZ=UTC

set -x
set -e

# RAW SAMPLES
PREFIX=$PREFIX1
if test "$PREFIX1" != "$PREFIX2" ; then
    PREFIX=${PREFIX1}_vs_$PREFIX2
fi
SITE=$SITE1
if test "$SITE1" != "$SITE2" ; then
    SITE=${SITE1}_vs_$SITE2
fi
ISP=$ISP1
if test "$ISP1" != "$ISP2" ; then
    ISP=${ISP1}_vs_$ISP2
fi
PROVIDER=$PROVIDER1
if test "$PROVIDER1" != "$PROVIDER2" ; then
    PROVIDER=${PROVIDER1}_vs_$PROVIDER2
fi

file1=cache/stage1.$PREFIX1.$SITE1.$ISP1.sql.csv
file2=cache/stage1.$PREFIX2.$SITE2.$ISP2.sql.csv
tmp1=tmp/stage1.$PREFIX1.$SITE1.$ISP1.sql.csv
tmp2=tmp/stage1.$PREFIX2.$SITE2.$ISP2.sql.csv
outfile=tmp/compare.$PREFIX.$SITE.$ISP

cat $file1 | sed -e 's/raw_download_rate/'${SITE1}_to_$ISP1'/g' | sort -n > $tmp1
cat $file2 | sed -e 's/raw_download_rate/'${SITE2}_to_$ISP2'/g' | sort -n > $tmp2

./queryview.py --merge $tmp1 \
               --merge $tmp2 \
               --output $outfile.csv --timestamp day_timestamp

sort -n $outfile.csv > $outfile.2.csv 

./queryview.py --timestamp day_timestamp \
            -l ${SITE1}_to_$ISP1 -C $COLOR1 \
            -l ${SITE2}_to_$ISP2 -C $COLOR2 \
            --csv $outfile.2.csv \
            --between 20130902T06:00,20130903T06:00 \
            --pivot   20130902T06:00 \
            --output graphs/compare.$PREFIX.$SITE.$ISP.png \
            -M '.' \
            -M '.' \
            --datefmt "%H" \
            --offset 72000 \
            --title "$PROVIDER to $ISP Downloads" \
            --ylabel "Mbps" \
            --xlabel "Eastern Time (UTC-4)" \
            --ymax 68

