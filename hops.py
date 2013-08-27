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
  if (cache and ip in cache):
    return cache[ip]
  for as_and_range in ases:
    s = ases[as_and_range].split(',')
    low = int(s[1])
    high = int(s[2])
    if (low <= ip and ip <= high):
      if cache:
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

def hop_array(filename, rates, skip=1):
  hops = {}
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
    hop_a = s[3]
    hop_b = s[4]
    rates_index = site + "," + client
    if (hop_a not in hops):
      hops[hop_a] = {}
    if (hop_b not in hops[hop_a]):
      hops[hop_a][hop_b] = ""
    hops[hop_a][hop_b] += rates[rates_index] + ","
  f.close()
  return hops

def asify_hop_array(hops, ases):
  as_hops = {}
  as_cache = {}
  for hop_a in hops:
    for hop_b in hops[hop_a]:
      print "Hop pair ..."
      as_hop_a = lookup_as(iptoint(hop_a), ases, as_cache)
      as_hop_b = lookup_as(iptoint(hop_b), ases, as_cache)
      if as_hop_a not in as_hops:
        as_hops[as_hop_a] = {}
      if as_hop_b not in as_hops[as_hop_a]:
        as_hops[as_hop_a][as_hop_b] = ""
      as_hops[as_hop_a][as_hop_b] += hops[hop_a][hop_b]
  return as_hops

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
hops = hop_array("cache/stage3.comcast.lga01.sql.csv", rate)
as_hops = asify_hop_array(hops, ases)
write_hop_array("cache/hops.csv", as_hops)
#print lookup_as(iptoint("8.8.8.8"), ases, None)
