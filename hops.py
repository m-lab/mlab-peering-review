#!/usr/bin/python
import socket
import struct
import sys


#
# from the web!
#
def iptoint(ip):
    return int(socket.inet_aton(ip).encode('hex'),16)

def inttoip(ip):
    return socket.inet_ntoa(hex(ip)[2:].zfill(8).decode('hex'))

MANUAL_ASN_MAP = [
  (iptoint('67.59.224.1'), iptoint('67.59.255.254'), "AS6128 Cablevision Systems Corp."),
  (iptoint('65.19.96.0'), iptoint('65.19.127.255'), "AS6128 Cablevision Systems Corp."),
  (iptoint('64.15.0.0'), iptoint('64.15.15.255'), "AS6128 Cablevision Systems Corp."),
  (iptoint('10.0.0.0'), iptoint('10.255.255.255'), "AS000 Private Space."),
  (iptoint('96.32.0.0'), iptoint('96.42.255.255'), "AS20115 Charter Communications"),
]

AS2NAME={}
def get_asno(as_raw):
    as_long = as_raw.replace('"','').replace('&','').replace('-', ' ')
    as_split = as_long.split(' ')
    as_no = as_split[0].strip()
    AS2NAME[as_no] = as_no.strip()
    if len(as_split) > 1:
        AS2NAME[as_no] = as_split[1].strip()

    # Manually translate some AS shortnames
    AS2NAME[as_no] = AS2NAME[as_no].replace("MCI",   "Verizon")
    AS2NAME[as_no] = AS2NAME[as_no].replace("Voxel", "Internap")
    AS2NAME[as_no] = AS2NAME[as_no].replace("Time",  "TimeWarner")

    return as_no

def as_array(filename,skip_header=True):
  ases = {}
  f = open(filename, 'r')
  header_skipped = False
  counter = 0
  for line in f:
    if not header_skipped and skip_header:
      header_skipped=True
      continue
    s = line.split(',')
    as_no = get_asno(s[2])
    low = int(s[0])
    high = int(s[1])
    ases[counter] = (as_no,low,high)
    counter += 1
  for row in MANUAL_ASN_MAP:
    (low,high,as_long) = row
    as_no = get_asno(as_long)
    ases[counter] = (as_no,low,high) 
    counter += 1
  f.close()
  return ases

def lookup_as(ip, ases, cache):
  if (cache and ip in cache):
    return cache[ip]
  for as_and_range in ases:
    (as_no,low,high) = ases[as_and_range]
    if (low <= ip and ip <= high):
      if cache:
        cache[ip] = as_no
      return as_no
  # note: first-char as '[a-z]' make graphviz easier.
  # note: also only return first three octets to reduce number of 'unknowns'
  print inttoip(ip)
  return "x"+(inttoip(ip).rpartition('.'))[0].replace(".","")

def rate_array(filename, skip_header=True):
  rate = {}
  f = open(filename, 'r')
  header_skipped = False
  total_rates = 0
  for line in f:
    if not header_skipped and skip_header:
      header_skipped=True
      continue
    s = line.split(',')
    site = (s[1].rpartition('.'))[0]
    client = s[2]
    index = site + "," + client
    bw = float(s[3])
    ts = int(s[0])
    if index not in rate:
        rate[index] = []
    rate[index].append((ts,bw))
    total_rates += 1
  print "Found %s raw, client rates" % total_rates
  f.close()
  return rate

def hop_array(filename, rates, skip_header=True):
  hops = {}
  f = open(filename, 'r')
  header_skipped = False
  hop_rates = 0
  hop_count = 0
  hop_rates_saved = {}
  for line in f:
    if not header_skipped and skip_header:
      header_skipped=True
      continue
    s = line.split(',')
    site = (s[1].rpartition('.'))[0]
    client = s[2]
    hop_a = iptoint(s[3])
    hop_b = iptoint(s[4])
    #print "Another data point %s -> %s" % (s[3], s[4]) 
    rates_index = site + "," + client
    if (hop_a not in hops):
      hops[hop_a] = {}
    if (hop_b not in hops[hop_a]):
      hops[hop_a][hop_b] = []
    if (rates_index,hop_a,hop_b) not in hop_rates_saved:
      # Save rates between all distinct pairs of rates_index,hop_a,hop_b
      hop_rates_saved[(rates_index,hop_a,hop_b)] = True
      hops[hop_a][hop_b] += rates[rates_index]
      hop_rates += len(rates[rates_index])
      hop_count += 1
  print "Assigned %s rates to %s distinct hops" % (hop_rates, hop_count)
  f.close()
  return hops

def asify_hop_array(hops, ases):
  as_hops = {}
  as_cache = {}
  len_hop_a = len(hops)
  i_progress = 0.0
  i_rates = 0
  hop_saved = {}
  hop_count = 0
  for hop_a in hops:
    msg = "Finding primary, AS-Hop pairs ... %0.2f%%" % (100*i_progress/len_hop_a)
    sys.stdout.write("\b"*len(msg))
    sys.stdout.write(msg)
    sys.stdout.flush()
    for hop_b in hops[hop_a]:
      as_hop_a = lookup_as(hop_a, ases, as_cache)
      as_hop_b = lookup_as(hop_b, ases, as_cache)
      if as_hop_a not in as_hops:
        as_hops[as_hop_a] = {}
      if as_hop_b not in as_hops[as_hop_a]:
        as_hops[as_hop_a][as_hop_b] = []
      if (hop_a,hop_b) not in hop_saved:
        hop_saved[(hop_a,hop_b)] = True
        as_hops[as_hop_a][as_hop_b] += hops[hop_a][hop_b]
        i_rates += len(hops[hop_a][hop_b])
        hop_count += 1
    i_progress+=1.0
  print "\nFound %s rates in %s distinct AS hops" % (i_rates, hop_count)
  return as_hops

def write_hops(ts_file, avg_file, hops):
    ts_f = open(ts_file, 'w')
    ts_f.write("ts,as1,AS1,as2,AS2,rate\n")

    avg_f = open(avg_file, 'w')
    avg_f.write("as1,AS1,as2,AS2,count,avgrate\n")

    for ashop_a in hops.keys():
        if ashop_a not in AS2NAME: AS2NAME[ashop_a] = ashop_a
        for ashop_b in hops[ashop_a].keys():
            if ashop_b not in AS2NAME: AS2NAME[ashop_b] = ashop_b

            sum_test = 0
            avg_test = 0
            cnt_test = len(hops[ashop_a][ashop_b]) 

            # write each TS
            for (ts,bw) in hops[ashop_a][ashop_b]:
                output = [ts, ashop_a, AS2NAME[ashop_a], ashop_b, AS2NAME[ashop_b], bw]
                ts_f.write(",".join(map(str,output)) + "\n")
                sum_test += bw

            # write AVG 
            if cnt_test > 0:
                avg_test = sum_test/cnt_test

            output = [ashop_a, AS2NAME[ashop_a], ashop_b, AS2NAME[ashop_b], str(cnt_test), str(avg_test) ]
            avg_f.write(",".join(output) + "\n")

    ts_f.close()
    avg_f.close()


prefix = sys.argv[1]
site = sys.argv[2]
isp = sys.argv[3]

stage1_filename = "cache/stage1.%s.%s.%s.sql.csv" % (prefix,site,isp)
stage3_filename = "cache/stage3.%s.%s.%s.sql.csv" % (prefix,site,isp)
ts_filename     = "cache/tshops.%s.%s.%s.csv" % (prefix,site,isp)
avg_filename    = "cache/avghops.%s.%s.%s.csv" % (prefix,site,isp)

rate = rate_array(stage1_filename)
ases = as_array("GeoIPASNum2.csv", 0)
hops = hop_array(stage3_filename, rate)
as_hops = asify_hop_array(hops, ases)
write_hops(ts_filename, avg_filename, as_hops)
