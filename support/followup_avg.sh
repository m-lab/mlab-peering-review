#!/usr/bin/env bash

set -x
set -e
# AVG

$SCRIPT_ROOT/support/stages_avg.sh NewYork lga01 "cablevision comcast warner verizon"
$SCRIPT_ROOT/support/stages_avg.sh NewYork lga02 "cablevision comcast warner verizon"

$SCRIPT_ROOT/support/compare_avg.sh NewYork lga01 comcast Internap \
                                    NewYork lga02 comcast Cogent
$SCRIPT_ROOT/support/compare_avg.sh NewYork lga01 cablevision Internap \
                                    NewYork lga02 cablevision Cogent
$SCRIPT_ROOT/support/compare_avg.sh NewYork lga01 warner Internap \
                                    NewYork lga02 warner Cogent
$SCRIPT_ROOT/support/compare_avg.sh NewYork lga01 verizon Internap \
                                    NewYork lga02 verizon Cogent

