#! /usr/bin/env python

import sys
import os

if __name__ == "__main__":
  argv = sys.argv
  if len(argv) < 2:
    print "Usage: %s <executable>" % argv[0]
    sys.exit(1)

  section = os.popen('otool -s __TEXT __cstring %s' % argv[1]).read()
  chars = []
  for l in section.split("\n")[2:]:
    parts = l.split("\t")
    if len(parts) < 2:
      continue

    for sec in parts[1].split(" "):
      if sec == '':
        continue

      a = sec[6:8]
      b = sec[4:6]
      c = sec[2:4]
      d = sec[0:2]

      if a != '':
        chars.append(chr(int(a, 16)))

      if b != '':
        chars.append(chr(int(b, 16)))

      if c != '':
        chars.append(chr(int(c, 16)))

      if d != '':
        chars.append(chr(int(d, 16)))

  strings = "".join(chars).split('\x00')
  for s in strings:
    print s

