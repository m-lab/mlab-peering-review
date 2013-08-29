#!/bin/bash

export LC_ALL=C
cat cache/hops.$1.$2.csv | grep -v as1 | awk -F, '{print $1,$2,$3,$4,$5}' | \
   while read as1 AS1 as2 AS2 count ; do
      if test "$as1" = "$as2" ; then continue ; fi
      printf "%-10s -> %-10s %-4s %-15s -> %-15s\n" "$as1" "$as2" $count "$AS1" "$AS2"
   done

#"s/^.*\(AS[0-9]\+\).*$/\1/"

