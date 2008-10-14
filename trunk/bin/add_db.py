#!/usr/bin/python
# coding=windows-1252

"""
    Genera las carpetas y archivos asociados a una nueva base de datos para
    consultar a través de OpacMarc.

    Uso:
        python add_db.py <BASE>
    
    Ejemplo:
        python add_db.py libros
"""
# Creado: Fernando Gómez, 2008-09-20
# TO-DO: dividir en funciones sencillas

import os
import sys
import shutil
from opac_util import error, OPACMARC_DIR, LOCAL_DATA_DIR

# Plantillas para archivos
template_dest = {
    'about.htm' : 'htmlpft',
    'banner.htm' : 'htmlpft',
    'home.htm' : 'htmlpft',
    'db.css' : 'htdocs/css',
    'db-settings.conf' : 'config',
}

def print_usage():
    # The name of this script
    SCRIPT_NAME = os.path.basename(sys.argv[0])
    print __doc__
    

# Ver: Python main() functions, by Guido van Rossum <http://www.artima.com/weblogs/viewpost.jsp?thread=4829>
def main(DB_NAME):

    print begin_msg % os.path.basename(sys.argv[0])  # FIXME - si es importado por demo.py imprime demo.py

    # Check mandatory argument
    #if len(argv) < 2:
    #    print_usage()
    #    sys.exit(0)
    
    #DB_NAME = argv[1]
    DB_DIR = os.path.join(LOCAL_DATA_DIR, 'bases', DB_NAME)
    
    if os.path.isdir(DB_DIR):
        error("Ya existe un directorio con el nombre '%s'." % DB_NAME)
    
    # Creamos directorios
    try:
        os.mkdir(DB_DIR)
        
        for dir_name in ('config', 'db', 'htmlpft', 'pft', 'htdocs'):
            os.mkdir(os.path.join(DB_DIR, dir_name))
    
        for dir_name in ('original', 'public', 'update'):
            os.mkdir(os.path.join(DB_DIR, 'db', dir_name))
    
        for dir_name in ('css', 'img', 'js'):
            os.mkdir(os.path.join(DB_DIR, 'htdocs', dir_name))
            
    except:
        raise
    
    # Creamos archivos a partir de templates
    # FIXME - los paths deben quedar con la barra correcta (os.sep)
    # FIXME - corregir lo que se muestra en el mensaje "Generado el archivo"
    for tpl in template_dest:
        f1 = open(os.path.join(OPACMARC_DIR, 'bin', 'add_db', 'templates', tpl), 'r')
        f2 = open(os.path.join(DB_DIR, template_dest[tpl], tpl), 'w')
        f2.write(
            f1.read().replace('__LOCAL_DATA_DIR__', LOCAL_DATA_DIR).replace('__DB__', DB_NAME)
        )
        f1.close()
        f2.close()
        print 'Generado el archivo %s.' % os.path.basename(template_dest[tpl])

    print end_msg1 % DB_NAME
    
    # Dummy logo image
    logo_src = os.path.join(OPACMARC_DIR, 'bin', 'add_db', 'templates', 'logo.png')
    logo_dst = os.path.join(DB_DIR, 'htdocs', 'img')
    shutil.copy(logo_src, logo_dst)

begin_msg = '''
-----------------------------------------------------
  %s - GENERACION DE UNA NUEVA BASE
-----------------------------------------------------
'''
    
end_msg1 = '''
Se han creado los directorios y archivos necesarios para trabajar con
la base '%s'.
'''

end_msg2 = '''
A continuacion, debe copiar la base bibliográfica original en la carpeta

    %s/bases/%s/db/original/
    
y luego ejecutar:

    python bin/update_db.py %s
    
Además, si desea personalizar la presentacion del OPAC para esta base, puede
editar los siguientes archivos:

    %s/bases/%s/htmlpft/about.htm
    %s/bases/%s/htmlpft/banner.htm
    %s/bases/%s/htmlpft/home.htm
    %s/bases/%s/htdocs/css/db.css
    
Si necesita imágenes para esta base (p.ej. un logo) debe colocarlas en
la carpeta

    %s/bases/%s/htdocs/img/
    
Si necesita modificar algunos parámetros de configuración específicamente
para esta base, edite el archivo

    %s/bases/%s/config/db-settings.conf
'''

if __name__ == "__main__":
    DB_NAME = sys.argv[1]
    main(DB_NAME)
    print end_msg2 % ((LOCAL_DATA_DIR, DB_NAME, DB_NAME) + (LOCAL_DATA_DIR, DB_NAME)*6)   # Requiere los paréntesis, de lo contrario TypeError
    sys.exit(0)
