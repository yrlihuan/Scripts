import time
from datetime import datetime


s = ''
for i in xrange(1000000):
  datetime.today().strftime("%H:%M:%S")

  #t = time.time()
  #ti = int(t)
  #"%d:%d:%s" % (ti/3600%24, ti/60%60, t%60)


t = time.time()
ti = int(t)
print "%d:%d:%s" % (ti/3600%24, ti/60%60, t%60)
print datetime.today().strftime("%H:%M:%S")


