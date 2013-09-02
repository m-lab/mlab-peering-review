#!/usr/bin/env bash

PREFIX=${1:?HELP: Prefix name, such as city.}
SITE=${2:?HELP: Please provide an M-Lab site name, i.e. lga01, lax01, etc.}
ISPLIST=${3:?HELP: Please provide a short ISP name, i.e. warner, comcast, verizon}

mkdir -p tmp
set -x
set -e
for ISP in $ISPLIST ; do

    RAWSAMPLES=cache/stage1.$PREFIX.$SITE.$ISP.sql.csv 
    TS_HOPS=cache/tshops.$PREFIX.$SITE.$ISP.csv 

    TMPFILE_RAW=tmp/raw.$PREFIX.$SITE.$ISP.csv
    TMPFILE_TS=tmp/ts.$PREFIX.$SITE.$ISP.csv

    cat $RAWSAMPLES | sort -n > $TMPFILE_RAW
    sed -e 's/raw_download_rate/'$SITE'/g' -i '' $TMPFILE_RAW

    TZ=UTC $SCRIPT_ROOT/queryview.py --csv $TMPFILE_RAW \
            --timestamp day_timestamp \
            -l $SITE -C blue \
            --between 20130902T06:00,20130903T06:00 \
            --output graphs/tsraw.$PREFIX.$SITE.$ISP.png \
            --pivot 20130902T06:00 \
            --datefmt "%H" \
            --offset 72000 \
            --title "RAW $SITE to $ISP Download Rates" \
            --ylabel "Mbps" \
            --xlabel "Eastern Time (UTC-4)" \
            --ymax 68

    # this will sort the paths with the largest number of samples
    # just take the top one for now that's not part of a private trace.
    HIGHEST=`$SCRIPT_ROOT/support/grepcount.sh $PREFIX $SITE $ISP | \
              sort -nr | grep -vE "Private|AS000" | head -1 | awk '{print $2}'`

    grep -E "as1|$HIGHEST" $TS_HOPS | sort -n > $TMPFILE_TS

    sed -e 's/rate/'$SITE'/g' -i '' $TMPFILE_TS

    TZ=UTC $SCRIPT_ROOT/queryview.py --csv $TMPFILE_TS \
            --timestamp ts \
            -l $SITE -C blue \
            --between 20130902T06:00,20130903T06:00 \
            --output graphs/tshops.$PREFIX.$SITE.$ISP.png \
            --pivot 20130902T06:00 \
            --datefmt "%H" \
            --offset 72000 \
            --title "HOPS $HIGHEST $SITE to $ISP" \
            --ylabel "Mbps" \
            --xlabel "Eastern Time (UTC-4)" \
            --ymax 68

done

