#!/usr/bin/python

import sys
import logging

def getConfig(filename):
    logging.basicConfig()
    log = logging.getLogger("oyster")
    try:
        conffile = open(filename, 'r')
        confline = conffile.readlines()
        conffile.close()
    except IOError:
        log.error("File " + filename + " does not exist!")
        sys.exit()
    config = {}
    for line in confline:
        posHash = line.find('#')
        posEq = line.find('=')
        if (posHash != -1) and (line[:(posHash)] == " "*(posHash+1)) :
            pass
        elif (posEq != -1 ) :
            config[line[:posEq]] = line[posEq+1:].rstrip() # remove whitespace (\n) 
    # for i in config.keys():
        # print i + ":" + config[i]
    return config
