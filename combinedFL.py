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

def initList(cit, d):
    for j in range(cit[-1]):
        lst = [i for i in range(cit[-1])]
        lst = sorted(lst, key = lambda x: d[x][j])
        cit[j].lstC = lst

def findStar(cit, d):
    star = [-1, -1]
    cost = 10**10
    for j in range(cit[-1]):
        if cit[j].isFac or not cit[j].covered:
            i = 0
            cum_sum = cit[j].current
            numC = 0
            costT = 0
            while i < cit[-1] and d[j][i] < cost:
                if cit[cit[j].lstC[i]].covered:
                    i += 1
                else:
                    numC += 1
                    cum_sum += d[j][i]
                    costT = cum_sum / numC
                    if costT < cost:
                        cost = costT
                        star = [j, i]
                    i += 1
    return star

def updateStar(cit, star, q):
    j = star[0]
    cit[j].used()
    cit[j].cover(q)
    end = star[1] + 1

    for l in range(end):
        i = cit[j].lstC[l]
        if not cit[i].covered:
            cit[j].cities.append(i)
            cit[i].cover(q)
            if q[cit[i].color] <= 0:
                colorDone(cit, cit[i].color, q)
    if max(q) <= 0:
        return True
    return False

def colorDone(cit, c, q):
    for i in range(cit[-1]):
        if cit[i].color == c:
            cit[i].cover(q)


def find_cost(cit, dist):
    citC = []
    facC = []
    cost = 0
    for j in range(cit[-1]):
        if cit[j].isFac:
            facC.append(j)
            citC.append(cit[j].cities)
            cost += cit[j].orig
            for i in cit[j].cities:
                cost += dist[j][i]
    return facC, citC, cost

def guess(cit, q, dist):
    done = False
    while not done:
        st = findStar(cit, dist)
        done = updateStar(cit, st, q)

    #printCF(fac)
    return find_cost(cit, dist)

def reset(cit):
    for i in range(cit[-1]):
        cit[i].uncover()
        cit[i].unuse()


def run(cit, q, d):
    faci = [i for i in range(cit[-1])]
    guesses = combinations(faci,len(q))
    #printCF(cit)
    cost = 10**10
    citC = []
    facC = []
    for g in guesses:
        print(g)
        reset(cit)
        for j in g:
            cit[j].used()
        facTemp, citTemp, costTemp = guess(cit, q.copy(), d)
        print(costTemp)
        if costTemp < cost:
            cost = costTemp
            citC = citTemp
            facC = facTemp

    return facC, citC, cost

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


    initList(cit, dist)
    return cit, dist, q

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

    initList(citA, dist)
    return citA, qA, dist

def main():

    """
    cit, d, q = little_data()
    facC, citC, cost = run(cit, q, d)
    print(cost)
    printF(cit, facC, citC, d)
    """

    n = int(sys.argv[1])
    F = float(sys.argv[2])
    g = int(sys.argv[3])

    start = time.time()
    citA, qA, distA = distance_adult(n, F)

    qT = [math.floor(qA[i]*0.6) for i in range(len(qA))]
    #print(qT)
    running = time.time()
    if g == 0:
        facC, citC, cost = run(citA,qT,distA)
    else:
        facC, citC, cost = guess(citA,qT,distA)

    printF(citA, facC, citC, distA)
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
