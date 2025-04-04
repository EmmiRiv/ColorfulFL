from itertools import combinations
import csv
import math
from ucimlrepo import fetch_ucirepo
import pandas as pd
import numpy as np

class CityFacility:
    def __init__(self, color, cost):
        self.color = color
        self.orig = cost
        self.current = cost
        self.closest = -1
        self.cities = []
        self.covered = False
        self.next = {}

    def __str__(self):
        return f'CityFacility({self.current},{self.color},{self.covered},{self.cities})'

    def setNext(self, j, new):
        self.next[j] = new

    def cover(self):
        self.covered = True

    def uncover(self):
        self.covered = False

    def setClosest(self, i):
        self.closest = i

    def used(self):
        self.current = 0

    def unuse(self):
        self.current = self.orig
        self.cities = []

def printCF(dict):
    for i in range(dict[-1]):
        print(i," ",dict[i])

def printF(cit, facC, citC, d):
    for jF in range(len(facC)):
        j = facC[jF]
        print("%d %f" % (j, cit[j].orig))
        for i in citC[jF]:
            print("        %d %d %f" % (i, cit[i].color, d[i][j]))

def initNext(j, cit, d):
      lst = [i for i in range(cit[-1])]
      lst = sorted(lst, key = lambda x: d[x][j])
      for i in range(cit[-1]-1):
          cit[lst[i]].setNext(j, lst[i+1])
      cit[lst[cit[-1]-1]].setNext(j, -1)
      cit[j].setClosest(lst[0])

def findStar(cit, d):
    star = -1
    cost = 10**cit[-1]
    go = False
    for i in range(cit[-1]):
        if cit[i].covered == False:
            go = True
    if not go:
      return star
    for j in range(cit[-1]):
        if not cit[j].covered:
            farthest = cit[j].closest
            commTemp = d[farthest][j]
            numC = 1
            #print(commTemp)
            #print(fac[j].current)
            costTemp = (commTemp + cit[j].current) / numC
            if costTemp < cost:
                  cost = costTemp
                  star = [j, farthest]
            while cit[farthest].next[j] != -1:
                  numC += 1
                  farthest = cit[farthest].next[j]
                  commTemp += d[farthest][j]
                  costTemp = (commTemp + cit[j].current) / numC
                  if costTemp < cost:
                        cost = costTemp
                        star = [j, farthest]
    return star

def findClosest(j, start, cit):
      cls = start
      while cit[cls].covered and cit[cls].next[j] != -1:
          cls = cit[cls].next[j]
      return cls


def updateStar(cit, star, q):
      j = star[0]
      cit[j].used()
      far = cit[j].closest
      cit[far].cover()
      c = cit[far].color
      q[c] -= 1
      if q[c] == 0:
            colorDone(cit,c)
            q[c] = -1
      cit[j].cities.append(far)
      while far != star[1] and cit[far].next[j] != -1:
            far = cit[far].next[j]
            if not cit[far].covered:
                  cit[far].cover()
                  c = cit[far].color
                  q[c] -= 1
                  if q[c] == 0:
                        colorDone(cit,c)
                        q[c] = -1
                  cit[j].cities.append(far)

      if cit[far].next[j] != -1:
          cit[j].setClosest(cit[far].next[j])

      for f in range(cit[-1]):
            if f != j and not cit[j].covered:
                  cls = findClosest(f,fac[f].closest,cit)
                  if cls != -1:
                        fac[f].setClosest(cls)
                        city = cls
                        nxt = cit[city].next[f]
                        while nxt != -1:
                              while nxt != -1 and cit[nxt].covered:
                                  nxt = cit[nxt].next[f]
                              cit[city].setNext(f,nxt)
                              if nxt != -1:
                                    city = nxt
                                    nxt = cit[city].next[f]

def colorDone(cit, c):
    for i in range(cit[-1]):
        if cit[i].color == c:
            cit[i].cover()


def guess(cit, q, d):
    reset(cit)
    #printCF(cit)
    for j in range(cit[-1]):
        initNext(j, cit, d)

    while 1:
        starOpt = findStar(cit, d)
        if starOpt == -1:
            break
        updateStar(cit, starOpt, q)

    cost = 0
    facC = []
    citC = []
    for j in range(cit[-1]):
        if len(cit[j].cities) != 0:
            facC.append(j)
            citC.append(cit[j].cities)
            cost += cit[j].orig
            for i in cit[j].cities:
                cost += d[i][j]
    return cost, citC, facC

def reset(cit):
    for i in range(cit[-1]):
        cit[i].uncover()
        cit[i].unuse()


def run(cit, q, d):
    faci = [i for i in range(cit[-1])]
    guesses = combinations(faci,len(q))
    #printCF(cit)
    cost = 10**cit[-1]
    citC = []
    facC = []
    for g in guesses:
        for j in g:
            cit[j].used()
        #printCF(cit)
        costTemp, citTemp, facTemp = guess(cit, q.copy(), d)
        #printCF(cit)
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

def adult_data():
    adult = fetch_ucirepo(id=2)
    n = 10

    datA = adult.data.features.head(n)

    citA = {}

    citA[-1] = n
    pos = []
    qA = [0,0]

    for i in range(n):
        ln = datA.loc[i]
        if ln['sex'] == "Male":
            c = 0
        else:
            c = 1
        citA[i] = CityFacility(c, ln['age'])
        qA[c] += 1
        pos.append([ln['hours-per-week'],ln['education-num']])

    dist = np.zeros((n,n))

    for i in range(n):
        for j in range(n):
            dist[i][j] = l2(pos[i],pos[j])

    cost, citC, facC = run(citA,[3,3],dist)
    print(cost)
    printF(citA, facC, citC, dist)

def little_data():
    cit = {-1 : 4,
            0 : CityFacility(0, 5),
            1 : CityFacility(0, 3),
            2 : CityFacility(0, 6),
            3 : CityFacility(0, 7)}
    dist = np.array([[0,1,3,5],
                     [1,0,4,1],
                     [3,4,0,10],
                     [5,1,10,0]])

    q = [3]

    print(run(cit, q, dist))

def main():

    #little_data()

    adult_data()


main()
