#!/bin/bash

awk --field-separator=, '
  function to_as_string(as_no) 
  {
    if (as_no == "NO AS")
      return as_no
    "grep " as_no " GeoIPASNum2.csv | head -n1 | sed \"s/^.*\\(AS.*$\\)/\\1/\"" | getline output
    return output;
  }
  {
  if ($1 != $2) { 
    print to_as_string($1) "(" $1 ")" "->" to_as_string($2) "(" $2 ")";
  }
}' cache/hops.csv

#"s/^.*\(AS[0-9]\+\).*$/\1/"

