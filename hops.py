#!/usr/bin/python
import socket
import struct

#
# from the web!
#
def iptoint(ip):
    return int(socket.inet_aton(ip).encode('hex'),16)

def as_array(filename,skip=1):
  ases = {}
  f = open(filename, 'r')
  skipped = 0
  counter = 0
  for line in f:
    if (skipped < skip):
      skipped += 1
      continue
    s = line.split(',')
    as_no = (s[2].split(' '))[0].lstrip("\"")
    low = s[0]
    high = s[1]
    ases[counter] = as_no + "," + low + "," + high
    counter += 1
  f.close()
  return ases

def lookup_as(ip, ases, cache):
  if (ip in cache):
    return cache[ip]
  for as_and_range in ases:
    s = ases[as_and_range].split(',')
    low = int(s[1])
    high = int(s[2])
    if (low <= ip and ip <= high):
      cache[ip] = s[0]
      return s[0]
  return "NO AS"

def rate_array(filename, skip=1):
  rate = {}
  f = open(filename, 'r')
  skipped = 0
  for line in f:
    if (skipped < skip):
      skipped += 1
      continue
    s = line.split(',')
    site = (s[1].rpartition('.'))[0]
    client = s[2]
    index = site + "," + client
    bw = s[3]
    rate[index] = bw
  f.close()
  return rate

def hop_array(filename, rates, ases, skip=1):
  hops = {}
  as_cache = {}
  f = open(filename, 'r')
  skipped = 0
  for line in f:
    if (skipped < skip):
      skipped += 1
      continue
    s = line.split(',')
    site = (s[1].rpartition('.'))[0]
    client = s[2]
    print "Another data point ..."
    hop_a = lookup_as(s[3], ases, as_cache)
    hop_b = lookup_as(s[4], ases, as_cache)
    rates_index = site + "," + client
    if (hop_a not in hops):
      hops[hop_a] = {}
    if (hop_b not in hops[hop_a]):
      hops[hop_a][hop_b] = ""
    hops[hop_a][hop_b] += rates[rates_index] + ","
  f.close()
  return hops

def write_hop_array(filename, hops):
  f = open(filename, 'w')
  for hop_a in hops.keys():
    for hop_b in hops[hop_a].keys():
      #
      # The number of results reported is a 
      # little off because of fence-post 
      # issue with trailing , in the list
      #
      f.write(hop_a + "," + hop_b + "," + str(len(hops[hop_a][hop_b].split(','))) + ":" + hops[hop_a][hop_b] + "\n")
  f.close()

rate = rate_array("cache/stage1.comcast.lga01.sql.csv")
ases = as_array("GeoIPASNum2.csv", 0)
hops = hop_array("cache/stage3.comcast.lga01.sql.csv", rate, ases)
write_hop_array("cache/hops.csv", hops)
