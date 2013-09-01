#!/usr/bin/env python


major_isps = ['at&t', 'cablevision', 'charter', 'comcast', 'cox', 'verizon', 'warner']

sitemap = { 
    'NewYork'       : { 'sites' : [ 'lga01', 'lga02'],
                        'extra' : [ 'rcn' ], },
    'LosAngeles'    : { 'sites' : [ 'lax01' ],
                        'extra' : [ ], },
    'Chicago'       : { 'sites' : [ 'ord01'],
                        'extra' : [ 'mediacom', 'rcn', 'wideopenwest'], },
    'SanFrancisco'  : { 'sites' : [ 'nuq01', 'nuq02'],
                        'extra' : [ 'sonic', 'webpass'], },
    'WashingtonDC'  : { 'sites' : [ 'iad01'],
                        'extra' : [ 'rcn' ] },
    'Dallas'        : { 'sites' : [ 'dfw01'],
                        'extra' : [ 'suddenlink' ], },
    'Atlanta'       : { 'sites' : [ 'atl01'],
                        'extra' : [ ], },
}

import itertools
import os
import sys
for city in sitemap:
    sites = sitemap[city]['sites']
    isps  = major_isps
    for site,isp in itertools.product(sites, isps):
        cmd = "./stages.sh %-12s %s '%s'" % (city, site, isp)
        print cmd
        os.system(cmd)

# NOTE: runs comparisons between the individual data created above.
os.system("./followup.sh")
