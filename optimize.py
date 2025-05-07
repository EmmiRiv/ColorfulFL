from scipy.optimize import linprog
import enhancedKmeans
import math
import csv
import numpy as np


"""
min sum_{i in F} f_i y_i + sum_{j in P} sum_{i in F} d_{ij} x_{ij}

sum_{i in F} x_{ij} + z_j >= 1 for all j in P
x_{ij} <= y_i for all j in P, i in F
sum_{j in C_g} z_j <= l_g for all g in [omega]
x_{ij}, y_i, z_j >= 0 for all i in F, j in P
"""

def l2(v1,v2):
    d = 0
    for i in range(len(v1)):
        d += (v1[i]-v2[i])**2
    return math.sqrt(d)

def distance_adult(nc, nf):
    """
    adult 45222 6
    2 race sex
    ['id', 'd1', 'd2', 'd3', 'd4', 'd5', 'd6', 'c1', 'c2']
    """

    pos = []
    qA = [0,0]
    gA = []

    with open("datasets/adult.ds", 'r') as a:
        datA = csv.reader(a, delimiter=' ')
        next(datA)
        for i in range(nc):
            ln = next(datA)
            if ln[8] == 'Male':
                c = 0
            else:
                c = 1
            qA[c] += 1
            gA.append(c)
            pos.append([float(ln[j]) for j in range(1,7)])

    facs = enhancedKmeans.Kmeans(nf,pos,0.01,initialCentroids=None)


    dist = np.zeros((nf,nc))

    for i,c in enumerate(facs.centroidList):
        for j in range(nc):
            dist[i][j] = l2(pos[j],c.point.coordinates)

    return dist, qA, gA

def main():

    nc = 6
    nf = 2
    fp = 3

    dist_matr, demo, grps = distance_adult(nc, nf)

    om = len(demo)

    l_vals = [2,1]

    A = np.zeros((nc+om+nc*nf, nc*nf+nc+nf))
    b = np.zeros((nc+om+nc*nf, 1))
    f = np.zeros((nc+om+nc*nf, 1))

    for i in range(nf):
        for j in range(nc):
            f[i*nc+j] = dist_matr[i][j]
        f[nc*nf+nc+i] = fp

    for j in range(nc):
        b[j] = -1
        for i in range(nf):
            A[j][i*nc+j] = -1
            A[nc+i*nc+j][i*nc+j] = 1
            A[nc+i*nc+j][nc*nf+nc+i] = -1
        A[j][nc*nf+j] = -1


    for g in range(om):
        b[nc+nc*nf+g] = l_vals[g]
        for j in range(nc):
            if grps[j] == g:
                A[nc+nc*nf+g][nc*nf+j] = 1

    opt = linprog(c = f, A_ub = A, b_ub = b)
    print(opt.fun)

main()
