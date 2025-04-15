class CityFacility:
    def __init__(self, color, cost):
        self.color = color
        self.orig = cost
        self.current = cost
        self.lstC = []
        self.cities = []
        self.covered = False
        self.isFac = False

    def __str__(self):
        return f'CityFacility({self.orig},{self.covered},{self.isFac},{self.cities})'

    def cover(self, q):
        if not self.covered:
            q[self.color] -= 1
            self.covered = True

    def uncover(self):
        self.covered = False

    def setClosest(self, i):
        self.closest = i

    def used(self):
        self.current = 0
        self.isFac = True

    def unuse(self):
        self.current = self.orig
        self.cities = []
        self.isFac = False


class City:
    def __init__(self, c):
        self.next = {}
        self.color = c
        self.covered = False

    def __str__(self):
        return f'City({self.covered},{self.color})'

    def setNext(self, j, new):
        self.next[j] = new

    def cover(self):
        self.covered = True

    def uncover(self):
        self.covered = False


class Facility:
    def __init__(self, f):
        self.cost = f
        self.cities = []
        self.closest = -1
        self.orig = f
        self.contributors = []
        self.open = False

    def __str__(self):
        return f'Facility({self.cost},{self.contributors})'

    def setClosest(self, i):
        self.closest = i

    def add_contr(self, i):
        self.contributors.append(i)

    def add_city(self, i):
        self.cities.append(i)

    def open_fac(self):
        self.open = True

    def payment(self, delta):
        self.cost -= delta

    def used(self):
        self.cost = 0

    def unuse(self):
        self.cost = self.orig
        self.cities = []
        self.contributors = []
        self.open = False


class TieredCity:
    def __init__(self, c):
        self.color = c
        self.covered = False

    def __str__(self):
        return f'City({self.color},{self.covered})'

    def cover(self):
        self.covered = True

    def uncover(self):
        self.covered = False


class TieredFacility:
    def __init__(self, f):
        self.cost = f
        self.tiers = {}
        self.current = f
        self.cities = []

    def __str__(self):
        return f'Facility({self.cost},{self.tiers},{self.cities})'

    def used(self):
        self.current = 0

    def new_tier(self, t):
        self.tiers[t] = []

    def add_city(self, i, t):
        self.tiers[t].append(i)

    def unused(self):
        self.current = self.cost
        self.cities = []
