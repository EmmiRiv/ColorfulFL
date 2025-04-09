from itertools import combinations
import csv
import math
import numpy as np
from FasterKmeans.Code import enhancedKmeans
import time
from cityfacility import TieredCity,TieredFacility

epsilon = 1.5

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
                t += 1
                fac[j].new_tier(t)
                fac[j].add_city(city, t)

        # for loop purposes
        fac[j].new_tier(t+1)
        fac[j].add_city(-1, t+1)

def find_star(fac, cit):
    cost = 10**cit[-1]
    star = [-1, -1]
    for j in range(fac[-1]):
        t = 0
        num = 0
        tieredC = []
        while fac[j].tiers[t][0] != -1:
            for i in fac[j].tiers[t]:
                if not cit[i].covered:
                    num += len(fac[j].tiers[t])
            if num == 0:
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
    cost = 0
    for j in range(fac[-1]):
        if len(fac[j].cities) != 0:
            cost += fac[j].cost
            for i in fac[j].cities:
                cost += dist[j][i]
    return cost

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
    cost = 10**cit[-1]

    for g in guesses:
        reset(fac, cit)
        for j in g:
            fac[j].used()
        costT = guess(fac, cit, dist, q.copy())
        #print(costT)
        if costT < cost:
            cost = costT
    return cost

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

    init_tiers(facE, citE, distE)

    print(run(facE, citE, distE, qE))



def main():
    #random_example()
    little_example()

main()
