# coding=windows-1252

# Genera las carpetas y archivos asociados a una nueva base de datos para
# consultar a través de OpacMarc.
#
# Fernando Gómez, 2008-09-20
#
# TO-DO: dividir en funciones sencillas

import os
import sys

OPACMARC_DIR = os.path.abspath(os.path.join(os.path.dirname(sys.argv[0]), ".."))
sys.path.insert(0, os.path.join(OPACMARC_DIR, 'util'))
from util import error

    
def print_usage():
    # The name of this script
    SCRIPT_NAME = os.path.basename(sys.argv[0])
    
    # A message to explain the script's usage
    usage_msg = '''
%s

    Agrega una nueva base al OPAC

    Uso:
        python newdb.py <BASE>
    
    Ejemplo:
        python newdb.py libros
''' % SCRIPT_NAME
    print usage_msg
    sys.exit()


def main():
    # Plantillas para archivost
    template_dest = {
        'about.htm' : 'htmlpft',
        'banner.htm' : 'htmlpft',
        'home.htm' : 'htmlpft',
        'styles.css' : 'static/css',
        'options.conf' : 'config',
    }
    
    
    # Check mandatory argument
    if len(sys.argv) < 2:
        print_usage()
    
    DB_NAME = sys.argv[1]
    LOCAL_DATA_DIR = os.path.join(OPACMARC_DIR, 'local-data')
    DB_DIR = os.path.join(LOCAL_DATA_DIR, 'bases', DB_NAME)
    
    if os.path.isdir(DB_DIR):
        error("Ya existe un directorio con el nombre '%s'." % DB_NAME)
    
    #os.chdir(OPACMARC_DIR)
    
    # Creamos directorios
    try:
        os.mkdir(DB_DIR)
        
        for dir_name in ('config', 'db', 'htmlpft', 'pft', 'static'):
            os.mkdir(os.path.join(DB_DIR, dir_name))
    
        for dir_name in ('original', 'public', 'update'):
            os.mkdir(os.path.join(DB_DIR, 'db', dir_name))
    
        for dir_name in ('css', 'img', 'js'):
            os.mkdir(os.path.join(DB_DIR, 'static', dir_name))
            
    except:
        raise
    
    # Creamos archivos a partir de templates
    for tpl in template_dest:
        f1 = open(os.path.join(OPACMARC_DIR, 'bin', 'add_db', 'templates', tpl), 'r')
        f2 = open(os.path.join(DB_DIR, template_dest[tpl], tpl), 'w')
        f2.write(
            f1.read().replace('__LOCAL_DATA_DIR__', LOCAL_DATA_DIR).replace('__DB__', DB_NAME)
        )
        f1.close()
        f2.close()
        print 'Generado el archivo %s.' % os.path.basename(template_dest[tpl])

    '''
    for file_name in ('about', 'banner', 'home'):
        f = open(os.path.join(DB_DIR, 'htmlpft', '%s.htm' % file_name), 'w')
        f.write(templates[file_name] % DB_NAME)
        f.close()
        
    f = open(os.path.join(DB_DIR, 'static', 'css', 'styles.css'), 'w')
    f.write(templates['css'] % DB_NAME)
    f.close()
    
    f = open(os.path.join(DB_DIR, 'config', 'options.conf'), 'w')
    f.write(templates['conf'] % DB_NAME)
    f.close()
    '''
        
    
    print
    print "Se han creado los directorios y archivos necesarios para trabajar con la base '%s'." % DB_NAME
    print
    print '''Ahora debe copiar la base bibliografica original en la carpeta
    
        %s/bases/%s/db/original/
        
    y luego ejecutar:
    
        bin/update-opac.py %s
        
    Además, si desea personalizar la presentacion del OPAC para esta base, puede
    editar los siguientes archivos:
    
        %s/bases/%s/htmlpft/about.htm
        %s/bases/%s/htmlpft/banner.htm
        %s/bases/%s/htmlpft/home.htm
        %s/bases/%s/static/css/styles.css
        
    Si necesita imágenes auxiliares (p.ej. un logo) deberá colocarlas en la carpeta
    
        %s/bases/%s/static/img/
        
    Si necesita modificar algunos parámetros de configuración para el OPAC,
    hágalo editando el archivo
    
        %s/bases/%s/config/options.conf
    
    ''' % ((LOCAL_DATA_DIR, DB_NAME, DB_NAME) + (LOCAL_DATA_DIR, DB_NAME)*6)   # Requiere los paréntesis, de lo contrario TypeError
    sys.exit(0)


if __name__ == "__main__":
    main()

