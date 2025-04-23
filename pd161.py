from itertools import combinations
import csv
import math
import sys
import time
import numpy as np
from cityfacility import City,Facility,CityFacility

def printCF(dict):
    for i in range(dict[-1]):
        print(i," ",dict[i])

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
    dists = np.transpose(np.array([[2,70],[50,4],[3,1],[4,6]]))



    cities0 = {-1 : 4,
            0 : City(0),
            1 : City(0),
            2 : City(0),
            3 : City(0)}
    facilities0 = {-1 : 2,
            0 : Facility(17),
            1 : Facility(25)}
    q0 = [2]

    return cities0, facilities0, q0, dists

def l2(v1,v2):
    d = 0
    for i in range(len(v1)):
        d += (v1[i]-v2[i])**2
    return math.sqrt(d)


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
            dist[j][i] = l2(pos[j],pos[i])

    return citA, qA, dist

def comb_little_data():
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

    return cit, q, dist

def order_data(dist, nc, nf):
    lst = []
    for i in range(nc):
        for j in range(nf):
            lst.append([j,i])
    lst = sorted(lst, key = lambda p : dist[p[0]][p[1]])
    return lst

def comb_order_data(dist, nc):
    lst = []
    for j in range(nc):
        for i in range(j, nc):
            lst.append([j,i])
    lst = sorted(lst, key = lambda p : dist[p[0]][p[1]])
    return lst

def compute_cost(fac, cit, dist):
    q = [0,0]
    cost = 0
    for j in range(fac[-1]):
        if fac[j].open:
            print(j, fac[j].cost)
            cost += fac[j].cost
            for i in fac[j].cities:
                cost += dist[j][i]
                print(" ", i, cit[i].orig_color, dist[j][i])
                q[cit[i].orig_color] += 1
            print()
    print(q)
    return cost


def color_done(col, cit, cur):
    for i in range(cit[-1]):
        if not cit[i].covered and cit[i].color == col:
            cit[i].cover()
            cit[i].set_freeze(cur)

def open_facJ(fac, j, cit, q, dist, cur):
    fac[j].open_fac()
    for contr in fac[j].contributors:
        city = cit[contr]
        if city.covered and city.assignment != -1 and dist[city.assignment][contr] - dist[j][contr] > 0:
            fac[city.assignment].remove_city(contr)
            city.set_assignment(j)
            fac[j].add_city(contr)
        if not city.covered:
            city.cover()
            city.set_assignment(j)
            fac[j].add_city(contr)
            col = city.color
            q[col] -= 1
            if q[col] <= 0:
                color_done(col, cit, cur)




def update(fac, cit, q, dist, c, f):
    cur = dist[f][c]
    if not cit[c].covered and fac[f].open:
        fac[f].add_city(c)
        cit[c].cover()
        cit[c].set_assignment(f)
        col = cit[c].color
        q[col] -= 1
        if q[col] <= 0:
            color_done(col, cit, cur)
    elif not fac[f].open:
        fac[f].add_contr(c)


    for j in range(fac[-1]):
        if not fac[j].open:
            payment = 0
            for contr in fac[j].contributors:
                city = cit[contr]
                if not city.covered:
                    payment += (cur - dist[j][contr])
                elif city.assignment != -1:
                    payment += max([0, (dist[city.assignment][contr]-dist[j][contr])])
                else:
                    payment += (cur - city.freeze)
                if payment >= fac[j].cost:
                    open_facJ(fac, j, cit, q, dist, cur)
                    break


    if max(q) <= 0:
        return False
    return True


def run(cit, fac, q, dist, timeline):
    for event in timeline:
        f1 = event[0]
        c1 = event[1]

        go = update(fac, cit, q, dist, c1, f1)
        if not go:
            break

def small():
    cit, fac, q, dist = little_data()

    citC, qC, distC = comb_little_data()

    timeline = order_data(dist, cit[-1], fac[-1])

    timelineC = comb_order_data(distC, citC[-1])

    run(cit, fac, q, dist, timeline)
    cost = compute_cost(fac, cit, dist)
    print(cost)
    print("--------")

    run(citC, citC, qC, distC, timelineC)
    costC = compute_cost(citC, citC, distC)
    print(costC)
    print("--------")

def main():
    #small()

    n = int(sys.argv[1])
    F = float(sys.argv[2])
    r = float(sys.argv[3])
    citA, qA, distA = distance_adult(n,F)
    timelineA = comb_order_data(distA, citA[-1])
    m = math.floor(r*min(qA))
    qT = [math.floor(r*q) for q in qA]
    run(citA, citA, [m,m], distA, timelineA)
    costA = compute_cost(citA, citA, distA)
    print(costA)
    print("--------")


main()
