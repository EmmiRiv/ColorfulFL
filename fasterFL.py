from itertools import combinations
import csv
import math
import numpy as np
from FasterKmeans.Code import enhancedKmeans, kpp
import time
from cityfacility import TieredCity,TieredFacility
import sys

epsilon = 1

def makeRandomPoint(n, lower, upper):
    return np.random.normal(loc=upper, size=[lower, n])

def random_example():
    pointList = []
    x = []
    y = []
    c = []
    numPoints = 10000
    dim = 10
    numClusters = 100
    k = 0
    for i in range(0,numClusters):
        num = int(numPoints/numClusters)
        p = makeRandomPoint(dim,num,k)
        k += 5
        pointList += p.tolist()

    start = time.time()
    config = enhancedKmeans.Kmeans(numClusters,pointList,1000,initialCentroids=None)
    print("Time taken:",time.time() - start)
    for c in config.centroidList:
        print(c.point.coordinates)

def printCF(dict):
    for i in range(dict[-1]):
        print(i," ",dict[i])

def printF(fac, cit, facC, citC, d):
    for jF in range(len(facC)):
        j = facC[jF]
        print("Facility {0:6d} cost {1:6.2f}".format(j, fac[j].cost))
        for i in citC[jF]:
            print("{0:6d} {1:2d} {2:6.2f}".format(i, cit[i].color, d[j][i]))
        print()

def l2(v1,v2):
    d = 0
    for i in range(len(v1)):
        d += (v1[i]-v2[i])**2
    return math.sqrt(d)

def init_tiers(fac, cit, dist):
    for j in range(fac[-1]):
        lst = [i for i in range(cit[-1])]
        lst = sorted(lst, key = lambda x: dist[j][x])
        t = 0
        fac[j].new_tier(t)
        while len(lst) != 0:
            city = lst.pop(0)
            if dist[j][city] <= (1+epsilon)**t:
                fac[j].add_city(city, t)
            else:
                if len(fac[j].tiers[t]) == 0:
                    fac[j].add_city(-2, t)
                t += 1
                fac[j].new_tier(t)
                fac[j].add_city(city, t)

        # for loop purposes
        fac[j].new_tier(t+1)
        fac[j].add_city(-1, t+1)

def find_star(fac, cit):
    cost = 10**fac[-1]
    star = [-1, -1]
    for j in range(fac[-1]):
        t = 0
        num = 0
        tieredC = []
        while fac[j].tiers[t][0] != -1:
            if fac[j].tiers[t][0] == -2:
                t += 1
            else:
                for i in fac[j].tiers[t]:
                    if not cit[i].covered:
                        num += len(fac[j].tiers[t])
                if num == 0 or (1 + epsilon)**t > cost:
                    t += 1
                else:
                    tC = 0
                    for i in fac[j].tiers[t]:
                        if not cit[i].covered:
                            tC += (1 + epsilon)**t
                    tieredC.append(tC)
                    costT = (fac[j].current + sum(tieredC)) / num
                    if costT < cost:
                        cost = costT
                        star = [j, t]
                    t += 1
    return star

def cover_color(cit, col):
    for i in range(cit[-1]):
        if cit[i].color == col:
            cit[i].cover()

def update_star(fac, cit, star, q):
    j = star[0]
    fac[j].used()
    end = star[1] + 1

    for t in range(end):
        for i in fac[j].tiers[t]:
            if not cit[i].covered:
                fac[j].cities.append(i)
                cit[i].cover()
                col = cit[i].color
                q[col] -= 1
                if q[col] <= 0:
                    cover_color(cit, col)
    if max(q) <= 0:
        return True
    return False

def find_cost(fac, dist):
    citC = []
    facC = []
    cost = 0
    for j in range(fac[-1]):
        if len(fac[j].cities) != 0:
            facC.append(j)
            citC.append(fac[j].cities)
            cost += fac[j].cost
            for i in fac[j].cities:
                cost += dist[j][i]
    return facC, citC, cost

def guess(fac, cit, dist, q):
    done = False
    while not done:
        st = find_star(fac, cit)
        done = update_star(fac, cit, st, q)

    #printCF(fac)
    return find_cost(fac, dist)

def reset(fac, cit):
    for i in range(cit[-1]):
        cit[i].uncover()
    for j in range(fac[-1]):
        fac[j].unused()

def run(fac, cit, dist, q):
    faci = [i for i in range(fac[-1])]
    guesses = combinations(faci,len(q))
    cost = 10**fac[-1]
    citF = []
    facF = []

    for g in guesses:
        reset(fac, cit)
        for j in g:
            fac[j].used()
        facT, citT, costT = guess(fac, cit, dist, q.copy())
        #print(costT)
        if costT < cost:
            cost = costT
            citF = citT
            facF = facT
    return facF, citF, cost

def little_example():
    citE = {-1 : 4,
             0 : TieredCity(0),
             1 : TieredCity(0),
             2 : TieredCity(0),
             3 : TieredCity(0)}

    facE = {-1 : 2,
             0 : TieredFacility(5),
             1 : TieredFacility(3)}

    distE = np.array([[2,1,3,5],[7,2,4,1]])

    qE = [2]

    print(run(facE, citE, distE, qE))

def distance_adult(n, F, k):
    """
    adult 45222 6
    2 race sex
    ['id', 'd1', 'd2', 'd3', 'd4', 'd5', 'd6', 'c1', 'c2']
    """

    citA = {}
    facA = {}

    citA[-1] = n
    facA[-1] = k
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
            citA[i] = TieredCity(c)
            qA[c] += 1
            pos.append([float(ln[j]) for j in range(1,7)])

    """
    kplus = kpp.KPP(k,X=pos)
    kplus.init_centers()
    cList = [kpp.Point(x,len(x)) for x in kplus.mu]
    """

    config = enhancedKmeans.Kmeans(k,pos,0.01, initialCentroids=None)
    distA = np.zeros((k,n))

    for j,c in enumerate(config.centroidList):
        for i in range(n):
            distA[j][i] = l2(pos[i], c.point.coordinates)
        facA[j] = TieredFacility(F)

    init_tiers(facA, citA, distA)

    return facA, citA, distA, qA

def main():
    #random_example()
    #little_example()

    n = int(sys.argv[1])
    F = float(sys.argv[2])
    k = int(sys.argv[3])

    start = time.time()
    fac, cit, dist, q = distance_adult(n, F, k)
    qT = [math.floor(q[i]*0.6) for i in range(len(q))]

    #print(dist)

    running = time.time()
    facL, citL, cost = guess(fac, cit, dist, qT)
    printF(fac, cit, facL, citL, dist)

    print("Cost: ", cost)
    print("Runtime: ", time.time()-running)
    print("Total time: ", time.time()-start)
main()
