#!/bin/bash

PREFIX=${1:?HELP: Prefix name, such as city.}
SITE=${2:?HELP: Please provide an M-Lab site name, i.e. lga01, lax01, etc.}
ISP=${3:?HELP: Please provide a short ISP name, i.e. warner, comcast, verizon}

export LC_ALL=C
cat cache/avghops.$PREFIX.$SITE.$ISP.csv | grep -v as1 | awk -F, '{print $1,$2,$3,$4,$5}' | \
   while read as1 AS1 as2 AS2 count ; do
      if test "$as1" = "$as2" ; then continue ; fi
      printf "%s %s,%s\n" "$count" "$AS1" "$as2"
   done

