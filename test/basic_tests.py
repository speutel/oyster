__author__ = 'nabcos'

import unittest
from hamcrest import *
import oyster
import os
import mock
import oysterconfig
import tempfile
import shutil

class BasicTests(unittest.TestCase):

    test_dir = tempfile.mkdtemp()

    def create_dummy_config_file(self):
        """
        FIXME: we're only able to mock config if this file exists
        """
        if not os.path.exists("config"):
            os.mkdir("config")

        config_file = file("config/default", 'w')
        config_file.write("DUMMY")
        config_file.close()

    def setUp(self):
        super(BasicTests, self).setUp()

        self.create_dummy_config_file()

        test_config = {"savedir": self.test_dir, "basedir": self.test_dir, "vol_get_cmd": "echo 1", "vol_filter_regexp": "(.)"}

        oysterconfig.getConfig = mock.MagicMock(name="getConfig", return_value=test_config )
        oyster.ControlThread = mock.MagicMock(name="ControlThread")
        oyster.PlaylistBuilder = mock.MagicMock(name="PlaylistBuilder")

        self.underTest = oyster.Oyster()

    def tearDown(self):
        shutil.rmtree(self.test_dir)
        shutil.rmtree("config")
        super( BasicTests, self ).tearDown( )

    def testBasic(self):
        assert_that(self.underTest, not_none())

def main():
    unittest.main()

if __name__ == '__main__':
    main()
