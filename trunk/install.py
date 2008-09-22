# coding=windows-1252

# Script de instalación para OpacMarc
# Issue 10: http://code.google.com/p/opacmarc/issues/detail?id=10

# TO-DO: Considerar también la situación en que ya existe una instalación
# y se desea preservar los datos locales.

def run(command, msg = 'Error'):
    # FIXME! (see update-opac.py)
    ENV = {'PATH': os.getenv('PATH') + os.pathsep + 'G:\\programas\\cisis\\5.2\\1030'}  # CONFIG.get('Global', 'PATH_CISIS')
    return run_command(command, msg = msg, env = ENV)

def set_version():
    # Genera un identificador de la versión y lo inserta en el footer.
    # svnversion produce identificadores de la forma '322' o '322M'.
    # En el 2do caso, significa que se trata de la revisión 322 con
    # modificaciones locales.
    version = os.popen('svnversion').read()
    footer_file = file(FILES['footer'])
    aux_file = file('footer.tmp', 'w')
    aux_file.write(
        footer_file.read().replace('__VERSION__', '(rev. %s)' % version)
    )
    aux_file.close()
    shutil.move('footer.tmp', FILES['footer'])
    
    print "Identificador de version generado."

def replace_config_path(config_file):
    # Crea un archivo de configuración a partir de una plantilla y del valor
    # actual de OPACMARC_DIR.
    if os.path.isfile(config_file):
        print
        print "ATENCION: ya existe el archivo de configuracion %s." % os.path.abspath(config_file)
    else:
        try:
            f1 = open(config_file + '.dist', 'r')
            f2 = open(config_file, 'w')
            #for line in f1: f2.write(line.replace('__OPACMARC_DIR__', OPACMARC_DIR))
            f2.write(
                f1.read().replace('__OPACMARC_DIR__', OPACMARC_DIR)
            )
            f1.close()
            f2.close()
            print
            print 'Generado el archivo %s.' % os.path.abspath(config_file)
        except:
            print
            print "ERROR: No se pudo generar el archivo %s." % os.path.abspath(config_file)

def set_config():
    # Crea archivos de configuración.
    replace_config_path(FILES['cipar'])
    replace_config_path(FILES['httpd'])
    replace_config_path(FILES['local'])
    replace_config_path(FILES['update'])

def create_dirs():
    # En Windows crear directorio temp para búsquedas de wxis (también en Linux para cache?), y ajustar config.
    # No necesitamos tener ese dir en el repositorio; svn:ignore temp
    try:
        os.mkdir('temp')
        print
        print "Directorio temp creado."
    except:
        print
        print "ATENCION: No se pudo crear la carpeta temp."
      
    # Crear directorio logs, e incluir dentro de él un README?
    # No necesitamos tener ese dir en el repositorio; svn:ignore logs
    #try:
    #   os.mkdir('logs')
    #   print "Directorio logs creado."
    #except:
    #   print
    #   print "ATENCION: No se pudo crear la carpeta logs."

def create_db():

    # Crea las bases isis auxiliares a partir de archivos de texto (.id)
    # FIXME: ajustar saltos de línea de los .id (usar os.linesep?)
    run('id2i bases/id/country.id create=bases/common/country')
    run('id2i bases/id/lang.id create=bases/common/lang')
    run('id2i bases/id/dictgiz.id create=bases/common/dictgiz')
    run('id2i bases/id/oem2ansi.id create=admin/opac/oem2ansi')
    run('id2i bases/id/demo.id create=admin/work/demo/original/biblio')

    # Genera los invertidos correspondientes
    run('mx bases/common/country "fst=1 0 v1" fullinv=bases/common/country')
    run('mx bases/common/lang "fst=1 0 v1" fullinv=bases/common/lang')
    
    print
    print "Bases auxiliares creadas."

def create_table(table_type):
    f = open(FILES[table_type], 'w')
    values = list(getattr(tablas, table_type))
    while values:
        for val in values[:32]:
            f.write(val + ' ')
        f.write(os.linesep)
        values = values[32:]
    f.close()
    print
    print "Tabla %s creada." % table_type

def show_msg():    
    # Mostrar mensajes útiles para el usuario (tips, tareas que debe realizar luego de instalar)
    print
    print "Algunos mensajes para el admin."

# Ejecutar newdb.py con la base demo?
# Ejecutar update-opac.py para la base demo?
  
# Realizar tests? E.g. búsquedas con acentos y agrep.


# ---------------------
# MAIN
# ---------------------

import os
import sys
import shutil

OPACMARC_DIR = os.path.abspath(os.path.dirname(sys.argv[0]))
sys.path.insert(0, os.path.join(OPACMARC_DIR, 'util'))
from util import run_command, error
import tablas

# Archivos que crea o modifica el script de instalación.
# TO-DO: agregar aquí los de create_db()
FILES = {
    'footer' : os.path.join(OPACMARC_DIR, 'cgi-bin', 'opac', 'html', 'opac-footer.htm'),
    'cipar'  : os.path.join(OPACMARC_DIR, 'config', 'opac.cip'),
    'httpd'  : os.path.join(OPACMARC_DIR, 'config', 'httpd-opacmarc.conf'),
    'local'  : os.path.join(OPACMARC_DIR, 'config', 'local.conf'),
    'update' : os.path.join(OPACMARC_DIR, 'config', 'update.conf'),
    'actab'  : os.path.join(OPACMARC_DIR, 'util', 'ac-ansi.tab'),
    'uctab'  : os.path.join(OPACMARC_DIR, 'util', 'uc-ansi.tab'),
}

print '''
-----------------------------------------------------
  install.py - SCRIPT DE INSTALACION DE OPACMARC
-----------------------------------------------------
'''

set_version()
set_config()
create_dirs()
create_db()
create_table('actab')
create_table('uctab')
show_msg()
