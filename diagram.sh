#!/bin/bash

export LC_ALL=C

PREFIX=${1:?HELP: Prefix name, such as city.}
SITE=${2:?HELP: Please provide an M-Lab site name, i.e. lga01, lax01, etc.}
ISP=${3:?HELP: Please provide a short ISP name, i.e. warner, comcast, verizon}

GVFILE=input/dot.$PREFIX.$SITE.$ISP.gv
GVPNG=graphs/dot.$PREFIX.$SITE.$ISP.png
HOPSFILE=cache/avghops.$PREFIX.$SITE.$ISP.csv

set -x

rm -f $GVFILE
cat <<EOF > $GVFILE
digraph TrafficLights {
overlap=false;
EOF

cat $HOPSFILE | grep -v as1 | awk -F, '{print $1,$2,$5}' | \
   sort | uniq | \
   while read as1 AS1 count ; do
      if test -z "$AS1" ; then
         AS1=$as1
      fi
      if test $count -gt 200 ; then
          printf "$as1[label=\"$AS1\"];\n"
      fi
   done >> $GVFILE
cat $HOPSFILE | grep -v as1 | awk -F, '{print $1,$2,$3,$4,$5,$6}' | \
   while read as1 AS1 as2 AS2 count rate ; do
      if test "$as1" = "$as2" ; then continue ; fi
      if test $count -gt 200 ; then
          printf "$as1->$as2 [ label=\"%0.2f\\\\n%d\\\\n%s\"];\n" "$rate" "$count" "$as2"
      fi
   done >> $GVFILE

if test "$2" = "lga01" ; then
    site=Internap
elif test "$2" = "lga02" ; then
    site=Cogent
fi

cat <<EOF  >> $GVFILE
overlap=false;
label="$PREFIX $SITE to $ISP";
fontsize=12;
}
EOF

dot -Tpng $GVFILE -o $GVPNG
