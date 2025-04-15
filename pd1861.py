from itertools import combinations
import csv
import math
import numpy as np
from cityfacility import City,Facility

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
    dists = np.array([[2,70],[50,4],[3,1],[4,6]])

    return cities, facilities, q, dists

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

def order_data(dist, nc, nf):
    lst = []
    for i in range(nc):
        for j in range(nf):
            lst.append([i,j])
    lst = sorted(lst, key = lambda p : dist[p[0]][p[1]])
    return lst

def update(fac, cit, dist, c, f):
    for j in range(fac[-1]):
        if not fac[j].is_open() and c in fac[j].contributors:
            fac[j].payment(delta)

    if not cit[c].fac:
        if not fac[f].is_open():
            fac[f].add_contr(c)
        else:
            fac[f].add_city(c)
            cit[c].cover()


def run(cit, fac, q, dist, timeline):
    for event in timeline:
        c1 = timeline[e][0]
        f1 = timeline[e][1]

        update(fac, cit, dist, c1, f1)


def main():
    cit, fac, q, dist = little_data()

    timeline = order_data(dist, cit[-1], fac[-1])

    run(cit, fac, q, dist, timeline)

    printCF(fac)


main()
