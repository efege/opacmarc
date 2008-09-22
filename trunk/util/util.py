# Python version notes
# subprocess: new in Python 2.4
# subprocess.check_call: new in Python 2.5


# Utility functions

import subprocess
import sys
import os

def error(msg = 'Error'):
    '''Displays an error message and exits.'''
    sys.exit(msg + '\n')


def run_command(command, msg='Error', env={}):
    '''Runs a system command and checks for an error.
    
    Accepts a string:
    
        run('mx tmp count=3 pft=mfn/ now')
        
    a list:
    
        run(['mx', 'tmp', 'count=3', 'pft=mfn/', 'now'])
        
    and a "broken" list (NOT SURE HOW/WHEN THIS WORKS!):
    
        run([
            "mx",
            "tmp",
            "count=3",
            "pft=mfn,x3,'!'/",
            "now"
        ])
    '''
    try:
        # NOTE: ENV is a global variable; shell=True is needed on Linux to avoid using lists for commands with arguments
        subprocess.check_call(command, env=env, shell=True)
    except subprocess.CalledProcessError:
        error(msg + ':\n  ' + command)


def emptydir(dir):
    '''Removes every file in a directory.'''
    
    # TO-DO: hacerlo recursivo. See 'rmall.py' in Programming Python:
    #    http://books.google.com/books?id=E6FcH4d-hAAC&pg=PA233&lpg=PA233&dq=python+rmall&source=web&ots=Xx3ulBkFBS&sig=pleFTG4fmym0b9UB6kXe-bplX9Y
    #    http://safari.oreilly.com/0596000855/python2-CHP-5-SECT-7
    try:
        for f in os.listdir(dir):
            fn = os.path.join(dir, f)
            if os.path.isfile(fn):
                os.remove(fn)
    except:
        error("Error al vaciar el directorio %s" % dir)
        raise
        
