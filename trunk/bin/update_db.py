#!/usr/bin/env python
# coding=windows-1252
#
# coding is explained here: http://www.python.org/dev/peps/pep-0263/
# NOTE: Using utf-8 causes problems with delimiter "¦" used occasionally with mx    
#
#
# -----------------------------------------------------------------------
# update-opac.py
#
# Este script genera el conjunto de bases de datos y archivos
# auxiliares utilizados en OPACMARC.
# Basado en update-opac.sh.
#
# Argumentos:
#            $1 nombre de la base
#            $2 cantidad de registros a procesar (opcional, es útil para
#               procesar una cantidad pequeña de registros de una base
#               grande cuando se hacen pruebas)
#
# Ejemplos:
#         update-opac.py demo
#         update-opac.py mibase 500
#
#
# (c) 2003-2008 Fernando J. Gomez - CONICET - INMABB
#
# -----------------------------------------------------------------------
#
# Requiere algunos utilitarios CISIS: mx, msrt, i2id, id2i.
#
# La base de origen debe tener la codificación "ANSI" (aka windows-1252,
# aka latin-1). Las bases creadas con Catalis ya traen esa codificación;
# bases provenientes de Windows o DOS pueden requerir la conversión, por
# ejemplo mediante el gizmo oem2ansi.
#
# Este script por ahora debe permanecer codificado como latin-1. Si usamos
# utf-8 tenemos un error de mx al usar el carácter '¦' como delimitador
# en los proc.
#
# Usamos "seq=filename.id\n" para que mx use el carácter de fin de línea como
# delimitador de campos (y, en consecuencia, no se produzca una indeseada
# separacion en campos).
# ¿Hay alguna manera de evitar que mx asuma un separador de campos?
#
# ATENCION: en caso de registros corruptos, es posible que recién
# salte un error al usar id2i para recrear la base biblio.
#
# -----------------------------------------------------------------------
#
# Esta es la estructura del script:
#
# * configuración
# 
# * verificar argumentos recibidos, existencia de bases
# 
# * descomprimir archivo .zip con la base
# 
# * si tenemos imagenes de tapas, añadimos un campo con esa info
# 
# * procesamiento de las bases:
#         BIBLIO_DATABASE_1
#         SUBJ_DATABASE
#         NAME_DATABASE
#         TITLE_DATABASE
#         BIBLIO_DATABASE_2
#         FULLINV
#         POSTINGS
#         AGREP_DICTIONARIES
#         ARCHIVOS_AUXILIARES
#         
# * limpieza (borrado de temporales) (opcional)
# 
# * movemos los archivos generados al directorio destino (opcional)
#
# -----------------------------------------------------------------------
#
# TO-DO:
#
# Agregar un parámetro de configuración para indicar en qué directorio
# se encuentra la base original.
#
# Verificar que la base no contenga caracteres "prohibidos", i.e. aquellos
# que se usan como delimitadores en los proc. Por ejemplo: "|" en un nombre.
# ¿Este problema desaparecería con mx 5.x?
#
# Medir el tiempo de ejecucion del script, y revisar de manera general
# su diseño, porque es lento en máquinas viejas con bases grandes.
#
# ¿Qué hacemos si los registros ya vienen con ^9 en los
# campos de encabezamientos?
#
# -----------------------------------------------------------------------
#
# NOTA: este fue mi primer script en Python (marzo 2008).
#
# TO-DO: verificar que los cisis (mx, id2i, msrt, etc.) estén en el PATH
#
# TO-DO: realizar una comparación exhaustiva con update-opac.sh
# 2008-09-18: comprobación realizada en Linux sobre los registros de la base BIBIMA
# (sin agregar registros de seriadas). Resta revisar algunas secciones, y probar en
# Windows.
#


# Import modules
import os            # path.*, mkdir, listdir, etc 
import sys           # argv for processing script arguments
import shutil        # shell utils (copy, move, rmtree...)
import re            # regular expressions
import zipfile       # for reading .zip files
#import subprocess    # for running system commands (mx, i2id, etc)
import ConfigParser  # for reading config file

from opac_util import run_command, error, emptydir, APP_DIR, LOCAL_DATA_DIR, setup_logger, unique_sort_files, subprocess


def run(command, msg = 'Error'):
    return run_command(command, msg = msg, env = ENV)

def read_config():
    # TO-DO: see also
    #  - http://docs.python.org/lib/module-ConfigParser.html
    #  - http://cfgparse.sourceforge.net/
    # FIXME - El archivo de configuración tiene que estar en app;
    #         sólo hay que dejar en local-data las opciones locales.
    config_file = os.path.join(LOCAL_DATA_DIR, 'config', 'update.conf')
    config = ConfigParser.ConfigParser()
    config.optionxform = str  # make option names case sensitive
    try:
        config.readfp(open(config_file))
        logger.info("Archivo de configuracion leido: %s" % os.path.abspath(config_file))
        return config
    except:
        error("No se ha podido leer el archivo de configuracion %s." % os.path.abspath(config_file))


def build_env():
    """Builds the environment dictionary, used for calling cisis commands.
    """
    
    # Este diccionario es pasado en las llamadas al sistema
    return {
        'CIPAR':                os.path.join(APP_DIR, 'config', 'update_db.par'),  # Hay que usar el path *absoluto* para el cipar
        # Las variables que siguen son definidas en update.conf
        'PATH':                 CONFIG.get('Global', 'PATH_CISIS') + os.pathsep + os.getenv('PATH'),
        'SUBJ_TAGS':            CONFIG.get('Global', 'SUBJ_TAGS'),
        'NAME_TAGS':            CONFIG.get('Global', 'NAME_TAGS'),
        'TITLE_TAGS':           CONFIG.get('Global', 'TITLE_TAGS'),
        'IGNORE_SUBJ_HEADINGS': CONFIG.get('Global', 'IGNORE_SUBJ_HEADINGS')
    }

        
def print_usage():
    # The name of this script
    SCRIPT_NAME = os.path.basename(sys.argv[0])
    
    # A message to explain the script's usage
    usage_msg = '''
%s

    Genera las bases de datos y archivos auxiliares para OPACMARC. 

    Uso:
        python %s <BASE> [<NUM_REGISTROS>]
    
    Ejemplos:
        %s demo
        %s /var/bases/opac/demo 100
    ''' % ((SCRIPT_NAME,)*4)
    print usage_msg
    sys.exit()


def goto_work_dir():

    # Directorio de trabajo
    WORK_DIR = os.path.join(LOCAL_DATA_DIR, 'bases', DB_NAME, 'db/update')
    if not os.path.isdir(WORK_DIR):
        error("No se ha encontrado el directorio de trabajo para la base %s:\n     %s" % (DB_NAME, WORK_DIR))
    
    # Nos ubicamos en el directorio de trabajo
    try:
        os.chdir(WORK_DIR)
        logger.debug("Directorio de trabajo: %s" % os.path.abspath(WORK_DIR))
    except:
        error("No se puede ingresar al directorio de trabajo, %s." % os.path.abspath(WORK_DIR))
    
    #TO-DO: eliminar en WORK_DIR todos los archivos *.* (sólo nos interesa conservar la carpeta 'original')
    
    # Creamos el directorio temporal, si es necesario
    if not os.path.isdir('tmp'):
        try:
            os.mkdir('tmp')
            logger.debug("Directorio tmp creado.")
        except:
            error("No se pudo crear el directorio tmp.")
    # Y si ya existe, lo vaciamos
    else:
        emptydir('tmp')


def import_marc():
    # basado en im2c.sh (código escrito en la 1ra reunión de CaMPI en Bariloche, julio 2007)
    # FIXME - a esto aún le falta depurar algunos detalles. Ver im2c.sh.
    
    # TO-DO: usar parámetros para indicar el archivo de entrada, el archivo de salida, el directorio tmp.
    # Si llevamos esto a un módulo, podremos usarlo para convertir archivos .mrc en bases isis o archivos .id
    # desde cualquier parte. Ojo: necesita la función run(), y las variables de entorno adecuadas.
    
    LEADER_BASE_TAG_1 = '1000'
    
    # creamos una base isis a partir del registro MARC
    # BUG: mx no almacena la posición 09 del leader!! (informar a Spinak/Bireme)
    run('''mx iso=marc=%s/%s.mrc isotag1=%s create=tmp/marctmp now -all''' % (SOURCE_DIR, DB_NAME, LEADER_BASE_TAG_1))

    # eliminamos del registro importado algunos campos locales que utiliza Catalis
    # TO-DO: verificar que la lista sea completa. ¿Eliminamos todos los 9xx?
    run('''mx tmp/marctmp "proc='d905 d906 d907 d908 d909 d917 d918 d919 d985'" copy=tmp/marctmp now -all''')
    
    # traemos los datos del leader a los campos 9xx usados por Catalis
    run('''mx tmp/marctmp "proc='d1005d1006d1007d1008d1009d1017d1018d1019','a905|',v1005,'|a906|',v1006,'|a907|',v1007,'|a908|',v1008,'|a909|',v1009,'|a917|',v1017,'|a918|',v1018,'|a919|',v1019,'|'" copy=tmp/marctmp now -all''')
    
    # sustituimos delimitadores de subcampos: hex 1F => ^
    run('''mx tmp/marctmp gizmo=DELIMSUBCAMPO copy=tmp/marctmp now -all''')
    
    # sustitución de blancos en campos de datos
    run('''mx tmp/marctmp "proc=@BLANCOS.PFT" copy=tmp/marctmp now -all''')
    
    # FIXME - falta sustitución de blancos en indicadores
    # FIXME - cambiar la codificación, si la original no es latin1. Usar un gizmo.
    
    run('''mx tmp/marctmp create=tmp/biblio now -all''')


def get_biblio_db():
    # --------------------------------------------------------------
    # BASE DE DATOS ORIGINAL
    # --------------------------------------------------------------
    #
    # La base de datos original puede estar en diversos formatos:
    #
    # Formato    Archivos esperados                                             Se leen con
    # ---------------------------------------------------------------------------------------------------
    #   ZIP      dbname.zip o biblio.zip (contenido: biblio.mst y biblio.xrf)   Python (zipfile module)
    #   TGZ      dbname.tgz o dbname.tar.gz [PENDIENTE]                         Python (tarfile module)
    #   MST/XRF  biblio.mst y biblio.xrf                                        mx
    #   MRC      dbname.mrc                                                     mx 5.x
    #   ISO      dbname.iso o biblio.iso                                        mx
    #   ID       dbname.id o biblio.id                                          id2i
    #
    # FIXME: si no se tiene cuidado, es posible que al seguir el orden de preferencias
    # se tome una base obsoleta, p.ej. una copia vieja en formato zip en lugar de la actual
    # en formato mst/xrf.
    
    # TO-DO: remove %s from strings (???)
    
    # TO-DO: revisar completamente esta sección
    
    # The OS path separator, e.g. "/" on Linux, "\\" on Windows.
    #sep = os.path.sep  # not available in Python 2.3
    sep = os.sep
    
    # ARCHIVOS ZIP
    if os.path.isfile(SOURCE_DIR + '/' + DB_NAME + '.zip'):
        #unzip -oq $SOURCE_DIR/$DB_NAME.zip -d tmp
        zipfile.ZipFile(SOURCE_DIR + '/' + DB_NAME + '.zip', 'r')  # ???  Ver http://www.thescripts.com/forum/thread25297.html
        logger.info("Usando como base original: %s%s%s.zip" % (os.path.abspath(SOURCE_DIR), sep, DB_NAME))
    
    elif os.path.isfile(SOURCE_DIR + '/biblio.zip'):
        #unzip -oq $SOURCE_DIR/biblio.zip -d tmp
        logger.info("Usando como base original: %s%sbiblio.zip" % (os.path.abspath(SOURCE_DIR), sep))
    
    # ARCHIVOS MST/XRF
    elif os.path.isfile('%s/biblio.mst' % SOURCE_DIR) and os.path.isfile('%s/biblio.xrf' % SOURCE_DIR):
        shutil.copy('%s/biblio.mst' % SOURCE_DIR, 'tmp')
        shutil.copy('%s/biblio.xrf' % SOURCE_DIR, 'tmp')
        logger.info("Usando como base original: %s%sbiblio.{mst,xrf}" % (os.path.abspath(SOURCE_DIR), sep))
    
    # ARCHIVOS MARC
    elif os.path.isfile('%s/%s.mrc' % (SOURCE_DIR, DB_NAME)):
        logger.info("Importando archivo %s%s%s.mrc..." % (SOURCE_DIR, sep, DB_NAME))
        import_marc()
        
    # ARCHIVOS ISO
    elif os.path.isfile(SOURCE_DIR + '/' + DB_NAME + '.iso'):
        run('mx iso=%s/%s.iso create=tmp/biblio now -all' % (SOURCE_DIR, DB_NAME))
        logger.info("Usando como base original: %s" + sep + "%s.iso" % (SOURCE_DIR, DB_NAME))
    
    elif os.path.isfile(SOURCE_DIR + '/biblio.iso'):
        run('mx iso=%s/biblio.iso create=tmp/biblio now -all' % SOURCE_DIR)
        logger.info("Usando como base original: %s" + sep + "biblio.iso" % SOURCE_DIR)
    
    # ARCHIVOS ID
    elif os.path.isfile(SOURCE_DIR + '/' + DB_NAME + '.id'):
        run('id2i %s/%s.id create=tmp/biblio' % (SOURCE_DIR, DB_NAME))
        logger.info("Usando como base original: %s" + sep + "%s.id" % (SOURCE_DIR, DB_NAME))
    
    elif os.path.isfile(SOURCE_DIR + '/biblio.id'):
        run('id2i %s/biblio.id create=tmp/biblio' % SOURCE_DIR)
        logger.info("Usando como base original: %s" + sep + "biblio.id" % SOURCE_DIR)
    
    else:
        error("No se encuentra la base de datos original.")
    
    
    # El 2do parámetro (opcional) indica cuántos registros procesar
    if len(sys.argv) > 2 and sys.argv[2] > 0:
        MAXCOUNT = sys.argv[2]
        count = "count=%s" % MAXCOUNT
    else:
        count = ""
    
    logger.info("Creando copia temporal de la base...")
    run('mx tmp/biblio %s create=tmp/bibliotmp now -all' % count)
    try:
        shutil.move('tmp/bibliotmp.mst', 'tmp/biblio.mst')
        shutil.move('tmp/bibliotmp.xrf', 'tmp/biblio.xrf')
    except:
        error("Error al mover archivos.")
        raise


def get_secs_db():
    # ------------------------------------------------------------------
    # Para la base bibima, tenemos que añadir a la base biblio los registros del SeCS
    # Como input necesitamos:
    #     * base secstitle (la base title de SeCS, en formato linux)
    #     * archivo EMA.001 (listado de existencias, generado desde SeCS)
    #     * base oem2ansi (el gizmo para cambio de codificación)
    #     * archivo secs2marc.proc (migración SeCS => MARC21)
    #
    # TO-DO: Independizarse del nombre de la base (usar update.conf)
    # ------------------------------------------------------------------
    
    # TO-DO SeCS
    pass
    
    if os.path.isfile(SOURCE_DIR + '/' + DB_NAME + '-secstitle.mst'):   # testeamos si existe la base secstitle asociada
        logger.info("Procesando base SECSTITLE...")
    
        # TO-DO: usar mxcp para eliminar espacios en la base title
        # TO-DO: usar dos2unix para el listado de existencias que proviene de DOS
        
        # paso 0: descomprimimos la base
        #unzip -oq $SOURCE_DIR/$DB_NAME-secstitle.zip -d tmp || error "No se pudo descomprimir el archivo $SOURCE_DIR/$DB_NAME-secstitle.zip"
        run('mx $SOURCE_DIR/$DB_NAME-secstitle create=tmp/title now -all')
        
        # paso 1: recodificamos caracteres
        run('mx tmp/secstitle gizmo=OEM2ANSI create=tmp/title now -all')
        
        # paso 2: creamos una base de holdings
        run('mx seq=tmp/EMA.001 create=tmp/holdings now -all')
        run('mx tmp/holdings "fst=2 0 v2" fullinv=tmp/holdings')
        
        # paso 3: insertamos la información sobre holdings en los registros bibliográficos
        run('''mx tmp/title "proc='a98|',ref(['tmp/holdings']l(['tmp/holdings']v40^c),v3),'|'" copy=tmp/title now -all''')
        
        # paso 4: migramos a MARC
        run('mx tmp/title "proc=@SECS2MARC.PROC" create=tmp/title_marc now -all')
        
        # paso 5: añadimos los registros a la base biblio
        run('mx tmp/title_marc append=tmp/biblio now -all')


def process_images():
    # Si hay imágenes de tapa, creamos un campo 985
    DIR_IMG = CONFIG.get('Global', 'DIR_IMG').replace('__DB__', DB_NAME)
    if not os.path.isdir(DIR_IMG):
        logger.info("No se encuentra el directorio de imágenes: %s" % DIR_IMG)
    else:
        logger.info("Procesando imagenes...")
        file = open('tmp/lista_img.txt', 'w')
        #pattern = re.compile(r'00[0-9]{4}\.[a-z]{3}$')
        pattern = re.compile(r'.\.(gif|jpeg|jpg|png)$', re.IGNORECASE)
        for filename in os.listdir(DIR_IMG):
            if pattern.search(filename):
                file.write(filename + "\n")
        file.close()
        run('''mx seq=tmp/lista_img.txt create=tmp/lista_img now -all''')
        run('''mx tmp/lista_img "proc='d1a1#',v1.6,'^f',v1*7.3,'#'" copy=tmp/lista_img now -all''')
        run('''mx tmp/lista_img "fst=1 0 v1^*" fullinv=tmp/lista_img''')
     
        # Oct. 19, 2006
        #ATENCION: tenemos un error en el MFN 4009 de bibima
        # fatal: recupdat/mfn
        # en la base vemos:
        #     004008   10^aVariational calculus and optimal con..
        #     925907264   10^aDiscriminants, resultants, and multi..
        #     004010   00^aAnalysis on manifolds /^cJames R. Mu..x
        # pero antes de ejecutar este comando el registro 4009 se ve sano.
        # Oct. 20, 2006: el problema desaparece al recrear la base usando $MAXCOUNT
     
        # Quizás sea mejor hacer un loop sobre los archivos de imagenes y solo acceder a los registros afectados,
        # en vez de acceder a todos los registros para solo modificar unos pocos
        run('''mx tmp/biblio "proc=if l(['tmp/lista_img']v1) > 0 then 'd985a985!##^a',ref(['tmp/lista_img']l(['tmp/lista_img']v1),v1^f),'!' fi" copy=tmp/biblio tell=%s now -all''' % TELL)


def process_biblio_db():
    # ------------------------------------------------------------------
    # BASE BIBLIO (1ra pasada)
    # ------------------------------------------------------------------
    
    logger.info("Creamos una copia (texto) de la base bibliografica...")
    # BUG en i2id: aun sin haber errores, el exit status es diferente de cero (e.g. 17, 19). Se testea con 'echo $?'
    # A causa de ese bug, aquí usamos subprocess.call en lugar de subprocess.check_call 
    subprocess.call('i2id tmp/biblio tell=%s > tmp/biblio1.id' % TELL, env=ENV, shell=True)
     
    logger.info("Intentamos normalizar la puntuacion final, filtramos encabezamientos")
    logger.info("   tematicos, y asignamos un numero (provisorio) a cada campo")
    logger.info("   de encabezamientos en el subcampo ^9...")
    # FIXED -- mx "seq=tmp/biblio1.id\n" molesta en Windows, cambiar por  mx "seq=tmp/biblio1.id\\n" (aparece en varios comandos)
    run('''mx "seq=tmp/biblio1.id\\n" lw=3000 "pft=@HEAD.PFT" now tell=%s > tmp/biblio2.id''' % TELL)
 

def process_references(hdg_type):
    # Incorporamos al listado algunas referencias de véase. -- EXPERIMENTAL
    # 
    # Las referencias se encuentran en archivos
    # local-data/<db_name>/db/original/<hdg_type>-references.id, con una estructura
    # básica de registro de autoridad: un campo 1xx y uno o más campos 4xx.

    SOURCE_DIR = os.path.join('..', 'original')  # FIXME - esta definición aparece en más de un lugar del script
    
    if os.path.isfile('%s/%s-references.id' % (SOURCE_DIR, hdg_type)):
    
        # Archivo pft para generar un registro por cada referencia.
        f = open('tmp/one-record-per-reference.pft', 'w')
        print >>f, '''
        (
            '!ID 0'/
            '!v001!',replace(s(v400, v410, v411)*2, '^', '~')/            /* referencia de véase */
            '!v004!',replace(s(v100[1], v110[1], v111[1])*2, '^', '~')/   /* forma autorizada */
        )
        
        if s(v500,v510,v511) > '' then
            '!ID 0'/
            '!v001!',replace(s(v100[1], v110[1], v111[1])*2, '^', '~')/   /* forma autorizada */
            (
                '!v005!',replace(s(v500, v510, v511)*2, '^', '~')/            /* referencias de véase además */
            )
        fi
        '''
        f.close()
        
        run('''id2i %s/%s-references.id create=tmp/%s-references''' % (SOURCE_DIR, hdg_type, hdg_type))
        run('''mx tmp/%s-references pft=@tmp/one-record-per-reference.pft now >tmp/%s-references.id''' % (hdg_type, hdg_type)) 
    
        # Agregamos las referencias al listado de encabezamientos  
        ref = open('tmp/%s-references.id' % hdg_type)
        f = open('tmp/%s1.id' % hdg_type, 'a')
        # usar el ejemplo de estas maneras:
        #   - buscar por "Sonja": 2 matchings
        #   - buscar por "Aderinwal": único matching -- FIXME
        f.write('\n')
        f.write(ref.read())
        f.close(); ref.close()


def build_headings_db(hdg_type):
    # Las bases name y subj se crean con un procesamiento común.  
    # hdg_type = 'subj' o 'name'
    
    type_verbose = {
        'subj': 'temáticos',
        'name' : 'de nombres',
    }
     
    logger.info("-----------------------------------------------------")
    logger.info(" Base de encabezamientos %s" % type_verbose[hdg_type])
    logger.info("-----------------------------------------------------")
     
    logger.info("Creamos el listado de encabezamientos %s..." % type_verbose[hdg_type])
    run('''mx "seq=tmp/biblio2.id\\n" lw=1000 "pft=if getenv('%s_TAGS') : v1*1.4 then @%s.PFT fi" now tell=%s > tmp/%s1.id''' % (hdg_type.upper(), hdg_type.upper(), TELL, hdg_type))

    # experimental
    process_references(hdg_type)
    
    logger.info("Convertimos el listado en una base (desordenada y con duplicados)...")
    run('''id2i tmp/%s1.id create/app=tmp/%s1 tell=%s''' % (hdg_type, hdg_type, TELL))
     
    logger.info("Regularizamos la puntuación final de los encabezamientos generados...")
    run('''mx tmp/%s1 "proc='d2a2¦',v1,'¦'" "proc='d1a1¦',@REGPUNT.PFT,'¦'" "proc='d2'" copy=tmp/%s1 now -all tell=%s''' % (hdg_type, hdg_type, TELL))
     
    logger.info("Almacenamos en un campo auxiliar la clave de ordenación...")
    run('''mx tmp/%s1 uctab=UC-ANSI.TAB "proc='d99a99¦',@HEADSORT.PFT,'¦'" copy=tmp/%s1 now -all tell=%s''' % (hdg_type, hdg_type, TELL))
     
    logger.info("Ordenamos la base de encabezamientos %s..." % type_verbose[hdg_type])
    run('''msrt tmp/%s1 100 v99 tell=%s''' % (hdg_type, TELL))
     
    logger.info("Generamos la tabla para mapear los números de encabezamientos...")
    run('''mx tmp/%s1 "pft=if s(v1) <> ref(mfn-1,v1) then putenv('HEADING_CODE='v9) fi, v9,'|',getenv('HEADING_CODE')/" now -all tell=%s > tmp/%scode.seq''' % (hdg_type, TELL, hdg_type))
     
    logger.info("Eliminamos los encabezamientos duplicados...")
    run('''mx tmp/%s1 lw=1000 "pft=@ELIMDUP2.PFT" now tell=%s > tmp/%s.id''' % (hdg_type, TELL, hdg_type))
     
    logger.info("Creamos la base de encabezamientos %s (ordenada y sin duplicados)..." % type_verbose[hdg_type])
    run('''id2i tmp/%s.id create/app=%s tell=%s''' % (hdg_type, hdg_type, TELL))
 

def recode_headings_in_biblio():
    logger.info("Reasignamos numeros a los encabezamientos en los registros")
    logger.info("   bibliograficos (subcampo 9)...")
    
    run('''mx seq=tmp/subjcode.seq create=tmp/subjcode now -all''')
    run('''mx tmp/subjcode "fst=1 0 v1" fullinv=tmp/subjcode''')
    
    run('''mx seq=tmp/namecode.seq create=tmp/namecode now -all''')
    run('''mx tmp/namecode "fst=1 0 v1" fullinv=tmp/namecode''')
     
    run('''mx "seq=tmp/biblio2.id\\n" lw=1000 "pft=@RECODE.PFT" now tell=%s > tmp/biblio3.id''' % TELL)
 

def build_title_db():
    # ------------------------------------------------------------------
    # BASE TITLE
    # ------------------------------------------------------------------
     
    logger.info("-----------------------------------------------------")
    logger.info(" Base de titulos")
    logger.info("-----------------------------------------------------")
     
    logger.info("Creamos listado de titulos...")
    run('''mx "seq=tmp/biblio3.id\\n" lw=1000 "pft=if getenv('TITLE_TAGS') : v1*1.4 then ,@TITLE.PFT, fi" now tell=%s > tmp/title1.id''' % TELL)
     
    logger.info("Convertimos el listado en una base (desordenada y con duplicados)...")
    run('''id2i tmp/title1.id create/app=tmp/title1 tell=%s''' % TELL)
     
    logger.info("Almacenamos en un campo auxiliar (99) la clave de ordenacion de titulos.")
    run('''mx tmp/title1 uctab=UC-ANSI.TAB "proc='d99a99¦',@HEADSORT.PFT,'¦'" copy=tmp/title1 now -all tell=%s''' % TELL)
     
    logger.info("Ordenamos la base de titulos.")
    run('''msrt tmp/title1 100 v99 tell=%s''' % TELL)
     
    logger.info("Eliminamos los titulos duplicados.")
    run('''mx tmp/title1 lw=1000 "pft=@ELIMDUP2.PFT" now tell=%s > tmp/title.id''' % TELL)
     
    logger.info("Creamos la base de titulos (ordenada y sin duplicados).")
    run('''id2i tmp/title.id create/app=title tell=%s''' % TELL)
 

def rebuild_biblio_db(): 
    # ------------------------------------------------------------------
    # BASE BIBLIO (2da pasada)
    # ------------------------------------------------------------------
     
    logger.info("-----------------------------------------------------")
    logger.info(" Base bibliografica")
    logger.info("-----------------------------------------------------")
     
    logger.info("Recreamos la base bibliografica.")
    run('''id2i tmp/biblio3.id create=biblio tell=%s''' % TELL)
     
    logger.info("Ordenamos la base bibliografica.")
    run('''msrt biblio 100 @LOCATION_SORT.PFT tell=%s''' % TELL)


# EXPERIMENTAL
def process_subcatalogs():
    # HS = short mnemonic for "headings/subcatalogs"

    logger.info("-----------------------------------------------------")
    logger.info(" Sub-catalogos")
    logger.info("-----------------------------------------------------")
    
    # Creamos un archivo de texto biblio-hs.txt, donde cada línea contiene la
    # lista de heading-ids y la lista de subcatálogos asociados a un registro
    # de la base bibliográfica. Las listas se separan con '|', y los ítems
    # dentro de cada lista con ','. Un ejemplo simplificado:
    #     H1,H2|S1
    #     H3|S2
    #     H4,H1|S1,S2
    run('''mx biblio "proc=@LIST-HEADING-IDS.PFT" "proc=@LIST-SUBCATS.PFT" "pft=if p(v5000) then v5000+|,|, '|', v5001+|,|, / fi" now -all lw=1000 > tmp/biblio-hs.txt''')

    # HS es un diccionario que mapea cada heading-id al conjunto de sus subcatálogos asociados.
    # Cada HS[hid] es a su vez un diccionario cuyas keys son los subcatálogos.
    HS = {}
    for B in open('tmp/biblio-hs.txt'):
        parts = B.rstrip('\n').split('|')
        H = parts[0].split(',')
        S = parts[1].split(',')
        for hid in H:
            if not hid in HS:
                HS[hid] = {}
            HS[hid].update(dict.fromkeys(S))
            
    # Enviamos los datos de HS a un archivo .id
    id_file = open('tmp/hs.id', 'w')
    for hid in HS:
        id_file.write('!ID 0\n')
        id_file.write('!v1!%s\n' % hid)
        for subcat in HS[hid].keys(): 
            id_file.write('!v2!%s\n' % subcat)
    id_file.close()

    # Creamos una base isis con id2i
    run('''id2i tmp/hs.id create=tmp/hs''')
    
    # Generamos invertido sobre el campo 1 (heading-id)
    run('''mx tmp/hs "fst=1 0 v1" fullinv=tmp/hs''')
    
    # Agregamos a las bases de headings un nuevo campo repetible (tag=8) con la lista de subcatálogos
    # ATENCION: bug en mx? si en lugar de tag=8 usamos tag=30, nos encontramos con este problema:
    # no podemos mandar el campo 30 al diccionario usando headings.fst. Parece que la FST no ve el
    # campo, aun cuando el campo está en el registro. Verificado con mx 5.2b-1030 en Linux, 2008-11-03.
    run('''mx name "proc='a8#', ref(['tmp/hs']l(['tmp/hs']v9), v2+|#a8#|) ,'#'" copy=name now -all''') 
    run('''mx subj "proc='a8#', ref(['tmp/hs']l(['tmp/hs']v9), v2+|#a8#|) ,'#'" copy=subj now -all''')
    

def fullinv(): 
    # ------------------------------------------------------------------
    # FULLINV
    # ------------------------------------------------------------------
     
    # -------------------------------------------------------------------
    # Generación de archivos invertidos.
    # ATENCION: AC-ANSI.TAB envia los numeros al diccionario.
    # -------------------------------------------------------------------
    
    logger.info("Archivo invertido - Base de temas...")
    #run('''mx subj to=1 now > zzzzz.txt''')  # DEBUG
    #run('''mx subj to=1 fst=@HEADINGS.FST now >> zzzzz.txt''')  # DEBUG
    run('''mx subj gizmo=REMOVE-CHARS,1 fst=@HEADINGS.FST actab=AC-ANSI.TAB uctab=UC-ANSI.TAB fullinv=subj tell=%s''' % TELL)
    
    logger.info("Archivo invertido - Base de nombres...")
    run('''mx name gizmo=REMOVE-CHARS,1 fst=@HEADINGS.FST actab=AC-ANSI.TAB uctab=UC-ANSI.TAB fullinv=name tell=%s''' % TELL)
    
    # TO-DO: ver cómo aplicar el gizmo remove-chars para los 2 invertidos que siguen, y la relación
    # con cleanQuery
    
    logger.info("Archivo invertido - Base de titulos...")
    run('''mx title "fst=2 0 '~',@HEADSORT.PFT" actab=AC-ANSI.TAB uctab=UC-ANSI.TAB fullinv=title tell=%s''' % TELL)
    
    logger.info("Archivo invertido - Base bibliografica...")
    # Antes de la FST, aplicamos un gizmo a los campos que generan puntos de acceso
    run('''mx biblio gizmo=DICTGIZ,100,110,111,130,700,710,711,730,800,810,811,830 gizmo=DICTGIZ,240,245,246,440,740,600,610,611,630,650,651,653,655,656 fst=@BIBLIO.FST actab=AC-ANSI.TAB uctab=UC-ANSI.TAB stw=@BIBLIO.STW fullinv=biblio tell=%s''' % TELL)


def process_analytics():
    # ------------------------------------------------------------------
    # REGISTROS ANALÍTICOS
    # ------------------------------------------------------------------
    
    logger.info("Detectando registros analiticos...")
    # Para los registros analíticos, creamos un 773$9 donde guardar el MFN
    # del registro asociado, y así ahorrar futuros lookups en el diccionario
    # ATENCION: esto debe hacerse *después* de aplicado el msrt y generado el diccionario
    
    run('''mx biblio "proc=if p(v773^w) then 'd773a773¦',v773,'^9',f(l('-NC=',v773^w),1,0),'¦', fi" copy=biblio now -all tell=%s''' % TELL)


def compact_db():
    # Compactamos la base bibliografica
    # TO-DO: compactar bases de headings
    logger.info("Compactando la base bibliografica...")
    run('mx biblio create=bibliotmp now -all tell=%s' % TELL)
    try:
        shutil.move('bibliotmp.mst', 'biblio.mst')
        shutil.move('bibliotmp.xrf', 'biblio.xrf')
    except:
        error()

# FIXME -- sirve esto?
#echo
#cecho "blue" "Títulos de seriadas..."
#mx biblio "-BIBLEVEL=S" "pft=replace(v245*2,'^','~')" now -all > title_serial.txt


def add_heading_postings(hdg_type):
    # POSTINGS
    # El diccionario de la base biblio debe haber sido generado previamente.
     
    logger.info("Asignamos postings a los terminos de %s." % hdg_type)
    run('''mx %s "proc=if p(v9) then 'd11a11#',f(npost(['biblio']'_%s_'v9),1,0),'#', fi" copy=%s now -all tell=%s''' % (hdg_type, hdg_type.upper(), hdg_type, TELL))
     
    # TO-DO: necesitamos postings para los títulos controlados (series, títulos uniformes).
    # Para eso necesitamos un subcampo $9 en la base de títulos.


def build_agrep_dictionaries():
    logger.info("Generamos diccionarios para AGREP.")
    
    # Solo nos interesan claves asociadas a ciertos tags.
    # /100 restringe la cantidad de postings (de lo contrario, da error).
    # ATENCION: los sufijos NAME, SUBJ, TITLE van en mayusculas o minusculas
    # en base a los valores que tome el parámetro CGI correspondiente.
    
    # DUDA: ¿hay alguna ventaja en tener los listados ordenados?
    
    # ----------------------------------------
    logger.info("   - subj")
    # ----------------------------------------
    # Para bibima usamos la base MSC; para el resto, la base SUBJ
    # TO-DO: la base subj también sirve para bibima; usar cat & uniq
    # TO-DO: independizarse del nombre de la base (usar config)
    # TO-DO: como la base MSC es fija, no necesitamos volver a generar este listado cada vez.
    if DB_NAME == 'bibima':
        run('''mx dict=MSC "pft=v1^*/" k1=a k2=zz now > dictSUBJ.txt''')
    else:
        run('''mx dict=subj "pft=v1^*/" k1=a k2=zz now > dictSUBJ.txt''')
    
    # ----------------------------------------
    logger.info("   - name")
    # ----------------------------------------
    run('''mx dict=name "pft=v1^*/" k1=a k2=zz now > dictNAME.txt''')
    
    # ----------------------------------------
    logger.info("   - title (incluye series)")
    # ----------------------------------------
    #mx dict=biblio,1,2/100  "pft=if v2^t : '204' then v1^*/ fi" k1=a now > dicttitle.txt
    run('''ifkeys biblio +tags from=a to=zzzz > tmp/titlekeys.txt''')
    run('''mx seq=tmp/titlekeys.txt "pft=if '204~404' : right(v2,3) then v3/ fi" now > tmp/titlekeys2.txt''')
    #cat tmp/titlekeys2.txt | uniq > dictTITLE.txt
    #run('''mx seq=tmp/titlekeys2.txt create=tmp/titlekeys2 now -all''')
    #run('''mx tmp/titlekeys2 "pft=if v1 <> ref(mfn-1, v1) then v1/ fi" now > dictTITLE.txt''')
    unique_sort_files(['tmp/titlekeys2.txt'], output_file='dictTITLE.txt')
    
    # ----------------------------------------
    logger.info("   - any")
    # ----------------------------------------
    # Unión de los diccionarios anteriores (eliminando términos duplicados)
    # Originalmente en Bash era: cat dict*.txt | sort | uniq > dictANY.txt
    unique_sort_files(['dict%s.txt' % t for t in ('SUBJ', 'NAME', 'TITLE')], output_file='dictANY.txt')
    

def build_aux_files():
    # ARCHIVOS AUXILIARES
     
    logger.info("Lista de codigos de idioma.")
    run('''mx seq=LANG.SEQ create=tmp/lang now -all''')
    run('''mx tmp/lang fst=@LANG.FST fullinv=tmp/lang''')
    run('''mx dict=biblio "k1=-LANG=A" "k2=-LANG=ZZZ" "pft=v1^**6.3,'|',v1^t/" now > tmp/langcode.txt''')
    run('''mx seq=tmp/langcode.txt create=tmp/langcode now -all''')
    run('''msrt tmp/langcode 30 "ref(['tmp/lang']l(['tmp/lang']v1.3),s(mpu,v3))"''')
    run('''mx tmp/langcode "pft=v1,'^p',v2,'^',/" now -all > langcode.txt''')

    # TO-DO: independizarse del nombre de la base (usar update.conf)
    if DB_NAME == "bibima":
        logger.info("Actualizamos los postings para cada código MSC")
        run('''mx MSC "proc=if l(['biblio']'-MSC='v1) > 0 then 'd7a7@',f(npost(['biblio']'-MSC='v1),1,0),'@' fi" copy=MSC now -all tell=%s''' % TELL)
        # TO-DO: compactar la base MSC
    
    logger.info("Lista de codigos de bibliotecas.")
    run('''mx dict=biblio "k1=-BIB=A" "k2=-BIB=ZZZ" "pft=v1^**5,'^p',v1^t/" now > bibcode.txt''')
    
    logger.info("Fechas extremas.")
    run('''mx dict=biblio "k1=-F=1" "k2=-F=2999" "pft=v1^**3/" now > tmp/dates1.txt''')
    run('''mx tmp to=1 "proc='a1~',replace(s(cat('tmp/dates1.txt')),s(#),'&'),'~'" "pft=v1.4,'-',s(right(v1,5)).4" > dates.txt''')
    
    logger.info("Total de registros disponibles.")
    run('''mx biblio count=1 "pft=proc('a5001~',f(maxmfn-1,1,0),'~'),'BIBLIOGRAPHIC_TOTAL=',left(v5001,size(v5001)-3),if size(v5001) > 3 then '.' fi,right(v5001,3)/" > bases.txt''')
    run('''mx name count=1 "pft=proc('a5001~',f(maxmfn-1,1,0),'~'),'NAME_TOTAL=',left(v5001,size(v5001)-3),if size(v5001) > 3 then '.' fi,right(v5001,3)/" >> bases.txt''')
    run('''mx subj count=1 "pft=proc('a5001~',f(maxmfn-1,1,0),'~'),'SUBJ_TOTAL=',left(v5001,size(v5001)-3),if size(v5001) > 3 then '.' fi,right(v5001,3)/" >> bases.txt''')
    run('''mx title count=1 "pft=proc('a5001~',f(maxmfn-1,1,0),'~'),'TITLE_TOTAL=',left(v5001,size(v5001)-3),if size(v5001) > 3 then '.' fi,right(v5001,3)/" >> bases.txt''')
    
    logger.info("Total de ejemplares disponibles.")
    # ATENCION: necesitamos una buena definición de "ejemplares" (los "items" de FRBR)
    # Por ahora, vamos a contar los nros. de inventario, 859$p
    # En lugar de wc, usar archivo temporal y count = len(open(thefilepath, 'rU').readlines( )) -- ver Recipe 2.5. Counting Lines in a File
    run('''mx biblio "pft=(v859^p/)" now > tmp/items.txt''')
    itemcount = len(open('tmp/items.txt', 'rU').readlines( ))
    file = open('tmp/items-total.txt', 'w')
    file.write(str(itemcount) + '\n')  # newline needed for mx seq
    file.close()
    #run('''mx biblio "pft=(v859^p/)" now | wc -l > tmp/items-total.txt''')
    run('''mx seq=tmp/items-total.txt "pft=proc('d1a1|',replace(v1,' ',''),'|'), if size(v1) > 3 then left(v1,size(v1)-3),'.',right(v1,3), else v1, fi" now > tmp/items-total-punto.txt''')
    #echo "ITEMS_TOTAL=`cat tmp/items-total-punto.txt`" >> bases.txt
    f1 = open('tmp/items-total-punto.txt')
    f2 = open('bases.txt', 'a')  # 'a': append (>>)
    f2.write('ITEMS_TOTAL=')
    f2.write(f1.read())  # FIXME -- esto no genera nada
    #print f2.read()  # FIXME -- Mostramos bases.txt
    f1.close()
    f2.close()
    
    # Mostramos bases.txt
    #cat bases.txt
    
    logger.info("Listado de novedades.")
    # TO-DO: generalizar para cualquier año y/o mes, y para otros criterios (e.g. en ABCI por inventario)
    # FIXME (sort para Windows)
    run('''mx biblio "pft=if '~2006~2007~2008~2009~2010~' : s('~',v859^y[1]*6.4,'~') then v1/ fi" now | sort > novedades.txt''')
    
    logger.info("Fecha de esta actualizacion.")
    run('''mx tmp "pft=s(date)*6.2,'/',s(date)*4.2,'/',s(date).4,' a las ',s(date)*9.2,':',s(date)*11.2" to=1 > updated.txt''')


def remove_tmp_files():
    # Eliminamos archivos temporales generados por este script
    
    logger.info("Eliminando archivos temporales...")
    try:
        shutil.rmtree('tmp')
    except:
        logger.info("ERROR: No se puede eliminar el directorio tmp")
    
    #rm -rf *.ln* 2>/dev/null
    #rm -rf *.lk* 2>/dev/null
    pattern = re.compile(r'\.l[kn][12]$')  # FIXME -- se comporta como si tuviera ^ al comienzo!
    for f in os.listdir('.'):
        if pattern.match(f):
            os.remove(f)


def move_files():
    """Movemos los archivos generados."""
    # TO-DO: sacamos de servicio el OPAC mientras se están pisando los archivos viejos?
    #        Otra opción: cambiar un link simbólico que apunte a la carpeta con los nuevos archivos
    #        (ver la idea en http://athleticsnyc.com/blog/entry/on-using-subversion-for-web-projects)
    logger.info("Moviendo los archivos generados...")
    TARGET_DIR = CONFIG.get('Global', 'TARGET_DIR').replace('__DB__', DB_NAME)
    emptydir(TARGET_DIR)
    try:
        for f in os.listdir('.'):
            if os.path.isfile(f):    # solo archivos (excluyo directorios)
                shutil.move(f, TARGET_DIR)
    except:
        raise

def clean_cache():
    # FIXME -- CACHE_DIR may not exist (fix it in emptydir?) 
    CACHE_DIR = os.path.join(LOCAL_DATA_DIR, 'temp')
    emptydir(CACHE_DIR)

begin_msg = "*** Actualización de la base %s. ***"

end_msg = "*** Base %s actualizada exitosamente. ***\n"

def main(db_name):

    global CONFIG, TELL, ENV, DB_NAME, SOURCE_DIR

    script_name = os.path.basename(sys.argv[0])

    #Check mandatory argument
    #if len(argv) < 2:
    #    print_usage()
    
    DB_NAME = db_name
    
    # En este directorio se encuentra la base original 
    SOURCE_DIR = os.path.join(LOCAL_DATA_DIR, 'bases', DB_NAME, 'db/original')

    logger.info(begin_msg % DB_NAME)  # FIXME - si es importado por demo.py imprime 'demo.py'
    
    # Read config file
    CONFIG = read_config()
    
    # define global variables
    TELL = CONFIG.get('Global', 'TELL')  # used by many calls to cisis utilities
    ENV = build_env()
    
    
    # Prepare the input data
    goto_work_dir()
    get_biblio_db()
    if CONFIG.get('Global', 'IMAGES') == '1':
        process_images()
    
    # Do the hard work
    process_biblio_db()
    build_headings_db('name')
    build_headings_db('subj')
    recode_headings_in_biblio()
    build_title_db()
    rebuild_biblio_db()
    if CONFIG.get('Global', 'SUBCATS') == '1':
        process_subcatalogs()
    fullinv()
    process_analytics()
    compact_db()
    add_heading_postings('name')
    add_heading_postings('subj')
    build_agrep_dictionaries()
    build_aux_files()
    
    # Clean and/or move files if needed
    if CONFIG.get('Global', 'CLEAN') == '1':
        remove_tmp_files()
    if CONFIG.get('Global', 'MOVE') == '1':
        move_files()
    
    clean_cache()

    logger.info(end_msg % DB_NAME)


# Define a global logger object
log_file = os.path.join(LOCAL_DATA_DIR, 'logs', 'python.log')
logger = setup_logger(log_file)

if __name__ == "__main__":
    db_name = sys.argv[1]
    main(db_name)
    sys.exit(0)
