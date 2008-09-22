# coding=windows-1252

# Fernando G�mez, 2008-09-20

import os
import sys

OPACMARC_DIR = os.path.abspath(os.path.join(os.path.dirname(sys.argv[0]), ".."))
sys.path.insert(0, os.path.join(OPACMARC_DIR, 'util'))
from util import error

# Plantillas para archivos
banner_tpl = '''<p>Agregue aqu� un texto explicando a los usuarios qu� encontrar�n en este cat�logo.</p>'''
banner_tpl = '''<h1>Cabecera para la base <i>%s</i></h1>'''
home_tpl = '''<p>Puede agregar aqu� contenido adicional para las p�ginas de la base <i>%s</i></p>'''
css_tpl = '''/* Puede definir aqu� estilos CSS espec�ficos para la base %s */'''


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


# Check mandatory argument
if len(sys.argv) < 2:
    print_usage()

DB_NAME = sys.argv[1]

os.chdir(OPACMARC_DIR)

# Creamos directorios
try:
    os.mkdir('bases/opac/%s' % DB_NAME)
    
    os.mkdir('admin/work/%s' % DB_NAME)
    
    for dir_name in ('original', 'tmp', 'preprocess'):
        os.mkdir('admin/work/%s/%s' % (DB_NAME, dir_name))
    
    os.mkdir('htdocs/opac/img/%s' % DB_NAME)

except:
    error("Hubo un error. Posiblemente ya existe una base con ese nombre.")

# Creamos archivos
try:
    f = open('cgi-bin/opac/local/about/%s.htm' % DB_NAME, 'w')
    f.write(about_tpl % DB_NAME)
    f.close()
    
    f = open('cgi-bin/opac/local/banner/%s.htm' % DB_NAME, 'w')
    f.write(banner_tpl % DB_NAME)
    f.close()

    f = open('cgi-bin/opac/local/home/%s.htm' % DB_NAME, 'w')
    f.write(home_tpl % DB_NAME)
    f.close()
    
    f = open('htdocs/opac/css/custom/%s.css' % DB_NAME, 'w')
    f.write(css_tpl % DB_NAME)
    f.close()
except:
    raise
    sys.exit(1)
    

print
print "Se han creado los directorios y archivos necesarios para trabajar con la base '%s'." % DB_NAME
print
print '''Ahora debe copiar la base bibliografica original en la carpeta

    admin/work/%s/original/
    
y luego ejecutar:

    admin/bin/update-opac.py %s
    
Ademas, si desea personalizar la presentacion del OPAC para esta base, puede
editar los siguientes archivos:

    cgi-bin/opac/local/about/%s.htm
    cgi-bin/opac/local/banner/%s.htm
    cgi-bin/opac/local/home/%s.htm
    htdocs/opac/css/custom/%s.css
    
Si necesita imagenes auxiliares (p.ej. un logo) debera colocarlas en la carpeta

    htdocs/opac/img/%s/
    
Puede que necesite modificar algunos par�metros de configuraci�n para el OPAC;
h�galo editando el archivo

    cgi-bin/opac/config/local.conf
    
''' % (DB_NAME,)*7
sys.exit(0)

