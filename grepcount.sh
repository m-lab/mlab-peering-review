#!/bin/bash

site=${1:?provide sitename}
isp=${2:?provide isp name}

export LC_ALL=C
cat cache/hops.$isp.$site.csv | grep -v as1 | awk -F, '{print $1,$2,$3,$4,$5}' | \
   while read as1 AS1 as2 AS2 count ; do
      if test "$as1" = "$as2" ; then continue ; fi
      printf "%s %s,%s\n" "$count" "$AS1" "$as2"
   done

#"s/^.*\(AS[0-9]\+\).*$/\1/"

