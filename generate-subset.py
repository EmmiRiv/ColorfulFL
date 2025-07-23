import csv
from enhancedKmeans import Kmeans
import random
import math



pos = []
prb = 0.1
k = 100

with open("datasets/adult.ds", 'r') as a, open("subsets/adult-01-100.csv", 'w') as cli, \
    open("subsets/adult-01-100-fac.csv", 'w') as fac:
    datA = csv.reader(a, delimiter=' ')
    datCli = csv.writer(cli, delimiter=' ')
    datFac = csv.writer(fac, delimiter=' ')
    next(datA)
    for row in datA:
        if random.random() < prb:
            pos.append([float(row[j]) for j in range(1,7)])
            datCli.writerow(row)


    config = Kmeans(k,pos,0.01, initialCentroids=None)

    for v in config.centroidList:
        datFac.writerow(v.point.coordinates)

