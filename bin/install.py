#!/usr/bin/python
# coding=windows-1252

"""
Script de instalación para OpacMarc
Issue 10: http://code.google.com/p/opacmarc/issues/detail?id=10

TO-DO: Considerar también la situación en que ya existe una instalación
y se desea preservar los datos locales.
"""

import os
import sys
import shutil

from opac_util import run_command, error, OPACMARC_DIR, LOCAL_DATA_DIR
import tablas


# Archivos que crea o modifica el script de instalación.
# TO-DO: agregar aquí los que usa create_db()
FILES = {
    'footer'       : os.path.join(OPACMARC_DIR, 'cgi-bin', 'html', 'opac-footer.htm'),
    'cipar-opac'   : os.path.join(OPACMARC_DIR, 'config', 'update.cip'),
    'cipar-update' : os.path.join(OPACMARC_DIR, 'config', 'opac.cip'),
    'conf-local'   : os.path.join(LOCAL_DATA_DIR, 'config', 'local.conf'),
    'conf-update'  : os.path.join(LOCAL_DATA_DIR, 'config', 'update.conf'),
    'conf-httpd'   : os.path.join(OPACMARC_DIR, 'config', 'httpd-opacmarc.conf'),
    'actab'        : os.path.join(OPACMARC_DIR, 'util', 'ac-ansi.tab'),
    'uctab'        : os.path.join(OPACMARC_DIR, 'util', 'uc-ansi.tab'),
}

CISIS_PATH = os.path.join(OPACMARC_DIR, 'bin', 'cisis-1660')
if not os.path.isdir(CISIS_PATH):
    print
    print "No se encuentra el directorio con los utilitarios cisis:\n    %s" % CISIS_PATH
    sys.exit()


def run(command, msg = 'Error'):
    # FIXME! (see update-opac.py)
    #ENV = {'PATH': os.getenv('PATH') + os.pathsep + 'G:\\programas\\cisis\\5.2\\1660'}  # CONFIG.get('Global', 'PATH_CISIS')
    ENV = {}
    return run_command(command, msg = msg, env = ENV)

def set_version():
    """Genera un identificador de la versión y lo inserta en el footer."""
    # svnversion produce identificadores de la forma '322' o '322M'.
    # En el 2do caso, significa que se trata de la revisión 322 con
    # modificaciones locales.
    # FIXME - En Windows con Tortoise no tenemos svnversion. Alternativa: ver cómo
    # extraer la información de SubWCRev.exe
    # FIXME - Esto solo funciona cuando install.py se ejecuta sobre una working copy,
    # pero no sobre código exportado.
    #
    # Al hacer un build se genera un identificador de versión (fecha)
    version = os.popen('svnversion').read().replace(os.linesep, '')
    footer_file = file(FILES['footer'])
    aux_file = file('footer.tmp', 'w')
    aux_file.write(
        footer_file.read().replace('__VERSION__', '(rev. %s)' % version)
    )
    aux_file.close()
    shutil.move('footer.tmp', FILES['footer'])
    
    print "Identificador de version generado."

def create_from_template(template, destination, substitutions, force_forward=False, allow_overwrite=False):
    """Crea un archivo de configuración a partir de una plantilla."""
    
    if os.path.isfile(destination) and not allow_overwrite:
        print
        print "ATENCION: ya existe el archivo %s." % os.path.abspath(destination)
        print
    else:
        try:
            f1 = open(template, 'r')
            f2 = open(destination, 'w')
            content = f1.read()
            for sub in substitutions:
                if force_forward and os.sep == '\\':
                    sub[1] = sub[1].replace('\\', '/')
                content = content.replace(sub[0], sub[1])
            f2.write(content)
            f1.close()
            f2.close()
            print 'Generado el archivo %s.' % os.path.basename(destination)
        except:
            print
            print "ERROR: No se pudo generar el archivo %s." % os.path.basename(destination)
            print

def build_config_files():
    """Crea archivos de configuración con los paths apropiados."""

    # Find the platform-specific name for the wxis binary
    import platform
    if platform.system() == 'Windows':
        WXIS = 'wxis.exe'
    else:
        WXIS = 'wxis' 

    substitutions = (
        ['__OPACMARC_DIR__', OPACMARC_DIR],
        ['__LOCAL_DATA_DIR__', LOCAL_DATA_DIR],
        ['__WXIS__', WXIS],
    )
    
    for config_file in ('conf-httpd', 'conf-local', 'conf-update', 'cipar-opac', 'cipar-update'):
        template = os.path.join(OPACMARC_DIR, 'bin', 'install', 'templates', os.path.basename(FILES[config_file]) + '.dist')
        if config_file == 'conf-httpd':
            force_forward=True  # Apache requiere barras hacia adelante, incluso en Windows
        create_from_template(template, FILES[config_file], substitutions, force_forward=force_forward)
    
    # TO-DO: local.conf -> path agrep


def make_local_dirs():
    """Crea la estructura de directorios para los datos locales."""
    
    # TO-DO: agregar archivos (templates) en algunos de estos directorios?
    
    os.mkdir(LOCAL_DATA_DIR)
    for dir_name in ('bases', 'bin', 'config', 'htdocs', 'logs', 'temp'):
        os.mkdir(os.path.join(LOCAL_DATA_DIR, dir_name))
    for dir_name in ('css', 'img', 'js'):
        os.mkdir(os.path.join(LOCAL_DATA_DIR, 'htdocs', dir_name))

def create_aux_db():
    """Crea bases ISIS auxiliares."""
    
    # FIXME: ajustar saltos de línea de los .id (usar os.linesep?)
    # En Linux hay problemas si usan '\r\n', pero en Windows pueden usar '\n'
    
    # Crea las bases isis auxiliares a partir de archivos de texto (.id)
    run('%s/id2i bin/install/data/country.id create=util/country' % CISIS_PATH)
    run('%s/id2i bin/install/data/lang.id create=util/lang' % CISIS_PATH)
    run('%s/id2i bin/install/data/dictgiz.id create=util/dictgiz' % CISIS_PATH)
    
    run('%s/id2i bin/install/data/oem2ansi.id create=bin/update_db/oem2ansi' % CISIS_PATH)
    run('%s/id2i bin/install/data/delimsubcampo.id create=bin/update_db/delimsubcampo' % CISIS_PATH)
    
    # Genera los invertidos correspondientes
    run('%s/mx util/country "fst=1 0 v1" fullinv=util/country' % CISIS_PATH)
    run('%s/mx util/lang "fst=1 0 v1" fullinv=util/lang' % CISIS_PATH)
    
    print "Bases auxiliares creadas."

def create_table(table_type):
    """Crea una tabla con códigos de caracteres (actab , uctab)."""
    f = open(FILES[table_type], 'w')
    values = list(getattr(tablas, table_type))
    while values:
        f.write(' '.join(values[:32]) + '\n')  # CURIOSO: usando os.linesep en vez de '\n' no se puede leer la tabla en Windows
        values = values[32:]
    f.close()
    print "Tabla %s creada." % table_type

    
def show_end_msg():    
    # Mostrar mensajes útiles para el usuario (tips, tareas que debe realizar luego de instalar)
    print '''
-----------------------------------------------------
  INSTALACION FINALIZADA
-----------------------------------------------------
'''
    print '''
        - Configure permiso de escritura en temp y logs (mostrar ejemplo)
        - Use %s/config/httpd-opacmarc.conf como base para configurar Apache
        - Copie wxis (wxis.exe en Windows) en la carpeta cgi-bin
        - Windows: copie agrep.exe en la carpeta bin; Linux: cree un link simbólico a agrep desde bin/
        - Entre con un browser a http://...
        - Realizar tests? E.g. búsquedas con acentos y con errores (agrep).
    ''' % LOCAL_DATA_DIR


def main():

    print '''
-----------------------------------------------------
  %s - SCRIPT DE INSTALACION DE OPACMARC
-----------------------------------------------------
    ''' % os.path.basename(sys.argv[0])

    # Algunas rutas son relativas a OPACMARC_DIR
    os.chdir(OPACMARC_DIR)

    #set_version()
    make_local_dirs()
    build_config_files()
    create_aux_db()
    create_table('actab')
    create_table('uctab')
    
    show_end_msg()


if __name__ == "__main__":
    main()
    