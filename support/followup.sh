#!/usr/bin/env bash

LEVEL3=green
INTERNAP=blue
COGENT=red
COGENT2=turquoise
OTHER=lightseagreen
XO=orange
XO2=mediumpurple

# NEW YORK 
$SCRIPT_ROOT/support/compare.sh NewYork lga01 comcast     $INTERNAP NewYork lga02 comcast     $COGENT
$SCRIPT_ROOT/support/compare.sh NewYork lga01 cablevision $INTERNAP NewYork lga02 cablevision $COGENT
$SCRIPT_ROOT/support/compare.sh NewYork lga01 verizon     $INTERNAP NewYork lga02 verizon     $COGENT
$SCRIPT_ROOT/support/compare.sh NewYork lga01 warner      $INTERNAP NewYork lga02 warner      $COGENT

# SanFrancisco
$SCRIPT_ROOT/support/compare.sh SanFrancisco nuq01 comcast $LEVEL3 SanFrancisco nuq02 comcast $OTHER

# LAX
$SCRIPT_ROOT/support/compare.sh LosAngeles lax01 cox      $COGENT2 LosAngeles lax01 comcast $COGENT
$SCRIPT_ROOT/support/compare.sh LosAngeles lax01 charter  $COGENT2 LosAngeles lax01 warner  $COGENT

# DFW
$SCRIPT_ROOT/support/compare.sh Dallas dfw01 cox $COGENT2 Dallas dfw01 comcast $COGENT
$SCRIPT_ROOT/support/compare.sh Dallas dfw01 cox $COGENT2 Dallas dfw01 verizon $COGENT
$SCRIPT_ROOT/support/compare.sh Dallas dfw01 cox $COGENT2 Dallas dfw01 warner  $COGENT
    
# IAD
$SCRIPT_ROOT/support/compare.sh WashingtonDC iad01 comcast $XO WashingtonDC iad01 verizon $XO2
$SCRIPT_ROOT/support/compare.sh WashingtonDC iad01 comcast $XO WashingtonDC iad01 warner  $XO2  
$SCRIPT_ROOT/support/compare.sh WashingtonDC iad01 verizon $XO WashingtonDC iad01 warner  $XO2  

# ATL 
$SCRIPT_ROOT/support/compare.sh Atlanta atl01 charter  $LEVEL3 Atlanta atl01 comcast $OTHER
$SCRIPT_ROOT/support/compare.sh Atlanta atl01 cox      $LEVEL3 Atlanta atl01 verizon $OTHER
$SCRIPT_ROOT/support/compare.sh Atlanta atl01 cox      $LEVEL3 Atlanta atl01 warner  $OTHER

# ORD 
$SCRIPT_ROOT/support/compare.sh Chicago ord01 charter  $LEVEL3 Chicago ord01 comcast $OTHER
$SCRIPT_ROOT/support/compare.sh Chicago ord01 charter  $LEVEL3 Chicago ord01 warner  $OTHER
