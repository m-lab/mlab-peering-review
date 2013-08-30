#!/usr/bin/env bash


set -x
for ISP in cablevision warner comcast verizon ; do
#for ISP in verizon ; do
    #./ts_hops.py $ISP $SITE
    #./ts_hops.py $ISP $SITE

    # this will sort the paths with the largest number of samples
    # just take the top one for now that's not part of a private trace.
    HIGHEST=`grepcount.sh $SITE $ISP | sort -nr | grep -vE "Private|AS000" | head -1 | awk '{print $2}'`
    grep -E "as1|$HIGHEST" cache/tshops.$ISP.lga01.csv | sort -n > internap2$ISP.csv

    # SAMPLES with PATHS
    if test "$ISP" = "cablevision" ; then
        grep -E "as1|Private,AS6128" cache/tshops.$ISP.lga01.csv | sort -n > internap2$ISP.csv
        grep -E "as1|PSI,AS6128"     cache/tshops.$ISP.lga02.csv | sort -n > cogent2$ISP.csv
    elif test "$ISP" = "comcast" ; then
        grep -E "as1|Voxel,AS13789"  cache/tshops.$ISP.lga01.csv | sort -n > internap2$ISP.csv
        grep -E "as1|PSI,AS7922"     cache/tshops.$ISP.lga02.csv | sort -n > cogent2$ISP.csv
    elif test "$ISP" = "warner" ; then
        grep -E "as1|Voxel,AS23393"  cache/tshops.$ISP.lga01.csv | sort -n > internap2$ISP.csv
        grep -E "as1|PSI,AS7843"     cache/tshops.$ISP.lga02.csv | sort -n > cogent2$ISP.csv
    elif test "$ISP" = "verizon" ; then
        grep -E "as1|nLayer,AS701"   cache/tshops.$ISP.lga01.csv | sort -n > internap2$ISP.csv
        grep -E "as1|PSI,AS701"      cache/tshops.$ISP.lga02.csv | sort -n > cogent2$ISP.csv
    fi

    # RAW SAMPLES
    cat cache/stage1.$ISP.lga01.sql.csv | sort -n > internap2$ISP.2.csv
    cat cache/stage1.$ISP.lga02.sql.csv | sort -n > cogent2$ISP.2.csv
    sed -e 's/raw_download_rate/internap/g' -i'' internap2$ISP.2.csv 
    sed -e 's/raw_download_rate/cogent/g' -i'' cogent2$ISP.2.csv

    ./queryview.py --merge internap2$ISP.2.csv \
                   --merge cogent2$ISP.2.csv \
                   --output out.2.csv --timestamp day_timestamp
    sort -n out.2.csv > out1.2.csv 

    ./queryview.py --timestamp day_timestamp \
            -l internap  -C blue \
            -l cogent -C red \
            --csv out1.2.csv --between 20130830T06:00,20130831T06:00 \
            --output graphs/$ISP.2.vc.png \
            --pivot 20130830T06:00 \
            --datefmt "%H" \
            --offset 72000 \
            --title "${ISP^} Download Rates" \
            --ylabel "Mbps" \
            --xlabel "Eastern Time (UTC-4)" \
            --ymax 68


    # SAMPLES WITH PATHS
    sed -e 's/rate/internap/g' -i'' internap2$ISP.csv 
    sed -e 's/rate/cogent/g' -i'' cogent2$ISP.csv

    ./queryview.py --merge  internap2$ISP.csv \
                   --merge  cogent2$ISP.csv \
                   --output out.csv --timestamp ts

    sort -n out.csv > out1.csv 

    ./queryview.py --timestamp ts \
            -l internap -C blue \
            -l cogent   -C red \
            --csv out1.csv --between 20130830T06:00,20130831T06:00 \
            --output graphs/$ISP.vc.png \
            --pivot 20130830T06:00 \
            --datefmt "%H" \
            --offset 72000 \
            --title "${ISP^} Download Rates" \
            --ylabel "Mbps" \
            --xlabel "Eastern Time (UTC-4)" \
            --ymax 68
            #--ymax 25
            #--pivot 20130829T08:00 \


    
done

