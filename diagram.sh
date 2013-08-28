#!/bin/bash

export LC_ALL=C
cat <<EOF 
digraph TrafficLights {
overlap=false;
EOF
HOPSFILE=cache/hops.$1.$2.csv
cat $HOPSFILE | grep -v as1 | awk -F, '{print $1,$2,$5}' | \
   sort | uniq | \
   while read as1 AS1 count ; do
      if test -z "$AS1" ; then
         AS1=$as1
      fi
      if test $count -gt 200 ; then
          printf "$as1[label=\"$AS1\"];\n"
      fi
   done
cat $HOPSFILE | grep -v as1 | awk -F, '{print $1,$2,$3,$4,$5,$6}' | \
   while read as1 AS1 as2 AS2 count rate ; do
      if test "$as1" = "$as2" ; then continue ; fi
      if test $count -gt 200 ; then
          printf "$as1->$as2 [ label=\"%0.2f\\\\n%d\"];\n" "$rate" "$count"
      fi
   done

cat <<EOF 
overlap=false;
label="NY to $1";
fontsize=12;
}
EOF

# dot -Tpng output.gv > output.png 

