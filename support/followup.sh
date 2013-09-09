#!/usr/bin/env bash

LEVEL3=green
INTERNAP=blue
COGENT=red
COGENT2=turquoise
#OTHER=blue
OTHER=turquoise
XO=orangered
XO2=mediumpurple

set -x
# NEW YORK 
$SCRIPT_ROOT/support/compare.sh NewYork lga01 comcast     $INTERNAP Internap \
                                NewYork lga02 comcast     $COGENT   Cogent
$SCRIPT_ROOT/support/compare.sh NewYork lga01 cablevision $INTERNAP Internap \
                                NewYork lga02 cablevision $COGENT   Cogent 
$SCRIPT_ROOT/support/compare.sh NewYork lga01 verizon     $INTERNAP Internap \
                                NewYork lga02 verizon     $COGENT   Cogent
$SCRIPT_ROOT/support/compare.sh NewYork lga01 warner      $INTERNAP Internap \
                                NewYork lga02 warner      $COGENT   Cogent

exit
# SanFrancisco
$SCRIPT_ROOT/support/compare.sh SanFrancisco nuq01 comcast $LEVEL3 Level3 \
                                SanFrancisco nuq02 comcast $OTHER  ISC

# LAX
$SCRIPT_ROOT/support/compare.sh LosAngeles lax01 cox      $COGENT2 Cogent \
                                LosAngeles lax01 comcast  $COGENT  Cogent
$SCRIPT_ROOT/support/compare.sh LosAngeles lax01 charter  $COGENT2 Cogent \
                                LosAngeles lax01 warner   $COGENT  Cogent

# DFW
$SCRIPT_ROOT/support/compare.sh Dallas dfw01 cox     $COGENT2 Cogent \
                                Dallas dfw01 comcast $COGENT  Cogent
$SCRIPT_ROOT/support/compare.sh Dallas dfw01 cox     $COGENT2 Cogent \
                                Dallas dfw01 verizon $COGENT  Cogent
$SCRIPT_ROOT/support/compare.sh Dallas dfw01 cox     $COGENT2 Cogent \
                                Dallas dfw01 warner  $COGENT  Cogent
    
# IAD
$SCRIPT_ROOT/support/compare.sh WashingtonDC iad01 comcast $XO  XO \
                                WashingtonDC iad01 verizon $XO2 XO
$SCRIPT_ROOT/support/compare.sh WashingtonDC iad01 comcast $XO  XO \
                                WashingtonDC iad01 warner  $XO2 XO  
$SCRIPT_ROOT/support/compare.sh WashingtonDC iad01 verizon $XO  XO \
                                WashingtonDC iad01 warner  $XO2 XO

# ATL 
$SCRIPT_ROOT/support/compare.sh Atlanta atl01 charter $LEVEL3 Level3 \
                                Atlanta atl01 comcast $OTHER  Level3 
$SCRIPT_ROOT/support/compare.sh Atlanta atl01 cox     $LEVEL3 Level3 \
                                Atlanta atl01 verizon $OTHER  Level3 
$SCRIPT_ROOT/support/compare.sh Atlanta atl01 cox     $LEVEL3 Level3 \
                                Atlanta atl01 warner  $OTHER  Level3 

# ORD 
$SCRIPT_ROOT/support/compare.sh Chicago ord01 charter $LEVEL3 Level3 \
                                Chicago ord01 comcast $OTHER  Level3
$SCRIPT_ROOT/support/compare.sh Chicago ord01 charter $LEVEL3 Level3 \
                                Chicago ord01 warner  $OTHER  Level3
