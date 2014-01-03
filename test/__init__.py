__author__ = 'nabcos'

import unittest

def all_tests_suite():
    suite = unittest.TestLoader().loadTestsFromNames([
        'test.basic_tests'
    ])
    return unittest.TestSuite([suite])


def main():
    runner = unittest.TextTestRunner(verbosity=1 + sys.argv.count('-v'))
    suite = all_tests_suite()
    raise SystemExit(not runner.run(suite).wasSuccessful())


if __name__ == '__main__':
    import os
    import sys
    sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
    main()
