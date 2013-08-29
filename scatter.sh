#!/usr/bin/env bash


set -x
for ISP in cablevision warner comcast ; do
#    ./ts_hops.py $ISP lga01
#    ./ts_hops.py $ISP lga02
    if test "$ISP" = "cablevision" ; then
        grep -E "as1|Private,AS6128" cache/tshops.$ISP.lga01.csv | sort -n > voxel2$ISP.csv
        grep -E "as1|PSI,AS6128"     cache/tshops.$ISP.lga02.csv | sort -n > cogent2$ISP.csv
    elif test "$ISP" = "comcast" ; then
        grep -E "as1|Voxel,AS13789"  cache/tshops.$ISP.lga01.csv | sort -n > voxel2$ISP.csv
        grep -E "as1|PSI,AS7922"     cache/tshops.$ISP.lga02.csv | sort -n > cogent2$ISP.csv
    elif test "$ISP" = "warner" ; then
        grep -E "as1|Voxel,AS23393"  cache/tshops.$ISP.lga01.csv | sort -n > voxel2$ISP.csv
        grep -E "as1|PSI,AS7843"     cache/tshops.$ISP.lga02.csv | sort -n > cogent2$ISP.csv
    fi
    sed -e 's/rate/voxel/g' -i '' voxel2$ISP.csv 
    sed -e 's/rate/cogent/g' -i '' cogent2$ISP.csv

    ./queryview.py --merge voxel2$ISP.csv \
                   --merge cogent2$ISP.csv \
                   --output out.csv --timestamp ts

    sort -n out.csv > out1.csv 

    ./queryview.py --timestamp ts \
            -l cogent -C red \
            -l voxel  -C blue \
            --csv out1.csv --between 20130829,20130830 \
            --output graphs/$ISP.vc.png \
            --pivot 20130829T00:00 \
            --datefmt "%H" \
            --ymax 25
            #--offset -28800 \
            #--pivot 20130829T08:00 \
done

