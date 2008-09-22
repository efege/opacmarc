# coding=windows-1252

# Script de instalación para OpacMarc
# Issue 10: http://code.google.com/p/opacmarc/issues/detail?id=10

# TO-DO: Considerar también la situación en que ya existe una instalación
# y se desea preservar los datos locales.


def set_version():
    # Genera un identificador de la versión y lo inserta en opac-footer.htm
    version = os.popen('svnversion').read()
    footer_file = file('cgi-bin/opac/html/opac-footer.htm')
    footer_file.write(
        footer_file.read().replace('__VERSION__', 'rev. %s' % version)
    )

def create_db():
    # Crea las bases isis auxiliares a partir de archivos de texto (.id)
    # TO-DO: ajustar saltos de línea (usar os.linesep?)?
    run_command('id2i bases/id/country.id create=bases/common/country')
    run_command('id2i bases/id/lang.id create=bases/common/lang')
    run_command('id2i bases/id/dictgiz.id create=bases/common/dictgiz')
    run_command('id2i bases/id/biblio.id create=admin/work/demo/original/biblio')

    # Genera los invertidos correspondientes
    run_command('mx bases/common/country "fst=1 0 v1" fullinv=bases/common/country')
    run_command('mx bases/common/lang "fst=1 0 v1" fullinv=bases/common/lang')

# Cambiar saltos de línea en archivos .tab (usar os.linesep?)

def set_config():
    # Ajusta los paths en los archivos de configuración a partir de plantillas.

    # Tomamos como base un cipar incluido en la distribución y lo adecuamos a nuestro OPACMARC_DIR.
    # Hay que usar el path *absoluto* para el cipar
    CIPAR = os.path.join(OPACMARC_DIR, 'opac', 'opac.cip')
    try:
        f1 = open(CIPAR + '.dist', 'r')  # archivo CIPAR de la distribución
        f2 = open(CIPAR, 'w')
        #for line in f1: f2.write(line.replace('__OPACMARC_DIR__', OPACMARC_DIR))
        f2.write(
            f1.read().replace('__OPACMARC_DIR__', OPACMARC_DIR)
        )
        f1.close()
        f2.close()
    except:
        error("No se pudo generar el archivo cipar.")

    # TO-DO: lo mismo con local.conf, httpd-opacmarc.conf

def create_dirs():    
    # En Windows crear directorio temp para búsquedas de wxis (también en Linux para cache?), y ajustar config.
    # No necesitamos tener ese dir en el repositorio; svn:ignore temp
    os.mkdir('temp')
      
    # Crear directorio logs, e incluir dentro de él un README?
    # No necesitamos tener ese dir en el repositorio; svn:ignore logs
    os.mkdir('logs')

def show_msg():    
    # Mostrar mensajes útiles para el usuario (tips, tareas que debe realizar luego de instalar)
    print "Mensajes"

# Ejecutar newdb.py con la base demo?
# Ejecutar update-opac.py para la base demo?
  
# Realizar tests? E.g. búsquedas con acentos y agrep.


import os
import sys

OPACMARC_DIR = os.path.abspath(os.path.dirname(sys.argv[0]))
sys.path.insert(0, os.path.join(OPACMARC_DIR, 'util'))
from util import run_command, error

set_version()
create_db()
set_config()
create_dirs()
show_msg()
