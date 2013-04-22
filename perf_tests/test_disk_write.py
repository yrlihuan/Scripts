import random

f = open('a', 'a+')
for i in xrange(0,100000):
  f.write("%s\n" % random.randint(0,i))
  #f.flush()
