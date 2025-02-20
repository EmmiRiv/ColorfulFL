import random
import math

"""
datC = [ [i, x, y] ...]

datF = [ [j, x, y, f] ...]
"""
def make_random_data(c, f):
  datC = []
  datF = []
  for i in range(c):
    datC.append([i, c*random.random(), c*random.random()])
  for j in range(f):
    datF.append([j, c*random.random(), c*random.random(), f*random.random()])
  return datC,datF

def distCF(cl, fa):
  return math.sqrt((cl[1]-fa[1])**2 + (cl[2]-fa[2])**2)

def distProcess(datC, datF):
  dists = []
  for j in datF:
    dj = []
    for i in datC:
      dj.append([i[0],j[0],distCF(i,j)])
    dj = sorted(dj, key = lambda x: x[2])
    dists.append(dj)
  return dists

def computeCost(f, cl):
  cost = f
  for c in cl:
    cost += c[2]
  return cost/len(cl)
  
def findStar(dists, datF, cl):
  cost = 10**10
  star = -1
  for j in range(len(datF)):
    for i in range(1,cl):
      subC = dists[j][0:i]
      costT = computeCost(datF[j][3], subC)
      if costT < cost:
        cost = costT
        star = subC
  return star

def update(star, datC, datF, dists,res):
  j = star[0][1]
  datF[j][3] = 0
  for cl in star:
    i = cl[0]
    res[j].append(i)
    for clD in datC:
      if clD[0] == i:
        datC.remove(clD)
    for fac in dists:
      for clD in fac:
        if clD[0] == i:
          fac.remove(clD)


    
def main():
  citN = 10
  facN = 3
  citD, facD = make_random_data(citN, facN)
  citConst = citD.copy()
  facConst = facD.copy()
  sortD = distProcess(citD, facD)
  facA = [[] for _ in range(facN)]

  while 1:
    remS = findStar(sortD, facD, len(citD))
    if remS == -1:
      break
    update(remS, citD, facD, sortD, facA)

  cost = 0
  for j in range(len(facA)):
    cost += facConst[j][3]
    print(facA[j])
    for i in facA[j]:
      cost += distCF(citConst[i],facConst[j])
  print(cost)

main()