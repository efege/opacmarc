# coding=windows-1252

# Script de instalaci�n para OpacMarc
# Issue 10: http://code.google.com/p/opacmarc/issues/detail?id=10

# TO-DO: Considerar tambi�n la situaci�n en que ya existe una instalaci�n
# y se desea preservar los datos locales.

def run(command, msg = 'Error'):
    # FIXME! (see update-opac.py)
    ENV = {'PATH': os.getenv('PATH') + os.pathsep + 'G:\\programas\\cisis\\5.2\\1030'}  # CONFIG.get('Global', 'PATH_CISIS')
    return run_command(command, msg = msg, env = ENV)

def set_version():
    # Genera un identificador de la versi�n y lo inserta en el footer.
    # svnversion produce identificadores de la forma '322' o '322M'.
    # En el 2do caso, significa que se trata de la revisi�n 322 con
    # modificaciones locales.
    # FIXME - En Windows con Tortoise no tenemos svnversion. Alternativa: ver c�mo
    # extraer la informaci�n de SubWCRev.exe
    # FIXME - Esto solo funciona cuando install.py se ejecuta sobre una working copy,
    # pero no sobre c�digo exportado.
    version = os.popen('svnversion').read().replace(os.linesep, '')
    footer_file = file(FILES['footer'])
    aux_file = file('footer.tmp', 'w')
    aux_file.write(
        footer_file.read().replace('__VERSION__', '(rev. %s)' % version)
    )
    aux_file.close()
    shutil.move('footer.tmp', FILES['footer'])
    
    print "Identificador de version generado."

def replace_config_path(config_file):
    # Crea un archivo de configuraci�n a partir de una plantilla y del valor
    # actual de OPACMARC_DIR.
    if os.path.isfile(config_file):
        print
        print "ATENCION: ya existe el archivo de configuracion %s." % os.path.abspath(config_file)
        print
    else:
        config_template = os.path.join(OPACMARC_DIR, 'config', 'templates', os.path.basename(config_file) + '.dist')
        try:
            f1 = open(config_template, 'r')
            f2 = open(config_file, 'w')
            f2.write(
                f1.read().replace('__OPACMARC_DIR__', OPACMARC_DIR)
            )
            f1.close()
            f2.close()
            print 'Generado el archivo %s.' % os.path.basename(config_file)
        except:
            print
            print "ERROR: No se pudo generar el archivo %s." % os.path.basename(config_file)
            print

def set_config():
    # Crea archivos de configuraci�n con los paths correctos.
    replace_config_path(FILES['httpd'])   # modelo de config. para Apache
    replace_config_path(FILES['local'])   # config. local (para opac.xis) 
    replace_config_path(FILES['update'])  # para update-opac.py
    replace_config_path(FILES['cipar-update']) # para las llamadas a mx desde update-opac.py
    replace_config_path(FILES['cipar-opac'])   # para opac.xis
    
    # TO-DO: local.conf > SCRIPT_URL > "wxis.exe" vs "wxis"
    # TO-DO: ver c�mo podemos crear un cipar para read-param.xis. Puede ser un archivo fijo
    #        en el cual se reemplaza '__DB_NAME__' por v2104, y '__DATE__' por s(date).8 


def create_dirs():
    # En Windows crear directorio temp para b�squedas de wxis (tambi�n en Linux para cache?), y ajustar config.
    # No necesitamos tener ese dir en el repositorio; svn:ignore temp
    try:
        os.mkdir('temp')
        print "Directorio temp creado."
    except:
        pass
        # posiblemente ya existe el dir. temp
        #print
        #print "ATENCION: No se pudo crear la carpeta temp."
      
    # Crear directorio logs, e incluir dentro de �l un README?
    # No necesitamos tener ese dir en el repositorio; svn:ignore logs
    #try:
    #   os.mkdir('logs')
    #   print "Directorio logs creado."
    #except:
    #   print
    #   print "ATENCION: No se pudo crear la carpeta logs."

def create_db():
    
    # FIXME: asegurarse de que los cisis est�n en el path. Esto parece que
    #        va a requerir tocar un config *antes* de ejecutar este script.
    #        Podemos intentar encontrarlos (subprocess), y en caso de fracasar
    #        se genera un mensaje de error.
    #        Tambi�n podemos exigir que los cisis est�n en __OPACMARC_DIR__/bin
    
    # FIXME: ajustar saltos de l�nea de los .id (usar os.linesep?)
    # En Linux hay problemas si usan '\r\n', pero en Windows pueden usar '\n'
    
    # Crea las bases isis auxiliares a partir de archivos de texto (.id)
    run('%s/id2i bases/id/country.id create=bases/common/country' % CISIS_PATH)
    run('%s/id2i bases/id/lang.id create=bases/common/lang' % CISIS_PATH)
    run('%s/id2i bases/id/dictgiz.id create=bases/common/dictgiz' % CISIS_PATH)
    run('%s/id2i bases/id/oem2ansi.id create=admin/opac/oem2ansi' % CISIS_PATH)
    
    run('%s/id2i bases/id/demo.id create=local-data/bases/demo/db/original/biblio' % CISIS_PATH)

    # Genera los invertidos correspondientes
    run('%s/mx bases/common/country "fst=1 0 v1" fullinv=bases/common/country' % CISIS_PATH)
    run('%s/mx bases/common/lang "fst=1 0 v1" fullinv=bases/common/lang' % CISIS_PATH)
    
    print "Bases auxiliares creadas."

def create_table(table_type):
    f = open(FILES[table_type], 'w')
    values = list(getattr(tablas, table_type))
    while values:
        f.write(' '.join(values[:32]) + '\n')  # CURIOSO: usando os.linesep en vez de '\n' no se puede leer la tabla en Windows
        values = values[32:]
    f.close()
    print "Tabla %s creada." % table_type

def show_msg():    
    # Mostrar mensajes �tiles para el usuario (tips, tareas que debe realizar luego de instalar)
    print '''
-----------------------------------------------------
  INSTALACION FINALIZADA
-----------------------------------------------------
'''
    print '''Algunos mensajes para el admin:
        - configurar permiso de escritura en temp y logs
        - use config/http-opacmarc.conf como base para configurar Apache
        - ejecutar newdb.py con la base demo?
        - copie wxis (wxis.exe en Windows) en la carpeta cgi-bin
        - Windows: copie agrep.exe en la carpeta bin
        - ejecutar update-opac.py demo
        - Entrar con un browser a la URL...
        - Realizar tests? E.g. b�squedas con acentos y con errores.
    '''



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

# Archivos que crea o modifica el script de instalaci�n.
# TO-DO: agregar aqu� los que usa create_db()
FILES = {
    'footer' : os.path.join(OPACMARC_DIR, 'cgi-bin', 'opac', 'html', 'opac-footer.htm'),
    'cipar-update' : os.path.join(OPACMARC_DIR, 'local-data', 'config', 'opac.cip'),
    'cipar-opac' : os.path.join(OPACMARC_DIR, 'local-data', 'config', 'update.cip'),
    'httpd' : os.path.join(OPACMARC_DIR, 'local-data', 'config', 'httpd-opacmarc.conf'),
    'local' : os.path.join(OPACMARC_DIR, 'local-data', 'config', 'local.conf'),
    'update' : os.path.join(OPACMARC_DIR, 'local-data', 'config', 'update.conf'),
    'actab' : os.path.join(OPACMARC_DIR, 'util', 'ac-ansi.tab'),
    'uctab' : os.path.join(OPACMARC_DIR, 'util', 'uc-ansi.tab'),
}

CISIS_PATH = os.path.join(OPACMARC_DIR, 'bin', 'cisis-1660')

print '''
-----------------------------------------------------
  %s - SCRIPT DE INSTALACION DE OPACMARC
-----------------------------------------------------
''' % os.path.basename(sys.argv[0])

# Varias rutas son relativas a OPACMARC_DIR
os.chdir(OPACMARC_DIR)

set_version()
set_config()
#create_dirs()
create_db()
create_table('actab')
create_table('uctab')
show_msg()
