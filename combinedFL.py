from itertools import combinations
import csv
import math
import pandas as pd
import numpy as np
from cityfacility import CityFacility
import sys
import time

def printCF(dict):
    for i in range(dict[-1]):
        print(i," ",dict[i])


def printF(cit, facC, citC, d):
    for jF in range(len(facC)):
        j = facC[jF]
        print("Facility {0:6d} cost {1:6.2f}".format(j, cit[j].orig))
        for i in citC[jF]:
            print("{0:6d} {1:2d} {2:6.2f}".format(i, cit[i].color, d[i][j]))
        print()

def initNext(j, cit, d):
      lst = [i for i in range(cit[-1])]
      lst = sorted(lst, key = lambda x: d[x][j])
      cit[j].lstC = lst

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
                  if q[c] <= 0:
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

def adult_data(n):
    from ucimlrepo import fetch_ucirepo

    adult = fetch_ucirepo(id=2)

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
        pos.append([ln['hours-per-week'],ln['education-num'],ln['capital-gain'],ln['capital-loss']])

    dist = np.zeros((n,n))

    for i in range(n):
        for j in range(n):
            dist[i][j] = l2(pos[i],pos[j])

    return citA, qA, dist

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

def distance_adult(n, F):
    """
    adult 45222 6
    2 race sex
    ['id', 'd1', 'd2', 'd3', 'd4', 'd5', 'd6', 'c1', 'c2']
    """

    citA = {}

    citA[-1] = n
    pos = []
    qA = [0,0]

    with open("datasets/adult.ds", 'r') as a:
        datA = csv.reader(a, delimiter=' ')
        next(datA)
        for i in range(n):
            ln = next(datA)
            if ln[8] == 'Male':
                c = 0
            else:
                c = 1
            citA[i] = CityFacility(c, F)
            qA[c] += 1
            pos.append([float(ln[j]) for j in range(1,7)])

    dist = np.zeros((n,n))

    for i in range(n):
        for j in range(n):
            dist[i][j] = l2(pos[i],pos[j])

    return citA, qA, dist

def main():

    #little_data()

    n = int(sys.argv[1])
    F = float(sys.argv[2])
    g = int(sys.argv[3])

    start = time.time()
    citA, qA, distA = distance_adult(n, F)
    #printCF(citA)

    qT = [math.floor(qA[i]*0.6) for i in range(len(qA))]
    #print(qT)
    running = time.time()
    if g == 0:
        cost, citC, facC = run(citA,qT,distA)
    else:
        cost, citC, facC = guess(citA,qT,distA)

    #printF(citA, facC, citC, distA)
    print(cost)
    print("Runtime: ", time.time()-running)
    print("Total time: ", time.time()-start)

    """
    for i in range(citA[-1]):
        citA[i].outlier()
    cost, citC, facC = run(citA,[min(qA)],distA)
    print(cost)
    printF(citA, facC, citC, distA)
    """

main()
