__author__ = 'nabcos'

import unittest
from hamcrest import *

class BasicTests(unittest.TestCase):
    def testBasic(self):
        assert_that("x", equal_to("t"))

def main():
    unittest.main()

if __name__ == '__main__':
    main()
