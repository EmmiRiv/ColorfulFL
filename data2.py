import csv
from random import random
import math

omega = 5
numcit = 100
numfac = 9

with open("datasets/random1.csv", 'w', newline='') as rdat:
  r = csv.writer(rdat, quoting=csv.QUOTE_MINIMAL)

  r.writerow([numcit,omega])
  for _ in range(numcit):
    r.writerow([math.floor(random()*omega), random()*numcit, random()*numcit])
  
  r.writerow([numfac])
  for _ in range(numfac):
    r.writerow([random()*numcit, random()*numcit, random()*numcit])

with open("datasets/random1.csv", 'r') as rdat, open("random1dist.csv", 'w', newline='') as met:
  r = list(csv.reader(rdat))
  d = csv.writer(met, quoting=csv.QUOTE_MINIMAL)
  cit = r[1:numcit+1]
  fac = r[numcit+2:]

  d.writerow([numcit,omega])
  for i in range(numcit):
    ir = [i,cit[i][0]]
    for f in fac:
      dist = math.sqrt((float(cit[i][1])-float(f[1]))**2+(float(cit[i][2])-float(f[2]))**2)
      ir.append(dist)
    d.writerow(ir)

  d.writerow([numfac])
  for j in range(numfac):
    d.writerow([j,fac[j][0]])