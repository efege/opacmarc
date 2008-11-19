#!/usr/bin/env python
# coding=windows-1252

"""
Script de instalación para OpacMarc
Issue 10: http://code.google.com/p/opacmarc/issues/detail?id=10

TO-DO: Considerar la situación en que ya existe una instalación previa.

TO-DO: hacer read-only los directorios y archivos de la aplicación, para
       mayor protección.
       import stat; os.chmod(myFile, stat.S_IREAD)
       http://techarttiki.blogspot.com/2008/08/read-only-windows-files-with-python.html
"""

import os
import sys
import shutil

from opac_util import run_command, error, APP_DIR, LOCAL_DATA_DIR, CISIS_PATH, LOCAL_DATA, setup_logger
import char_tables


def run(command, msg = 'Error'):
    # FIXME! (see update-db.py) -- Sirve esto para algo?
    #ENV = {'PATH': os.getenv('PATH') + os.pathsep + '...cisis...'}  # CONFIG.get('Global', 'PATH_CISIS')
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
    
    logger.info("Identificador de version generado.")

def create_from_template(template, destination, substitutions, force_forward=False, allow_overwrite=False):
    """Crea un archivo de configuración a partir de una plantilla."""
    
    if os.path.isfile(destination) and not allow_overwrite:
        logger.warning("ATENCION: ya existe el archivo %s." % os.path.abspath(destination))
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
            logger.info('Generado el archivo %s.' % os.path.basename(destination))
        except:
            logger.error("ERROR: No se pudo generar el archivo %s." % os.path.basename(destination))
            raise

def build_config_files():
    """Crea archivos de configuración con los paths apropiados."""

    # Platform-specific info
    import platform
    if platform.system() == 'Windows':
        WXIS = 'wxis.exe'
        TEMP_DIR = os.path.join(LOCAL_DATA_DIR, 'temp')
    else:
        WXIS = 'wxis'
        TEMP_DIR = '/tmp' 

    substitutions = (
        ['__APP_DIR__', APP_DIR],
        ['__LOCAL_DATA_DIR__', LOCAL_DATA_DIR],
        ['__WXIS__', WXIS],
        ['__TEMP_DIR__', TEMP_DIR],
    )
    
    # TO-DO: no necesitamos listar explícitamente los archivos
    for config_file in ('conf-httpd', 'conf-default', 'conf-local', 'conf-update', 'cipar-default', 'cipar-local', 'cipar-update'):
        template = os.path.join(APP_DIR, 'config', 'templates', os.path.basename(FILES[config_file]) + '.tpl')
        if config_file == 'conf-httpd':
            force_forward=True  # Apache requiere barras hacia adelante, incluso en Windows
        create_from_template(template, FILES[config_file], substitutions, force_forward=force_forward)
        
    # Concatenamos archivos cipar
    cipar1 = open(FILES['cipar-default'], 'r')
    cipar2 = open(FILES['cipar-update'], 'a')
    cipar2.write('\n')
    for line in cipar1:
        cipar2.write(line)
    cipar1.close()
    cipar2.close()
    
def make_local_dirs():
    """Crea la estructura de directorios para los datos locales."""
    
    # TO-DO: agregar archivos (templates) en algunos de estos directorios?
    
    local_data_tree = {
        'bases'   : [],
        'bin'     : [],
        'cgi-bin' : ['html', 'pft', 'xis'],
        'config'  : [],
        'htdocs'  : ['css', 'docs', 'img', 'js'],
        'logs'    : ['opac'],
        'temp'    : [],
    }
    
    # TO-DO: definir una función recursiva en opac_util.py
    os.mkdir(LOCAL_DATA_DIR)
    for dir_name in local_data_tree:
        os.mkdir(os.path.join(LOCAL_DATA_DIR, dir_name))
        for subdir_name in local_data_tree[dir_name]:
            os.mkdir(os.path.join(LOCAL_DATA_DIR, dir_name, subdir_name))

def create_files():            
    # Creamos archivos a partir de templates.
    # FIXME - los paths deben quedar con la barra correcta (os.sep)
    # FIXME - corregir el nombre de archivo que se muestra en el mensaje "Generado el archivo"
    for tpl in template_dest:
        f1 = open(os.path.join(APP_DIR, 'bin', 'install', tpl), 'r')
        f2 = open(os.path.join(LOCAL_DATA_DIR, template_dest[tpl], tpl), 'w')
        f2.write(
            f1.read().replace('__LOCAL_DATA_DIR__', LOCAL_DATA_DIR)
        )
        f1.close()
        f2.close()
        logger.info('Generado el archivo %s.' % os.path.basename(template_dest[tpl]))


def setup_msc():
    # ATENCION! Rutas relativas a APP_DIR
    # IMPORTANTE: las tablas .tab deben haberse creado *antes* de generar el invertido.
    os.mkdir(os.path.join('util', 'msc2000'))
    run('%s/id2i bin/install/data/msc2000.id create=util/msc2000/msc2000' % CISIS_PATH)
    run('%s/mx util/msc2000/msc2000 "fst=@bin/install/msc.fst" actab=util/ac-ansi.tab uctab=util/uc-ansi.tab stw=@util/biblio.stw fullinv=util/msc2000/msc2000' % CISIS_PATH)


def create_aux_db():
    """Crea bases ISIS auxiliares."""
    
    # Algunas rutas son relativas a APP_DIR
    os.chdir(APP_DIR)
    
    # TO-DO: ajustar saltos de línea de los .id (usar os.linesep?)
    # En Linux hay problemas si usan '\r\n', pero en Windows andan bien con sólo usar '\n'.
    
    # Crea las bases isis auxiliares a partir de archivos de texto (.id)
    
    # para util
    # TO-DO: los .id es mejor que estén directamente en util/ 
    run('%s/id2i bin/install/data/country.id create=util/country' % CISIS_PATH)
    run('%s/id2i bin/install/data/lang.id create=util/lang' % CISIS_PATH)
    run('%s/id2i bin/install/data/dictgiz.id create=util/dictgiz' % CISIS_PATH)
    run('%s/id2i bin/install/data/gizmo-remove-chars.id create=util/gizmo-remove-chars' % CISIS_PATH)

    # para update_db
    # TO-DO: los .id es mejor que estén directamente en bin/update_db/
    run('%s/id2i bin/install/data/oem2ansi.id create=bin/update_db/oem2ansi' % CISIS_PATH)
    run('%s/id2i bin/install/data/delimsubcampo.id create=bin/update_db/delimsubcampo' % CISIS_PATH)
    
    # Genera los invertidos correspondientes
    run('%s/mx util/country "fst=1 0 v1" fullinv=util/country' % CISIS_PATH)
    run('%s/mx util/lang "fst=1 0 v1" fullinv=util/lang' % CISIS_PATH)
    
    # Caso particular: base MSC 2000 (esquema de clasificación para Matemática, usado en el catálogo del INMABB)
    # FIXME - Esto es sucio; por ahora funciona así: "python install.py msc", pero ¿y si decidimos usar msc
    #         después de haber ejecutado install.py? Quizás mejor usar otro script, e.g. setup_msc.py?
    if len(sys.argv) > 1 and sys.argv[1] == 'msc':
        setup_msc()
    
    logger.info("Bases auxiliares creadas.")

def create_table(table_type):
    """Crea una tabla con códigos de caracteres (actab , uctab).
    """
    f = open(FILES[table_type], 'w')
    values = list(getattr(char_tables, table_type))
    while values:
        f.write(' '.join(values[:32]) + '\n')  # CURIOSO: usando os.linesep en vez de '\n' no se puede leer la tabla en Windows
        values = values[32:]
    f.close()
    logger.info("Tabla %s creada." % table_type)


def upgrade(old_dir=None):
    if old_dir is None:
        old_dir = os.path.join(APP_DIR, '..')
    
    old_local_data = os.path.join(old_dir, LOCAL_DATA)
    shutil.copystat(old_local_data, LOCAL_DATA_DIR)
    
def make_app_readonly():
    """Configura permiso de sólo lectura para todos los archivos excepto en LOCAL_DATA_DIR.
    """
    # FIXME
    #import stat
    #for file_name in os.listdir('.'):
    #    os.chmod(file_name, stat.S_IREAD)
    
    
def main():

    logger.info('*** Instalación iniciada. ***')

    #set_version()
    
    make_local_dirs()  # FIXME - si estamos haciendo un upgrade, sólo tenemos que copiar lo existente.
    
    create_files()
    
    build_config_files()
    
    create_table('actab')
    create_table('uctab')
    
    create_aux_db()
    
    #make_app_readonly()
    
    logger.info('*** Instalación finalizada. ***\n')


# A global logger object
# log_file no puede estar en LOCAL_DATA_DIR pues inicialmente el directorio no existe
log_file = os.path.join(APP_DIR, '..', 'install.log')
logger = setup_logger(log_file)


# Archivos que crea o modifica el script de instalación.
# TO-DO: agregar aquí los que usa create_db()?
FILES = {
    'footer'       : os.path.join(APP_DIR, 'cgi-bin', 'html', 'page-end.htm'),
    
    'conf-httpd'   : os.path.join(APP_DIR, 'config', 'httpd-opacmarc.conf'),
    'conf-default' : os.path.join(APP_DIR, 'config', 'default-settings.conf'),
    'conf-local'   : os.path.join(LOCAL_DATA_DIR, 'config', 'local-settings.conf'),
    'conf-update'  : os.path.join(LOCAL_DATA_DIR, 'config', 'update.conf'),
    
    'cipar-default': os.path.join(APP_DIR, 'config', 'default-cipar.par'),
    'cipar-update' : os.path.join(APP_DIR, 'config', 'update_db.par'),
    'cipar-local'  : os.path.join(LOCAL_DATA_DIR, 'config', 'local-cipar.par'),
    
    'actab'        : os.path.join(APP_DIR, 'util', 'ac-ansi.tab'),
    'uctab'        : os.path.join(APP_DIR, 'util', 'uc-ansi.tab'),
}

# Plantillas para archivos (tomado de add_db.py -- TO-DO: unificar mecanismos)
template_dest = {
    'local-styles.css' : 'htdocs/css',
    'local-scripts.js' : 'htdocs/js',
    #'local-settings.conf' : 'config',
    #'local-cipar.par' : 'config',
    'local.xis' : 'cgi-bin/xis',
}


if __name__ == "__main__":
    main()
    
