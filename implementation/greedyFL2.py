class City:
  def __init__(self, c, d):
    self.next = {}
    self.color = c
    self.pos = d
    self.fac = False

  def __str__(self):
    return f'City({self.fac},{self.next})'

  def setNext(self, j, new):
    self.next[j] = new
  
  def covered(self):
    self.fac = True

class Facility:
  def __init__(self, f):
    self.cost = f
    self.cities = []
    self.closest = -1
    self.orig = f

  def __str__(self):
    return f'Facility({self.orig},{self.closest},{self.cities})'
  
  def setClosest(self, i):
    self.closest = i

  def used(self):
    self.cost = 0

def printCF(dict):
  for i in range(dict[-1]):
    print(i," ",dict[i])

def initNext(j, cities, fac):
  lst = [i for i in range(cities[-1])]
  lst = sorted(lst, key = lambda x: cities[x].pos[j])
  for i in range(cities[-1]-1):
    cities[lst[i]].setNext(j, lst[i+1])
  cities[lst[cities[-1]-1]].setNext(j, -1)
  fac.setClosest(lst[0])

def findStar(fac, cit):
  star = -1
  cost = 10**cit[-1]
  go = False
  for i in range(cit[-1]):
    if cit[i].fac == False:
      go = True
  if not go:
    return star
  for j in range(fac[-1]):
    farthest = fac[j].closest
    commTemp = cit[farthest].pos[j]
    numC = 1
    costTemp = (commTemp + fac[j].cost) / numC
    if costTemp < cost:
      cost = costTemp
      star = [j, farthest]
    while cit[farthest].next[j] != -1:
      numC += 1
      farthest = cit[farthest].next[j]
      commTemp += cit[farthest].pos[j]
      costTemp = (commTemp + fac[j].cost) / numC
      if costTemp < cost:
        cost = costTemp
        star = [j, farthest]
  return star

def findClosest(j, start, cit):
  cls = start
  while cit[cls].fac and cit[cls].next[j] != -1:
    cls = cit[cls].next[j]
  return cls


def updateStar(fac, cit, star, q):
  j = star[0]
  fac[j].used()
  far = fac[j].closest
  cit[far].covered()
  c = cit[far].color
  q[c] -= 1
  if q[c] == 0:
    colorDone(cit,c)
    q[c] = -1
  fac[j].cities.append(far)
  while far != star[1] and cit[far].next[j] != -1:
    far = cit[far].next[j]
    if not cit[far].fac:
      cit[far].covered()
      c = cit[far].color
      q[c] -= 1
      if q[c] == 0:
        colorDone(cit,c)
        q[c] = -1
      fac[j].cities.append(far)
  
  if cit[far].next[j] != -1:
    fac[j].setClosest(cit[far].next[j])

  for f in range(fac[-1]):
    if f != j:
      cls = findClosest(f,fac[f].closest,cit)
      if cls != -1:
        fac[f].setClosest(cls)
        city = cls
        nxt = cit[city].next[f]
        while nxt != -1:
          while nxt != -1 and cit[nxt].fac:
            nxt = cit[nxt].next[f]
          cit[city].setNext(f,nxt)
          if nxt != -1:
            city = nxt
            nxt = cit[city].next[f]
  
def colorDone(cit, c):
  for i in range(cit[-1]):
    if cit[i].color == c:
      cit[i].covered()


def run(cities,facilities,q):
  for j in range(facilities[-1]):
    initNext(j,cities,facilities[j])

  while 1:
    starOpt = findStar(facilities,cities)
    if starOpt == -1:
      break
    updateStar(facilities, cities, starOpt, q)


  #printCF(cities)
  #printCF(facilities)

  cost = 0
  for j in range(facilities[-1]):
    if len(facilities[j].cities) != 0:
      cost += facilities[j].orig
      for i in facilities[j].cities:
        cost += cities[i].pos[j]

  return cost    


def main():
  cities = {-1 : 4,
         0 : City(0,[2,70]), 
         1 : City(0,[50,4]), 
         2 : City(1,[3,1]), 
         3 : City(1,[4,6])}
  facilities = {-1 : 2,
         0 : Facility(17), 
         1 : Facility(25)}
  q = [1,1]

  run(cities,facilities,q)
  
  cities2 = {-1 : 6,
             0 : City(0,[1,1000,1000]),
             1 : City(0,[1,1000,1000]),
             2 : City(0,[1000,1,1000]),
             3 : City(0,[1000,1,1000]),
             4 : City(0,[1000,1000,1]),
             5 : City(0,[1000,1000,20])}
  
  facilities2 = {-1 : 3,
                 0 : Facility(1),
                 1 : Facility(1),
                 2 : Facility(2)}
  
  q2 = [5]
  

  run(cities2,facilities2,q2)
  
main()