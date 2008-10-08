# coding=windows-1252

"""
Script de instalación para OpacMarc
Issue 10: http://code.google.com/p/opacmarc/issues/detail?id=10

TO-DO: Considerar también la situación en que ya existe una instalación
y se desea preservar los datos locales.

TO-DO: en los archivos htmlpft de la base demo (y de una nueva base), corregir
automáticamente los paths que aparecen como contenido.
"""

import os
import sys
import shutil

OPACMARC_DIR = os.path.abspath(os.path.dirname(sys.argv[0]))

sys.path.insert(0, os.path.join(OPACMARC_DIR, 'util'))
from util import run_command, error
import tablas

LOCAL_DATA_DIR = os.path.join(OPACMARC_DIR, 'local-data')

# Archivos que crea o modifica el script de instalación.
# TO-DO: agregar aquí los que usa create_db()
FILES = {
    'footer' : os.path.join(OPACMARC_DIR, 'cgi-bin', 'html', 'opac-footer.htm'),
    'cipar-update' : os.path.join(LOCAL_DATA_DIR, 'config', 'opac.cip'),
    'cipar-opac' : os.path.join(LOCAL_DATA_DIR, 'config', 'update.cip'),
    'httpd' : os.path.join(LOCAL_DATA_DIR, 'config', 'httpd-opacmarc.conf'),
    'local' : os.path.join(LOCAL_DATA_DIR, 'config', 'local.conf'),
    'update' : os.path.join(LOCAL_DATA_DIR, 'config', 'update.conf'),
    'actab' : os.path.join(OPACMARC_DIR, 'util', 'ac-ansi.tab'),
    'uctab' : os.path.join(OPACMARC_DIR, 'util', 'uc-ansi.tab'),
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
    version = os.popen('svnversion').read().replace(os.linesep, '')
    footer_file = file(FILES['footer'])
    aux_file = file('footer.tmp', 'w')
    aux_file.write(
        footer_file.read().replace('__VERSION__', '(rev. %s)' % version)
    )
    aux_file.close()
    shutil.move('footer.tmp', FILES['footer'])
    
    print "Identificador de version generado."

def replace_config_path(config_file, force_forward=False):
    """Crea un archivo de configuración a partir de una plantilla y del valor actual de OPACMARC_DIR."""
    
    if os.path.isfile(config_file):
        print
        print "ATENCION: ya existe el archivo de configuracion %s." % os.path.abspath(config_file)
        print
    else:
        config_template = os.path.join(OPACMARC_DIR, 'bin', 'install', 'templates', os.path.basename(config_file) + '.dist')
        if force_forward:
            replacement = OPACMARC_DIR.replace('\\', '/')
        else:
            replacement = OPACMARC_DIR
        try:
            f1 = open(config_template, 'r')
            f2 = open(config_file, 'w')
            f2.write(
                f1.read().replace('__OPACMARC_DIR__', replacement)
            )
            f1.close()
            f2.close()
            print 'Generado el archivo %s.' % os.path.basename(config_file)
        except:
            print
            print "ERROR: No se pudo generar el archivo %s." % os.path.basename(config_file)
            print

def build_config_files():
    """Crea archivos de configuración con los paths apropiados."""
    
    replace_config_path(FILES['httpd'], force_forward=True)   # modelo de config. para Apache (requiere barras hacia adelante, incluso en Windows)
    replace_config_path(FILES['local'])   # config. local (para opac.xis) 
    replace_config_path(FILES['update'])  # para update-opac.py
    replace_config_path(FILES['cipar-update']) # para las llamadas a mx desde update-opac.py
    replace_config_path(FILES['cipar-opac'])   # para opac.xis
    
    # TO-DO: local.conf -> SCRIPT_URL -> "wxis.exe" vs "wxis"
    # TO-DO: local.conf -> path agrep
    # TO-DO: ver cómo podemos crear un cipar para read-param.xis. Puede ser un archivo fijo
    #        en el cual se reemplaza '__DB_NAME__' por v2104, y '__DATE__' por s(date).8 


def make_local_dirs():
    """Crea la estructura de directorios para los datos locales."""
    for dir_name in ('bases', 'bin', 'config', 'logs', 'temp'):
        os.mkdir(os.path.join(LOCAL_DATA_DIR, dir_name))

def create_aux_db():
    """Crea bases ISIS auxiliares."""
    
    # FIXME: ajustar saltos de línea de los .id (usar os.linesep?)
    # En Linux hay problemas si usan '\r\n', pero en Windows pueden usar '\n'
    
    # Crea las bases isis auxiliares a partir de archivos de texto (.id)
    run('%s/id2i bin/install/data/country.id create=bases/common/country' % CISIS_PATH)
    run('%s/id2i bin/install/data/lang.id create=bases/common/lang' % CISIS_PATH)
    run('%s/id2i bin/install/data/dictgiz.id create=bases/common/dictgiz' % CISIS_PATH)
    run('%s/id2i bin/install/data/oem2ansi.id create=admin/opac/oem2ansi' % CISIS_PATH)
    
    # Genera los invertidos correspondientes
    run('%s/mx bases/common/country "fst=1 0 v1" fullinv=bases/common/country' % CISIS_PATH)
    run('%s/mx bases/common/lang "fst=1 0 v1" fullinv=bases/common/lang' % CISIS_PATH)
    
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

def setup_demo_db():   # ABORTADO #
    """Crea archivo maestro a partir de archivo de texto."""
    run('%s/id2i bin/install/data/demo.id create=%s/bases/demo/db/original/biblio' % (CISIS_PATH, LOCAL_DATA_DIR))
    # FIXME copy
    shutil.copy('bin/install/data/demo-img/*', '%s/bases/demo/static/img/' % LOCAL_DATA_DIR) 

def set_demo():
    """Procesa la base demo."""   # ABORTADO #
    #FIXME add_db.py demo
    import add_db
    add_db.main('demo')
    setup_demo_db()
    #FIXME update-opac.py demo

    
def show_msg():    
    # Mostrar mensajes útiles para el usuario (tips, tareas que debe realizar luego de instalar)
    print '''
-----------------------------------------------------
  INSTALACION FINALIZADA
-----------------------------------------------------
'''
    print '''
        - Configure permiso de escritura en temp y logs (mostrar ejemplo)
        - Use local-data/config/httpd-opacmarc.conf como base para configurar Apache
        - Copie wxis (wxis.exe en Windows) en la carpeta cgi-bin
        - Windows: copie agrep.exe en la carpeta bin
        - Entre con un browser a http://...
        - Realizar tests? E.g. búsquedas con acentos y con errores (agrep).
    '''


def main():

    print '''
    -----------------------------------------------------
      %s - SCRIPT DE INSTALACION DE OPACMARC
    -----------------------------------------------------
    ''' % os.path.basename(sys.argv[0])

    # Algunas rutas son relativas a OPACMARC_DIR
    os.chdir(OPACMARC_DIR)

    set_version()
    make_local_dirs()
    build_config_files()
    create_aux_db()
    create_table('actab')
    create_table('uctab')
    
    #set_demo()  # esto puede ser parte de un testeo, pero no necesariamente de la instalación
    
    show_msg()


if __name__ == "__main__":
    main()
    