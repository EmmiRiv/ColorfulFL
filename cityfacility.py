class CityFacility:
    def __init__(self, color, cost):
        self.color = color
        self.cost = cost
        self.contributors = []
        self.cities = []
        self.covered = False
        self.open = False
        self.orig_color = color
        self.assignment = -1
        self.freeze = -1

    def __str__(self):
        return f'CityFacility({self.orig_color},{self.covered},{self.open},{self.cities})'

    def cover(self):
        self.covered = True

    def uncover(self):
        self.covered = False

    def open_fac(self):
        self.open = True

    def unuse(self):
        self.cities = []
        self.open = False
        self.covered = False
        self.contributors = []
        self.assignment = -1
        self.freeze = -1

    def add_contr(self, i):
        self.contributors.append(i)

    def add_city(self, i):
        self.cities.append(i)

    def remove_city(self,i):
        self.cities.remove(i)

    def make_outlier(self):
        self.color = 0

    def set_assignment(self, j):
        self.assignment = j

    def set_freeze(self, a):
        self.freeze = a

class City:
    def __init__(self, c):
        self.color = c
        self.covered = False
        self.assignment = -1
        self.orig_color = c
        self.freeze = -1

    def __str__(self):
        return f'City({self.covered},{self.orig_color},{self.assignment})'

    def cover(self):
        self.covered = True

    def uncover(self):
        self.covered = False
        self.assignment = -1
        self.freeze = -1

    def set_assignment(self, j):
        self.assignment = j

    def make_outlier(self):
        self.color = 0

    def set_freeze(self, a):
        self.freeze = a


class Facility:
    def __init__(self, f):
        self.cost = f
        self.cities = []
        self.contributors = []
        self.open = False
        self.current = f

    def __str__(self):
        return f'Facility({self.cost},{self.open},{self.cities})'

    def setClosest(self, i):
        self.closest = i

    def add_contr(self, i):
        self.contributors.append(i)

    def add_city(self, i):
        self.cities.append(i)

    def remove_city(self, i):
        self.cities.remove(i)

    def open_fac(self):
        self.open = True


    def used(self):
        self.cost = 0

    def unuse(self):
        self.current = self.cost
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
