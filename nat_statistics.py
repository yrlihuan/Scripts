#! /usr/bin/env python

import sys

if __name__ == "__main__":
  if len(sys.argv) < 2:
    print "Usage: %s <file>" % sys.argv[0]
    sys.exit(1)

  path = sys.argv[1]
  f = open(path)
  count = {}
  # each line is like:
  # tcp 124.205.101.162:64997 192.168.3.104:64997 74.207.228.138:80 74.207.228.138:80
  for l in f.read().split("\n"):
    try:
      local_ip = l.split(" ")[2].split(":")[0]
    except:
      continue

    if local_ip in count:
      count[local_ip] += 1
    else:
      count[local_ip] = 1

  for ip in count:
    print "%s: %s" % (ip, count[ip])

