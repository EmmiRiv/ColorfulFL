from itertools import combinations
import csv
import math
from ucimlrepo import fetch_ucirepo
import pandas as pd
import numpy as np

class CityFacility:
  def __init__(self, color, cost):
    self.color = color
    self.orig = cost
    self.current = cost
    self.closest = -1
    self.cities = []
    self.covered = False

  def __str__(self):
    return f'CityFacility({self.orig},{self.color},{self.covered},{self.cities})'