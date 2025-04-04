from itertools import combinations
import csv
import math
from ucimlrepo import fetch_ucirepo
import pandas as pd
import numpy as np

class City:
  def __init__(self, c):
    self.next = {}
    self.color = c
    self.fac = False

  def __str__(self):
    return f'City({self.fac},{self.color},{self.fac})'

  def setNext(self, j, new):
    self.next[j] = new
  
  def covered(self):
    self.fac = True
  
  def uncover(self):
    self.fac = False

class Facility:
  def __init__(self, f):
    self.cost = f
    self.cities = []
    self.closest = -1
    self.orig = f

  def __str__(self):
    return f'Facility({self.orig},{self.cities})'
  
  def setClosest(self, i):
    self.closest = i

  def used(self):
    self.cost = 0
  
  def unuse(self):
    self.cost = self.orig
    self.cities = []

def printCF(dict):
  for i in range(dict[-1]):
    print(i," ",dict[i])

def printF(fac,cit,facC,citC,d):
  for jF in range(len(facC)):
    j = facC[jF]
    print("%d %f" % (j, fac[j].orig))
    for i in citC[jF]:
      print("        %d %d %f" % (i, cit[i].color, d[i][j]))

def initNext(j, cities, fac,d):
  lst = [i for i in range(cities[-1])]
  lst = sorted(lst, key = lambda x: d[x][j])
  for i in range(cities[-1]-1):
    cities[lst[i]].setNext(j, lst[i+1])
  cities[lst[cities[-1]-1]].setNext(j, -1)
  fac.setClosest(lst[0])

def findStar(fac, cit, d):
  star = -1
  cost = 10**cit[-1]
  go = False
  for i in range(cit[-1]):
    if cit[i].fac == False:
      go = True
  if not go:
    return star
  for j in range(fac[-1]):
    farthest = fac[j].closest
    commTemp = d[farthest][j]
    numC = 1
    #print(commTemp)
    #print(fac[j].cost)
    costTemp = (commTemp + fac[j].cost) / numC
    if costTemp < cost:
      cost = costTemp
      star = [j, farthest]
    while cit[farthest].next[j] != -1:
      numC += 1
      farthest = cit[farthest].next[j]
      commTemp += d[farthest][j]
      costTemp = (commTemp + fac[j].cost) / numC
      if costTemp < cost:
        cost = costTemp
        star = [j, farthest]
  return star

def findClosest(j, start, cit):
  cls = start
  while cit[cls].fac and cit[cls].next[j] != -1:
    cls = cit[cls].next[j]
  return cls


def updateStar(fac, cit, star, q):
  j = star[0]
  fac[j].used()
  far = fac[j].closest
  cit[far].covered()
  c = cit[far].color
  q[c] -= 1
  if q[c] == 0:
    colorDone(cit,c)
    q[c] = -1
  fac[j].cities.append(far)
  while far != star[1] and cit[far].next[j] != -1:
    far = cit[far].next[j]
    if not cit[far].fac:
      cit[far].covered()
      c = cit[far].color
      q[c] -= 1
      if q[c] == 0:
        colorDone(cit,c)
        q[c] = -1
      fac[j].cities.append(far)
  
  if cit[far].next[j] != -1:
    fac[j].setClosest(cit[far].next[j])

  for f in range(fac[-1]):
    if f != j:
      cls = findClosest(f,fac[f].closest,cit)
      if cls != -1:
        fac[f].setClosest(cls)
        city = cls
        nxt = cit[city].next[f]
        while nxt != -1:
          while nxt != -1 and cit[nxt].fac:
            nxt = cit[nxt].next[f]
          cit[city].setNext(f,nxt)
          if nxt != -1:
            city = nxt
            nxt = cit[city].next[f]
  
def colorDone(cit, c):
  for i in range(cit[-1]):
    if cit[i].color == c:
      cit[i].covered()


def guess(cities,facilities,q,d):
  for j in range(facilities[-1]):
    initNext(j,cities,facilities[j],d)



  while 1:
    starOpt = findStar(facilities,cities,d)
    if starOpt == -1:
      break
    updateStar(facilities, cities, starOpt, q)


  #printCF(cities)
  #printCF(facilities)

  cost = 0
  facC = []
  citC = []
  for j in range(facilities[-1]):
    if len(facilities[j].cities) != 0:
      facC.append(j)
      citC.append(facilities[j].cities)
      cost += facilities[j].orig
      for i in facilities[j].cities:
        cost += d[i][j]
  return cost, citC, facC  

def reset(cit, fac):
  for i in range(cit[-1]):
    cit[i].uncover()
  for j in range(fac[-1]):
    fac[j].unuse()
      

def run(cit, fac, q, d):
  faci = [i for i in range(fac[-1])]
  guesses = combinations(faci,len(q))
  #printCF(cit)
  cost = 10**cit[-1]
  citC = []
  facC = []
  for g in guesses:
    reset(cit,fac)
    for j in g:
      fac[j].used()
    costTemp, citTemp, facTemp = guess(cit, fac, q.copy(),d)
    #printCF(fac)
    #print(costTemp)
    if costTemp < cost:
      cost = costTemp
      citC = citTemp
      facC = facTemp
  
  return cost, citC, facC

def l2(v1,v2):
  d = 0
  for i in range(len(v1)):
    d += (v1[i]-v2[i])**2
  return math.sqrt(d)

def random_data():
  citdat1 = {}
  facdat1 = {}
  qdat1 = [0]
  ddat1 = []
  citst = False
  facst = False
  with open("datasets/random1dist.csv", 'r') as dat1:
    f1 = csv.reader(dat1)
    for line in f1:
      if len(line) == 2 and not citst:
        citst = True
        qdat1 = qdat1*int(line[1])
        citdat1[-1] = int(line[0])
      elif len(line) == 1 and not facst:
        facst = True
        facdat1[-1] = int(line[0])
      elif citst and not facst:
        c=0
        c = int(line[1])
        qdat1[c] += 1
        citdat1[int(line[0])] = City(c)
        ddat1.append([float(d) for d in line[2:]])
      elif citst and facst:
        facdat1[int(line[0])] = Facility(float(line[1]))
 

  print(run(citdat1, facdat1, [math.floor(7/10*qdat1[i]) for i in range(len(qdat1))],ddat1))


def little_data():
  cities = {-1 : 4,
         0 : City(0), 
         1 : City(0), 
         2 : City(1), 
         3 : City(1)}
  facilities = {-1 : 2,
         0 : Facility(17), 
         1 : Facility(25)}
  q = [1,1]
  dists = np.array([[2,70],[50,4],[3,1],[4,6]])

  print(run(cities,facilities,q,dists))


  cities0 = {-1 : 4,
         0 : City(0), 
         1 : City(0), 
         2 : City(0), 
         3 : City(0)}
  facilities0 = {-1 : 2,
         0 : Facility(17), 
         1 : Facility(25)}
  q0 = [2]
  dists0 = np.array([[2,70],[50,4],[3,1],[4,6]])

  print(run(cities0,facilities0,q0,dists0))
  
  cities2 = {-1 : 6,
             0 : City(0),
             1 : City(0),
             2 : City(0),
             3 : City(0),
             4 : City(0),
             5 : City(0)}
  
  facilities2 = {-1 : 3,
                 0 : Facility(1),
                 1 : Facility(1),
                 2 : Facility(2)}
  
  q2 = [5]
  dists2 = np.array([[1,1000,1000],
                    [1,1000,1000],
                    [1000,1,1000],
                    [1000,1,1000],
                    [1000,1000,1],
                    [1000,1000,20]])

  print(run(cities2,facilities2,q2,dists2))


def adult_data():
  adult = fetch_ucirepo(id=2)

  datA = adult.data.features.head(10)

  citA = {}
  facA = {}

  citA[-1] = 10
  facA[-1] = 10
  pos = []
  qA = [0,0]

  for i in range(10):
    ln = datA.loc[i]
    if ln['sex'] == "Male":
      c = 0
    else:
      c = 1
    citA[i] = City(c)
    qA[c] += 1
    facA[i] = Facility(ln['age'])
    pos.append([ln['hours-per-week'],ln['education-num']])
  
  dist = np.zeros((10,10))
  
  for i in range(10):
    for j in range(10):
      dist[i][j] = l2(pos[i],pos[j])

  cost, citC, facC = run(citA,facA,[3,3],dist)
  print(cost)
  printF(facA,citA,facC,citC,dist)
  printCF(facA)


def main():
  
  #little_data()
  random_data()

  #adult_data()

main()