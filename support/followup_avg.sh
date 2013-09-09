#!/usr/bin/env bash

set -x
set -e

#$SCRIPT_ROOT/support/stages_avg.sh NewYork lga01 comcast 
#$SCRIPT_ROOT/support/stages_avg.sh NewYork lga02 comcast
#$SCRIPT_ROOT/support/compare_avg.sh NewYork lga01 comcast Internap \
#                                    NewYork lga02 comcast Cogent
#exit

$SCRIPT_ROOT/support/stages_avg.sh  NewYork lga01 "cablevision comcast warner verizon"
$SCRIPT_ROOT/support/stages_avg.sh  NewYork lga02 "cablevision comcast warner verizon"

$SCRIPT_ROOT/support/compare_avg.sh NewYork lga01 comcast Internap \
                                    NewYork lga02 comcast Cogent
$SCRIPT_ROOT/support/compare_avg.sh NewYork lga01 cablevision Internap \
                                    NewYork lga02 cablevision Cogent
$SCRIPT_ROOT/support/compare_avg.sh NewYork lga01 warner Internap \
                                    NewYork lga02 warner Cogent
$SCRIPT_ROOT/support/compare_avg.sh NewYork lga01 verizon Internap \
                                    NewYork lga02 verizon Cogent

exit

$SCRIPT_ROOT/support/stages_avg.sh  WashingtonDC iad01 comcast 
$SCRIPT_ROOT/support/stages_avg.sh  WashingtonDC iad01 verizon
$SCRIPT_ROOT/support/stages_avg.sh  WashingtonDC iad01 warner
$SCRIPT_ROOT/support/compare_avg.sh WashingtonDC iad01 comcast XO \
                                    WashingtonDC iad01 verizon XO
$SCRIPT_ROOT/support/compare_avg.sh WashingtonDC iad01 comcast XO \
                                    WashingtonDC iad01 warner  XO

$SCRIPT_ROOT/support/stages_avg.sh Dallas dfw01 cox
$SCRIPT_ROOT/support/stages_avg.sh Dallas dfw01 comcast
$SCRIPT_ROOT/support/stages_avg.sh Dallas dfw01 verizon
$SCRIPT_ROOT/support/stages_avg.sh Dallas dfw01 warner

$SCRIPT_ROOT/support/compare_avg.sh Dallas dfw01 cox     Cogent \
                                    Dallas dfw01 comcast Cogent
$SCRIPT_ROOT/support/compare_avg.sh Dallas dfw01 cox     Cogent \
                                    Dallas dfw01 verizon Cogent
$SCRIPT_ROOT/support/compare_avg.sh Dallas dfw01 cox     Cogent \
                                    Dallas dfw01 warner  Cogent
