#!/usr/bin/env python
# coding=windows-1252

# ATENCION - este archivo está en proceso de conversión desde .bat a .py
#


# ===============================================================================
# Creación de una base de pseudo-autoridades a partir de una base bibliográfica
# existente.
#
# Uso:   python auto.py </path/to/archivo_maestro_biblio>
#
# Ejemplos:  python auto.py /var/bases/test/biblio
#            python auto.py biblio (si la base biblio está en el directorio 'autoridades')
#
#
# Genera algunos informes (archivos .txt y .html) sobre los procesos realizados.
#
# Genera, además, un listado de encabezamientos posiblemente duplicados, en base
# a la distancia de Levenshtein entre encabezamientos adyacentes en el orden alfabético
# (usa la función levenshtein de PHP, y por lo tanto requiere que esté disponible el
# intérprete de línea de comandos de PHP).
#
# La base bibliográfica debe estar en "formato Catalis"; en particular, debe
# usar '#' en lugar de 'blank' para los indicadores, y la codificación de
# caracteres debe ser windows-1252 (también llamada ANSI). Véase
# http://catalis.uns.edu.ar/wiki/index.php/Estructura_de_las_bases_bibliogr%C3%A1ficas
#
# TO-DO: considerar la adición de un campo 670 (u otro?) donde conste la fuente del encabezamiento.
# En el caso de la base de autoridades creada a partir de una base bibliográfica, se podría poner
# alguna mención de este hecho.
#
# TO-DO: crear una base para testeo, que incluya una buena muestra de las situaciones
# que se pueden presentar:
#   - nombres personales (100, 700)
#   - nombres de entidades (110, 710)
#   - nombres de conferencias (111, 711)
#   - títulos uniformes y series (130, 440, 730, 830, 240?)
#   - encabezamientos de nombre-título
#   - subcampos con funciones ($e, $4)
#   - encabezamientos "vinculados" (entidades subordinadas, o nombre-título)
#   - encabezamientos duplicados (con y sin error)
#   - acentos (efecto sobre el sort y sobre la deteccion de duplicados)
#   - diferencias en el uso de mayúsculas
#
# TO-DO: ¿podemos hacer que los números de control de los registros de autoridad vayan de
# 000001 en adelante, sin tantas lagunas?
#
# TO-DO: estos encabezamientos de materia deberían unificarse (^x -> ^v)
#   150  «#0^aAdventure stories, American^xHistory and criticism^vJuvenile literature.»
#   150  «#0^aAdventure stories, American^xHistory and criticism^xJuvenile literature.»
# Véase http://www.slc.bc.ca/cheats/formv.htm
#
# Código original: (c) F. Gómez, R. Mansilla, R. Piriz, 2005
# Modificaciones:  (c) F. Gómez, 2007
# ===============================================================================

import sys
import os
from opac_util import run_command, error, emptydir, APP_DIR, LOCAL_DATA_DIR, setup_logger, unique_sort_files, subprocess


def run(command, msg = 'Error'):
    return run_command(command, msg = msg, env = ENV)


# La base bibliográfica de origen.
BIBLIO = sys.argv[1]

def mkdirs():
    # Creamos directorios auxiliares.
    try:
        os.mkdir('work')
        os.mkdir('output')
    except:
        pass
    emptydir('work')
    emptydir('output')

def build_env():
    # cipar para mx
    cipar = open('work/cipar.txt', 'w')
    #echo map.*=autoridades/work/map.* >cipar.txt
    cipar.write('AC-ANSI.TAB=%s/ac-ansi.tab\n' % os.path.join(APP_DIR, 'util'))
    cipar.write('UC-ANSI.TAB=%s/uc-ansi.tab\n' % os.path.join(APP_DIR, 'util'))
    # FIXME - las tablas que usábamos en autoridades no son exactamente las mismas que las del opac. Revisar.
    ENV = {
        'CIPAR' : os.path.join(APP_DIR, 'bin/autoridades/work/cipar.txt'),
        'PATH' : os.path.join(APP_DIR, 'bin/cisis') + os.pathsep + os.getenv('PATH'),
        'CONTROLLED_TAGS' : CONTROLLED_TAGS,
        'PREFIX' : PREFIX, 
    }
    return ENV


def test_delimiter():
    # TO-DO: hacer esto mejor en Python.
    # Verificamos que no haya problemas con el delimitador elegido.
    # TO-DO: sugerir el uso de mxf0 para determinar caracteres no usados.
    # ATENCION: esto no sería necesario si usáramos la sugerencia de E. Spinak.
    run('''echo x| mx %s "text/show=%s" > work/delim.txt''' % (BIBLIO, SEQ_DELIM))
    run('''mx tmp count=1 "pft=if size(cat('work/delim.txt')) > 0 then system('echo ERROR>work/delim-error.txt'), fi" now''')
    if os.path.isfile('work/delim-error.txt'):
        logger.error('*** ATENCION ***')
        logger.error('El delimitador elegido "%s" ya está presente en la base.' % SEQ_DELIM)
        logger.error('Cambie el valor de SEQ_DELIM.')
        exit()


def build_auto():

    logger.info('--------------------------------------------------')
    logger.info(' 1 - CONSTRUCCION DE BASE AUTO')
    logger.info('--------------------------------------------------')
    
    # Si está presente el campo 240, creamos un campo auxiliar 1xx + $t (nombre/título)
    #mx %BIBLIO% proc=@v240.pft create=work/biblio-240 now -all
    
    #run('''echo %s>work/prefix''' % PREFIX)
    f = open('work/prefix', 'w')
    print >> f, PREFIX
    f.close()
    
    # Eliminamos campo 1106 y creamos una copia de trabajo de la base bibliográfica.
    run('''mx %s "proc='d1106'" create=work/biblio now -all tell=%s''' % (BIBLIO, TELL))
    
    # Cada campo de la base bibliográfica pasa a ser un registro de la base biblio-campos.
    logger.info('Creando lista de campos...')
    # Por bug en i2id usamos subprocess.call
    subprocess.call('''i2id work/biblio >work/biblio.id''', env=ENV, shell=True)
    run('''mx "seq=work/biblio.id%s" lw=%s create=work/biblio-campos now -all tell=%s''' % (SEQ_DELIM, LW, TELL))
    
    # Eliminamos espacios en blanco en los extremos (¿a qué se deben esos espacios?)
    # TO-DO: ¿vale la pena hacer la limpieza sobre toda la base, si solo nos interesan los encabezamientos?
    logger.info('Eliminando espacios en blanco...')
    run('''mxcp work/biblio-campos create=work/biblio-campos-clean clean log=output/mxcp-biblio-campos.log >nul tell=%s''' % TELL)
    
    # Extraemos los campos con encabezamientos controlados, y creamos una base con ellos.
    # ATENCION: para filtrar subcampos $e, $4, $5, podemos usar algo como name.pft del OPAC. (??)
    # TO-DO: para uctab necesitamos usar una tabla ad hoc.
    logger.info('Extrayendo encabezamientos controlados...')
    run('''mx work/biblio-campos-clean uctab=UC-ANSI.TAB lw=%s pft=@extract-headings.pft now tell=%s >work/auto-dup.seq''' % (LW, TELL))
    run('''mx seq=work/auto-dup.seq create=work/auto-dup now -all tell=%s''' % TELL)
    
    
    # Ordenamos la lista de encabezamientos.
    # Usamos el formato "mpu,v1*4" para comparar en mayúsculas, ignorando los indicadores y el primer delimitador de subcampo.
    # Necesitamos guardar la clave en un campo auxiliar (99) para poder usar la tabla correcta de conversión a mayúsculas.
    logger.info('Ordenando lista de encabezamientos...')
    run('''mx work/auto-dup uctab=UC-ANSI.TAB "proc='a99|',mpu,v1*4,'|'" copy=work/auto-dup now -all tell=%s''' % TELL)
    run('''msrt work/auto-dup 1000 v99''')
    
    # Eliminamos encabezamientos duplicados.
    # Usamos el formato "v1*2" para comparar encabezamientos ignorando los indicadores.
    # La comparación es directa (sin conversión a mayúsculas ni de otro tipo), por lo tanto detecta *cualquier* diferencia.
    # ATENCION: si normalizamos *antes* el 2do indicador de x00, x10, x11, ¿podemos acá incluir los indicadores en la comparación?
    logger.info('Eliminando encabezamientos duplicados...')
    run('''mx work/auto-dup lw=%s "pft=if v1*2 <> ref(mfn-1,v1*2) then v1,'|',v2,'|',v3/ fi" now >work/auto-uniq.seq''' % LW)
    run('''mx seq=work/auto-uniq.seq lw=%s create=work/auto-uniq now -all''' % LW)
    
    # Reasignamos tags y ajustamos los indicadores en los registros de autoridades.
    logger.info('Reasignando tags y ajustando indicadores...')
    run('''mx work/auto-uniq "proc=@fix-tags-indicators.pft" create=work/auto now -all tell=%s''' % TELL)
    
    # Agregamos campos a los registros de autoridades: leader, 005, 008, 999.
    logger.info('Agregando campos: leader, 005, 008, 999...')
    run('''mx work/auto "proc=@008etc.pft" copy=work/auto now -all''')
    
    # Ordenamos por tag los campos de cada registro de autoridad.
    logger.info('Ordenando campos en los registros de autoridad...')
    run('''mx work/auto "proc='s'" create=output/auto now -all''')
    
    # PRUEBA: generar registros inactivos en la base auto a partir del 2do registro
    #         Todos los registros de la base auto son alias del primero.
    #mx work/auto from=2 "proc='d999a999@001766@'" copy=work/auto now -all
    
    # Diccionario para la base de autoridades.
    logger.info('Generando diccionario para la base de autoridades...')
    run('''mx output/auto fst=@auto.fst actab=AC-ANSI.TAB uctab=UC-ANSI.TAB fullinv=output/auto''')


def generate_reports():

    logger.info('--------------------------------------------------')
    logger.info(' 2 - GENERACION DE INFORMES')
    logger.info('--------------------------------------------------')
    
    # Generamos algunos informes sobre las bases biblio y auto.
    
    logger.info('mxf0...')
    # mxf0 para biblio.
    # Por bug en mxf0 usamos subprocess.call
    subprocess.call('''mxf0 %s create=work/biblio-mxf0''' % BIBLIO, env=ENV, shell=True)
    run('''mx work/biblio-mxf0 "pft=@mxf0.pft" now >output/biblio-mxf0.html''')
    
    # mxf0 para auto.
    # Por bug en mxf0 usamos subprocess.call
    subprocess.call('''mxf0 work/auto create=work/auto-mxf0''', env=ENV, shell=True)
    run('''mx work/auto-mxf0 "pft=@mxf0.pft" now >output/auto-mxf0.html''')
    
    # Frecuencia de los campos usados para generar encabezamientos.
    logger.info('Frecuencia de campos de encabezamientos...')
    run('''mxtb work/auto-uniq create=work/tag-freq 3:v3''')
    run('''msrt work/tag-freq 3 v1''')
    run('''mx work/tag-freq "pft=v1,c10,v999/" now >output/tag-freq.txt''')
    
    # Listados de encabezamientos por tipo.
    logger.info('Listados de encabezamientos por tipo...')
    for tag in ('100', '110', '111', '130'):
        run('''mx work/auto lw=%s "pft=v%s/" now >output/auto-%s.txt''' % (LW, tag, tag))
    
    # Algunos listados por valor de indicadores.
    logger.info('Listados por valor de indicadores...')
    run('''mx work/auto lw=%s "pft=if p(v100) and v100.1 <> '1' then v100/ fi" now >output/auto-100-not1.txt''' % LW)
    run('''mx work/auto lw=%s "pft=if p(v110) and v110.1 <> '2' then v110/ fi" now >output/auto-110-not2.txt''' % LW)
    run('''mx work/auto lw=%s "pft=if p(v111) and v111.1 <> '2' then v111/ fi" now >output/auto-111-not2.txt''' % LW)
    run('''mx work/auto lw=%s "pft=if p(v130) and v130*1.1 <> '0' then v130/ fi" now >output/auto-130-not0.txt''' % LW)
    
    # Listado de encabezamientos de nombre-título.
    logger.info('Listado de encabezamientos de nombre-título...')
    out_file = 'output/auto-nombre-titulo.txt'
    for tag in ('100', '110', '111'):
        f = open(out_file, 'a')
        print >> f, '\n--------- %s ---------' % tag
        f.close()
        run('''mx work/auto lw=%s "pft=if p(v%s^t) then v%s/ fi" now >>%s''' % (LW, tag, tag, out_file))

   
    # Lista de posibles duplicados (requiere que el ejecutable PHP esté en el PATH).
    # TO-DO: considerar la aplicación de un criterio como el de NACO <http://www.loc.gov/catdir/pcc/naco/normrule.html>
    # TO-DO: incluir número de control en el listado
    logger.info('Generando lista de posibles duplicados...')
    run('''mx output/auto lw=%s "pft=v100/v110/v111/v130/v150/v151/v155/" now >work/auto-lista.txt''' % LW)
    #php compara-lev.php work/auto-lista.txt %LEV_LIMIT% >output/auto-posibles-duplicados.txt


def generate_links():

    logger.info('--------------------------------------------------')
    logger.info(' 3 - GENERACION DE LINKS ENTRE BIBLIO y AUTO')
    logger.info('--------------------------------------------------')
    
    # TO-DO: explicar bien qué sucede en cada paso de este proceso, usando un ejemplo.
    
    # Construimos tabla de mapeo de punteros a la base bibliográfica.
    logger.info('Construyendo tabla para mapear punteros...')
    run('''mx work/auto-dup "pft=if v1*2 <> ref(mfn-1,v1*2) then putenv('PTR=',v2) fi, v2,'|',getenv('PTR')/" now -all >work/map.seq''')
    run('''mx seq=work/map.seq create=work/map now -all''')
    
    # Diccionario para map.
    run('''mx work/map "fst=1 0 v1/" fullinv=work/map''')
    
    # Creamos un subcampo $0 en cada punto de acceso.
    # ¿Por qué subcampo $0? Ver http://www.loc.gov/marc/marbi/2007/2007-06.html
    logger.info('Creando subcampos $0 en los puntos de acceso...')
    run('''mx work/biblio-campos-clean proc=@create-subfield-0.pft create=work/biblio-campos-ref1 now -all tell=%s''' % TELL)
    
    # Consultamos la base map para reasignar punteros en la base bibliográfica.
    logger.info('Reasignando el valor de los subcampos $0...')
    run('''mx work/biblio-campos-ref1 proc=@update-subfield-0.pft create=work/biblio-campos-ref2 now -all tell=%s''' % TELL)
    
    # Regeneramos la base bibliográfica.
    logger.info('Regenerando la base bibliografica...')
    run('''mx work/biblio-campos-ref2 lw=%s "pft=v1/" now -all tell=%s >work/biblio-campos-ref2.id''' % (LW, TELL))
    run('''id2i work/biblio-campos-ref2.id create=output/biblio-ref''')
    
    # TO-DO: ¿cómo indizamos los registros de la nueva base biblio?
    # La respuesta, como siempre, es: "depende". Depende de qué búsquedas queremos poder hacer.
    
    # Para probar el funcionamiento de los links entre la base bibliográfica y
    # la base de autoridades, se puede usar esto, que presenta los títulos (245)
    # junto con los puntos de acceso 100 y 700 asociados (aunque sin añadir
    # puntuación):
    #     mx output/biblio-ref "pft=@test-ref.pft"
    


def main(db_name):
    global ENV
    
    os.chdir('autoridades')
    mkdirs()
    ENV = build_env()
    test_delimiter()
    build_auto()
    generate_reports()
    generate_links()
    logger.info('--------------------------------------------------')
    logger.info(' Esto ha sido todo. Vea el directorio output.')
    logger.info('--------------------------------------------------')
    if CLEAN:
        emptydir('work')



# Define a global logger object
log_file = os.path.join(LOCAL_DATA_DIR, 'logs', 'python.log')
logger = setup_logger(log_file)


# --------------------------------------------------------------
# COMIENZO DE CONFIGURACION
# --------------------------------------------------------------

# Directorio de trabajo. Aquí se almacenan archivos temporales.
#WORK = 'work'

# Directorio de salida. Aquí se almacenan las bases e informes generados.
#OUTPUT = 'output'

# Lista de tags de los cuales vamos a extraer los encabezamientos.
# TO-DO: ver cómo manejar los encabezamientos de nombre-título:
#     100, 110, 111 pueden estar asociados a un 240 (título uniforme)
#     700, 710, 711, 600, 610, 611 pueden incluir un $t (título uniforme)
#     800, 810 y 811 siempre incluyen un $t (título uniforme de serie)
MAIN_ENTRY = 'v100~v110~v111~v130'
ADDED_ENTRY = 'v700~v710~v711~v730'
SERIES = 'v440~v800~v810~v811~v830'
SUBJECT1 = 'v600~v610~v611~v630'
SUBJECT2 = 'v650~v651~v655~v656'
CONTROLLED_TAGS = MAIN_ENTRY + '~' + ADDED_ENTRY + '~'  + SERIES + '~' + SUBJECT1

# Prefijo usado en el identificador de los registros de autoridad (número de control, campo 001).
# Usamos 'a' por 'autoridad'.
PREFIX = 'a'

# Límite de tolerancia usado en la detección de posibles duplicados mediante la distancia de Levenshtein.
# Usar '0' para que no tolere errores (i.e., 2 encabezamiento se consideran duplicados sólo si son
# exactamente iguales), '1' para que tolere un error (i.e., si la distancia de Levenshtein es 1 se
# consideran duplicados), etc.
# Es conveniente probar con diferentes valores para tener una idea del tipo de "duplicados" que detecta.
# Más info: http://www.php.net/manual/en/function.levenshtein.php
LEV_LIMIT = 5

# Delimitador de campos usado por el comando 'mx seq=archivo'.
# El delimitador por defecto es la barra vertical ('|'). Como este carácter puede estar presente
# en los registros --p.ej. en el campo 008-- necesitamos usar cualquier otro carácter
# que no esté presente en la base biblio.
# Parece que anda bien con un carácter de control como p.ej. asc 30 (hex 1E, "record separator", "RS").
# ATENCION: mx 5.2 no admite algunos delimitadores! (e.g. '¬', '´', '§', etc).
# TO-DO: averiguar si mx permite una solución más elegante a este problema.
# 2007-08-27: Según E. Spinak, la solución pasa por usar el separador '\', entre comillas:  mx "seq=<file>\".
# Anda, pero sólo si no uso ningún parámetro a continuación del seq. :(
SEQ_DELIM = '\x1E'

# Longitud de línea. Valor para el parámetro lw de mx. Debe ser mayor que la máxima
# longitud de un campo de la base biblio, para evitar que un campo pueda quedar partido.
LW = '10000'

# Valor del parámetro tell de mx. Es preferible usar un valor muy grande, o bien '0',
# para que los mensajes frecuentes de tell no impidan ver posibles mensajes de error.
TELL = 0

# Usar True para que al finalizar la ejecución se eliminen los archivos temporales (directorio work).
CLEAN = False

# --------------------------------------------------------------
# FIN DE CONFIGURACION
# --------------------------------------------------------------


if __name__ == "__main__":
    db_name = sys.argv[1]
    main(db_name)
    sys.exit(0)
