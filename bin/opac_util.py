# coding=windows-1252

"""
Define variables y funciones de uso general.
"""


import sys
import os
import logging       # logs messages to console & file
#import logging.handlers   # for SMTPHandler 

# The subprocess module appeared with Python 2.4. If using an older version,
# import a copy of subprocess.py borrowed from Python 2.5.
# Based on http://coding.derkeiler.com/Archive/Python/comp.lang.python/2007-03/msg02717.html
# FIXME - subprocess.check_call: new in Python 2.5
try:
    import subprocess
except ImportError:
    import subprocess_ as subprocess


def error(msg = 'Error'):
    '''Displays an error message and exits.'''
    # FIXME - usar logger.error 
    sys.exit(msg + '\n')


# See also: http://www.python.org/doc/2.5.2/lib/module-commands.html (Unix only?)
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
        
# FIXME - para evitar duplicación de logs, tal vez sea mejor que setup_logger se ejecute en este
#         mismo módulo, y no en los que lo importen. El problema que queda por resolver es el
#         archivo a usar para el log de install.py (local-data no existe al iniciarse install.py,
#         a menos que ya venga incluida en el build). 
def setup_logger(log_file):
    # basado en http://www.onlamp.com/lpt/a/5914
    #create logger
    logger = logging.getLogger()
    logger.setLevel(logging.DEBUG)
    
    # console handler
    ch = logging.StreamHandler()
    ch.setLevel(logging.DEBUG)
    c_formatter = logging.Formatter("%(message)s")
    ch.setFormatter(c_formatter)
    logger.addHandler(ch)
    
    # file handler
    fh = logging.FileHandler(log_file)
    fh.setLevel(logging.DEBUG)
    f_formatter = logging.Formatter("%(asctime)s - %(levelname)s - %(message)s")
    fh.setFormatter(f_formatter)
    logger.addHandler(fh)
    
    # TO-DO: usando un SMTPHandler podemos enviar email al admin en caso de errores.
    # Ver: http://www.python.org/doc/2.5.2/lib/node418.html
    # Testeado en la UNS sin éxito, 2008-10-17
    # Para usar smtp authentication, ver: http://markmail.org/message/elhjphn222c3kg2w
    #mh = logging.handlers.SMTPHandler(mailhost, fromaddr, toaddrs, subject)
    #mh.setLevel(logging.WARNING)
    #mh.setFormatter(f_formatter)
    #logger.addHandler(mh)
    
    return logger


def unique_sort_files(input_files, output_file=None):
    '''Concatenates a list of files, removes duplicates, and sorts the
       resulting list.
       If an output file is specified, the result is written to it.
    '''
    # Necesitamos eliminar duplicados y ordenar (o al revés, pero entonces el
    # método de eliminación de duplicados debe preservar el orden).
    # Usamos por ahora una método que usa dict.fromkeys, tomado de:
    #      sorted unique elements from a list; using 2.3 features
    #      <http://mail.python.org/pipermail/python-list/2003-January/178712.html>
    # NOTA: dict.fromkeys está disponible desde Python 2.3. 
    # TO-DO: ¿será más rápido de otra manera, p.ej. con sets?
    # Ver: Fastest way to uniqify a list in Python <http://www.peterbe.com/plog/uniqifiers-benchmark>
    #      Recipe 52560: Remove duplicates from a sequence <http://code.activestate.com/recipes/52560/>

    all_lines = []
    for filename in input_files:
        f = open(filename, 'r')
        all_lines.extend(f.readlines())
        f.close()
        
    unique_lines = dict.fromkeys(all_lines).keys()
    unique_lines.sort()
    
    if not output_file is None:
        o = open(output_file, 'w')
        o.writelines(unique_lines)
        o.close()
    else:
        return unique_lines
    

APP = 'app'
# El nombre de este directorio sólo debería aparecer explícitamente aquí
# y en algunos archivos .xis (e.g. read-param.xis).
LOCAL_DATA = 'local-data'

parent_dir = os.path.join(os.path.dirname(sys.argv[0]), '..', '..') 
ROOT_DIR = os.path.abspath(parent_dir)
LOCAL_DATA_DIR = os.path.join(ROOT_DIR, LOCAL_DATA)
APP_DIR = os.path.join(ROOT_DIR, APP)

CISIS_PATH = os.path.join(APP_DIR, 'bin', 'cisis')
if not os.path.isdir(CISIS_PATH):
    print
    print "No se encuentra el directorio con los utilitarios cisis:\n    %s" % CISIS_PATH
    sys.exit()
