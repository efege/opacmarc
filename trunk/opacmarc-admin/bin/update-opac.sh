#!/bin/bash

# -----------------------------------------------------------------------
# update-opac.sh
#
# Este script genera el conjunto de bases de datos y archivos
# auxiliares utilizados en el OPAC.
#
# Argumentos:
#            $1 nombre de la base
#            $2 cantidad de registros a procesar (opcional, es útil para
#               procesar una cantidad pequeña de registros de una base
#               grande cuando se hacen pruebas)
#
# Ejemplos:
#         update-opac demo
#         update-opac mibase 500
#
#
# (c) 2003-2006 Fernando J. Gomez - CONICET - INMABB
#
# -----------------------------------------------------------------------
#
# Requiere algunos utilitarios CISIS: mx, msrt, i2id, id2i; para convertir
# las bases al "formato Windows" necesita además crunchmf y crunchif.
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
# Este script fue originalmente escrito como un .bat para Windows,
# y aún conserva vestigios de ese pasado, a la espera de completar
# la traducción.
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
# * si tenemos registros de SeCS, los añadimos a la base
# 
# * procesamiento de las bases:
# 		BIBLIO_DATABASE_1
# 		SUBJ_DATABASE
# 		NAME_DATABASE
# 		TITLE_DATABASE
# 		BIBLIO_DATABASE_2
# 		FULLINV
# 		POSTINGS
# 		AGREP_DICTIONARIES
# 		ARCHIVOS_AUXILIARES
# 		
# * limpieza (borrado de temporales) (opcional)
# 
# * movemos los archivos generados al directorio destino (opcional)
#
# -----------------------------------------------------------------------
#
# TO-DO:
#
# Aceptar como input otras opciones además de un archivo .zip:
# archivos biblio.mst + biblio.xrf, archivo .iso, archivo .id, archivo .mrc
#
# Medir el tiempo de ejecucion del script, y revisar de manera general
# su diseño, porque es lento en máquinas viejas con bases grandes.
#
# ¿Qué hacemos si los registros ya vienen con ^9 en los
# campos de encabezamientos?
#
# =========================================================================

# Funciones de error tomadas de install_qemu.sh (ver http://ubuntuforums.org/showthread.php?t=187413)

## COLOR ECHO FUNCTION ##
cecho()
{
	if [ "$1" = "black" ]; then
		echo -ne "\E[30m"
	elif [ "$1" = "red" ]; then
		echo -ne "\E[31m"
	elif [ "$1" = "green" ]; then
		echo -ne "\E[32m"
	elif [ "$1" = "yellow" ]; then
		echo -ne "\E[33m"
	elif [ "$1" = "blue" ]; then
		echo -ne "\E[34m"
	elif [ "$1" = "magenta" ]; then
		echo -ne "\E[35m"
	elif [ "$1" = "cyan" ]; then
		echo -ne "\E[36m"
	fi

	echo "$2" "$3"
	tput sgr0
}

## ERROR FUNCTION ##
error()
{
	if [ "$1" = "" ]; then
		cecho "red" "ERROR: hubo una falla, con causa desconocida."
	else
		cecho "red" "ERROR: $1"
	fi
	exit
}


echo
cecho "blue" "-----------------------------------------------------"
cecho "blue" "  update-opac.sh - SCRIPT DE ACTUALIZACION DEL OPAC  "
cecho "blue" "-----------------------------------------------------"

# ------------------------------------------------------------------
# VERIFICAMOS PRESENCIA DEL PARAMETRO OBLIGATORIO
# ------------------------------------------------------------------
if [ "$1" = "" ]; then
	error "Debe indicar el nombre de la base."
fi

DB_NAME=$1


# ------------------------------------------------------------------
# LEEMOS CONFIGURACION
# ------------------------------------------------------------------

CONF_FILE=`dirname $0`/../conf.sh
. $CONF_FILE || error "No se ha encontrado el archivo de configuración $CONF_FILE"


# ------------------------------------------------------------------
# DEFINIMOS ALGUNAS VARIABLES
# ------------------------------------------------------------------

# Directorio de trabajo
WORK_DIR=$OPACMARC_DIR/work/$DB_NAME
if [ ! -d $WORK_DIR ]; then
	error "No se ha encontrado el directorio de trabajo: $WORK_DIR"
fi

# En este directorio se encuentra la base original 
SOURCE_DIR=$WORK_DIR/original

# Hay que usar el path *absoluto* para el cipar
export CIPAR=$OPACMARC_DIR/opac/opac.cip


# ------------------------------------------------------------------
# GENERAMOS EL ARCHIVO CIPAR
# ------------------------------------------------------------------

# Usamos % como delimitador debido a que $OPACMARC_DIR contiene barras (/) 
sed "s%__OPACMARC_DIR__%$OPACMARC_DIR%" $CIPAR.dist > $CIPAR || error "No se pudo generar el archivo cipar"


# ------------------------------------------------------------------


# Nos ubicamos en el directorio de trabajo
cd $WORK_DIR || error "No se puede ingresar al directorio de trabajo, $WORK_DIR"

# Creamos el directorio temporal, si es necesario
if [ ! -d tmp ]; then
    mkdir tmp || error "No se pudo crear el directorio tmp"
    #cecho "blue" "Directorio tmp creado."
fi


# La base de datos original puede estar en diversos formatos:
#     ZIP:     dbname.zip o biblio.zip (contiene biblio.mst y biblio.xrf)
#     TGZ:     dbname.tgz o dbname.tar.gz [PENDIENTE]
#     MST/XRF: biblio.mst y biblio.xrf
#     MRC:     dbname.mrc
#     ISO:     dbname.iso o biblio.iso
#     ID:      dbname.id o biblio.id
echo
if [ -f $SOURCE_DIR/$DB_NAME.zip ]; then
	unzip -oq $SOURCE_DIR/$DB_NAME.zip -d tmp || error
	cecho "blue" "Usando como base original: $SOURCE_DIR/$DB_NAME.zip"

elif [ -f $SOURCE_DIR/biblio.zip ]; then
	unzip -oq $SOURCE_DIR/biblio.zip -d tmp || error
	cecho "blue" "Usando como base original: $SOURCE_DIR/biblio.zip"

elif [[ -f $SOURCE_DIR/biblio.mst && -f $SOURCE_DIR/biblio.xrf ]]; then
	cp -f $SOURCE_DIR/biblio.{mst,xrf} tmp/ || error
	cecho "blue" "Usando como base original: $SOURCE_DIR/biblio.{mst,xrf}"

elif [ -f $SOURCE_DIR/$DB_NAME.mrc ]; then
	echo
	cecho "blue" "Importando archivo $SOURCE_DIR/$DB_NAME.mrc..."
	php $OPACMARC_DIR/bin/mrc2isis.php $SOURCE_DIR/$DB_NAME.mrc > tmp/$DB_NAME.id || error "Falla al ejecutar mrc2isis.php"
	id2i tmp/$DB_NAME.id create=tmp/biblio || error "Hubo una falla al ejecutar id2i"

elif [ -f $SOURCE_DIR/$DB_NAME.iso ]; then
	mx iso=$SOURCE_DIR/$DB_NAME.iso create=tmp/biblio now -all || error
	cecho "blue" "Usando como base original: $SOURCE_DIR/$DB_NAME.iso"

elif [ -f $SOURCE_DIR/biblio.iso ]; then
	mx iso=$SOURCE_DIR/biblio.iso create=tmp/biblio now -all || error
	cecho "blue" "Usando como base original: $SOURCE_DIR/biblio.iso"

elif [ -f $SOURCE_DIR/$DB_NAME.id ]; then
	id2i $SOURCE_DIR/$DB_NAME.id create=tmp/biblio || error
	cecho "blue" "Usando como base original: $SOURCE_DIR/$DB_NAME.id"

elif [ -f $SOURCE_DIR/biblio.id ]; then
	id2i $SOURCE_DIR/biblio.id create=tmp/biblio || error
	cecho "blue" "Usando como base original: $SOURCE_DIR/biblio.id"

else
	error "No se encuentra la base de datos original"
fi


# El 2do parametro (opcional) indica cuántos registros procesar
if [ ! -z $2 ]; then
    MAXCOUNT=$2
else
    MAXCOUNT=999999
fi

mx tmp/biblio count=$MAXCOUNT create=tmp/bibliotmp now -all || error "Hubo una falla al ejecutar mx"
mv -f tmp/bibliotmp.mst tmp/biblio.mst || error
mv -f tmp/bibliotmp.xrf tmp/biblio.xrf || error


# ------------------------------------------------------------------
# Para la base bibima, tenemos que añadir a la base biblio los registros del SeCS
# Como input necesitamos:
#     * base secstitle (la base title de SeCS, en formato linux)
#     * archivo EMA.001 (listado de existencias, generado desde SeCS)
#     * base oem2ansi (el gizmo para cambio de codificación)
#     * archivo secs2marc.proc (migración SeCS => MARC21)
# ------------------------------------------------------------------
if [ -f $SOURCE_DIR/$DB_NAME-secstitle.zip ]; then    # testeamos si existe la base secstitle asociada
	echo
	cecho "blue" "Procesando base SECSTITLE..."
	
	# TO-DO: usar mxcp para eliminar espacios en la base title
	
	# paso 0: descomprimimos la base
	unzip -oq $SOURCE_DIR/$DB_NAME-secstitle.zip -d tmp || error "No se pudo descomprimir el archivo $SOURCE_DIR/$DB_NAME-secstitle.zip"
	
	# paso 1: recodificamos caracteres
	mx tmp/secstitle gizmo=OEM2ANSI create=tmp/title now -all || error "Hubo una falla al ejecutar mx"
	
	# paso 2: creamos una base de holdings
	mx seq=tmp/EMA.001 create=tmp/holdings now -all || error "Hubo una falla al ejecutar mx"
	mx tmp/holdings "fst=2 0 v2" fullinv=tmp/holdings || error "Hubo una falla al ejecutar mx"
	
	# paso 3: insertamos la información sobre holdings en los registros bibliográficos
	mx tmp/title "proc='a98|',ref(['tmp/holdings']l(['tmp/holdings']v40^c),v3),'|'" copy=tmp/title now -all || error "Hubo una falla al ejecutar mx"
	
	# paso 4: migramos a MARC
	mx tmp/title "proc=@SECS2MARC.PROC" create=tmp/title_marc now -all || error "Hubo una falla al ejecutar mx"
	
	# paso 5: añadimos los registros a la base biblio
	mx tmp/title_marc append=tmp/biblio now -all || error "Hubo una falla al ejecutar mx"
fi
# ------------------------------------------------------------------


# Si hay imágenes de tapa, creamos un campo 985
if [ ! -d $DIR_IMG ]; then
	echo
	cecho "blue" "No hay directorio de imagenes"
else
	echo
	cecho "blue" "Procesando imágenes de tapas..."
	ls $DIR_IMG | grep '00[0-9]\{4\}\.[a-z]\{3\}$' > tmp/lista_img.txt 	# TO-DO: revisar esta expresión regular
	mx seq=tmp/lista_img.txt create=tmp/lista_img now -all || error "Hubo una falla al ejecutar mx"
	mx tmp/lista_img "proc='d1a1#',v1.6,'^f',v1*7.3,'#'" copy=tmp/lista_img now -all || error "Hubo una falla al ejecutar mx"
	mx tmp/lista_img "fst=1 0 v1^*" fullinv=tmp/lista_img || error "Hubo una falla al ejecutar mx"
	
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
	mx tmp/biblio "proc=if l(['tmp/lista_img']v1) > 0 then 'd985a985!##^a',ref(['tmp/lista_img']l(['tmp/lista_img']v1),v1^f),'!' fi" copy=tmp/biblio tell=$TELL now -all || error "Hubo una falla al ejecutar mx"
fi


# ------------------------------------------------------------------
# BASE BIBLIO (1ra pasada)
# ------------------------------------------------------------------

echo
cecho "blue" "Creamos una copia (texto) de la base bibliografica..."
i2id tmp/biblio tell=$TELL > tmp/biblio1.id     # || error "Hubo una falla al ejecutar i2id"
# BUG en i2id: aun sin haber errores, el exit status es diferente de cero (e.g. 17, 19). Se testea con 'echo $?'

echo
cecho "blue" "Intentamos normalizar la puntuacion final, filtramos encabezamientos"
cecho "blue" "tematicos, y asignamos un numero (provisorio) a cada campo"
cecho "blue" "de encabezamientos en el subcampo ^9..."
mx "seq=tmp/biblio1.id\n" lw=3000 "pft=@HEAD.PFT" now tell=$TELL > tmp/biblio2.id || error "Hubo una falla al ejecutar mx"


# ------------------------------------------------------------------
# BASE SUBJ
# ------------------------------------------------------------------

echo
cecho "blue" "-----------------------------------------------------"
cecho "blue" " Base de encabezamientos tematicos"
cecho "blue" "-----------------------------------------------------"

cecho "blue" "Creamos el listado de encabezamientos tematicos..."
mx "seq=tmp/biblio2.id\n" lw=1000 "pft=if getenv('SUBJ_TAGS') : v1*1.4 then @SUBJ.PFT fi" now tell=$TELL > tmp/subj1.id || error "Hubo una falla al ejecutar mx"

echo
cecho "blue" "Convertimos el listado en una base (desordenada y con duplicados)..."
id2i tmp/subj1.id create/app=tmp/subj1 tell=$TELL || error "Hubo una falla al ejecutar id2i"

echo
cecho "blue" "Regularizamos la puntuacion final de los encabezamientos generados..."
mx tmp/subj1 "proc='d2a2¦',v1,'¦'" "proc='d1a1¦',@REGPUNT.PFT,'¦'" "proc='d2'" copy=tmp/subj1 now -all tell=$TELL || error "Hubo una falla al ejecutar mx"

echo
cecho "blue" "Almacenamos en un campo auxiliar la clave de ordenacion..."
mx tmp/subj1 uctab=UC-ANSI.TAB "proc='d99a99¦',@HEADSORT.PFT,'¦'" copy=tmp/subj1 now -all tell=$TELL || error "Hubo una falla al ejecutar mx"

echo
cecho "blue" "Ordenamos la base de encabezamientos tematicos..."
msrt tmp/subj1 100 v99 tell=$TELL || error "Hubo una falla al ejecutar msrt"

echo
cecho "blue" "Generamos la tabla para mapear los numeros de encabezamientos..."
mx tmp/subj1 "pft=if s(v1) <> ref(mfn-1,v1) then putenv('HEADING_CODE='v9) fi, v9,'|',getenv('HEADING_CODE')/" now -all tell=$TELL > tmp/subjcode.seq || error "Hubo una falla al ejecutar mx"

echo
cecho "blue" "Eliminamos los encabezamientos duplicados..."
mx tmp/subj1 lw=1000 "pft=@ELIMDUP2.PFT" now tell=$TELL > tmp/subj.id || error "Hubo una falla al ejecutar mx"

echo
cecho "blue" "Creamos la base de encabezamientos tematicos (ordenada y sin duplicados)..."
id2i tmp/subj.id create/app=subj tell=$TELL || error "Hubo una falla al ejecutar id2i"


# ------------------------------------------------------------------
# BASE NAME
# ------------------------------------------------------------------

echo
cecho "blue" "-----------------------------------------------------"
cecho "blue" " Base de encabezamientos de nombres"
cecho "blue" "-----------------------------------------------------"

cecho "blue" "Creamos el listado de encabezamientos de nombres..."
mx "seq=tmp/biblio2.id\n" lw=1000 "pft=if getenv('NAME_TAGS') : v1*1.4 then @NAME.PFT fi" now tell=$TELL > tmp/name1.id || error "Hubo una falla al ejecutar mx"

echo
cecho "blue" "Convertimos el listado en una base (desordenada y con duplicados)..."
id2i tmp/name1.id create/app=tmp/name1 tell=$TELL || error "Hubo una falla al ejecutar id2i"

echo
cecho "blue" "Regularizamos la puntuacion final de los encabezamientos generados..."
mx tmp/name1 "proc='d2a2¦',v1,'¦'" "proc='d1a1¦',@REGPUNT.PFT,'¦'" "proc='d2'" copy=tmp/name1 now -all tell=$TELL || error "Hubo una falla al ejecutar mx"

echo
cecho "blue" "Almacenamos en un campo auxiliar la clave de ordenacion..."
mx tmp/name1 uctab=UC-ANSI.TAB "proc='d99a99¦',@HEADSORT.PFT,'¦'" copy=tmp/name1 now -all tell=$TELL || error "Hubo una falla al ejecutar mx"

echo
cecho "blue" "Ordenamos la base de encabezamientos de nombres..."
msrt tmp/name1 100 v99 tell=$TELL || error "Hubo una falla al ejecutar msrt"

echo
cecho "blue" "Generamos la tabla para mapear los numeros de encabezamientos..."
mx tmp/name1 "pft=if s(v1) <> ref(mfn-1,v1) then putenv('HEADING_CODE='v9) fi, v9,'|',getenv('HEADING_CODE')/" now -all tell=$TELL > tmp/namecode.seq || error "Hubo una falla al ejecutar mx"

echo
cecho "blue" "Eliminamos los encabezamientos duplicados..."
mx tmp/name1 lw=1000 "pft=@ELIMDUP2.PFT" now tell=$TELL > tmp/name.id || error "Hubo una falla al ejecutar mx"

echo
cecho "blue" "Creamos base de encabezamientos de nombres (ordenada y sin duplicados)..."
id2i tmp/name.id create/app=name tell=$TELL || error "Hubo una falla al ejecutar id2i"


echo
# -----------------------------------------------------------------
cecho "blue" "Reasignamos numeros a los encabezamientos en los registros"
cecho "blue" "bibliograficos (subcampo 9)..."
# -----------------------------------------------------------------
mx seq=tmp/subjcode.seq create=tmp/subjcode now -all || error "Hubo una falla al ejecutar mx"
mx tmp/subjcode "fst=1 0 v1" fullinv=tmp/subjcode || error "Hubo una falla al ejecutar mx"
mx seq=tmp/namecode.seq create=tmp/namecode now -all || error "Hubo una falla al ejecutar mx"
mx tmp/namecode "fst=1 0 v1" fullinv=tmp/namecode || error "Hubo una falla al ejecutar mx"

mx "seq=tmp/biblio2.id\n" lw=1000 "pft=@RECODE.PFT" now tell=$TELL > tmp/biblio3.id || error "Hubo una falla al ejecutar mx"


# ------------------------------------------------------------------
# BASE TITLE
# ------------------------------------------------------------------

echo
cecho "blue" "-----------------------------------------------------"
cecho "blue" " Base de titulos"
cecho "blue" "-----------------------------------------------------"

cecho "blue" "Creamos listado de titulos..."
mx "seq=tmp/biblio3.id\n" lw=1000 "pft=if getenv('TITLE_TAGS') : v1*1.4 then ,@TITLE.PFT, fi" now tell=$TELL > tmp/title1.id || error "Hubo una falla al ejecutar mx"

echo
cecho "blue" "Convertimos el listado en una base (desordenada y con duplicados)..."
id2i tmp/title1.id create/app=tmp/title1 tell=$TELL || error "Hubo una falla al ejecutar id2i"

echo
cecho "blue" "Almacenamos en un campo auxiliar (99) la clave de ordenacion de titulos."
mx tmp/title1 uctab=UC-ANSI.TAB "proc='d99a99¦',@HEADSORT.PFT,'¦'" copy=tmp/title1 now -all tell=$TELL || error "Hubo una falla al ejecutar mx"

echo
cecho "blue" "Ordenamos la base de titulos."
msrt tmp/title1 100 v99 tell=$TELL || error "Hubo una falla al ejecutar msrt"

echo
cecho "blue" "Eliminamos los titulos duplicados."
mx tmp/title1 lw=1000 "pft=@ELIMDUP2.PFT" now tell=$TELL > tmp/title.id || error "Hubo una falla al ejecutar mx"

echo
cecho "blue" "Creamos la base de titulos (ordenada y sin duplicados)."
id2i tmp/title.id create/app=title tell=$TELL || error "Hubo una falla al ejecutar id2i"


# ------------------------------------------------------------------
# BASE BIBLIO (2da pasada)
# ------------------------------------------------------------------

echo
cecho "blue" "-----------------------------------------------------"
cecho "blue" "Base bibliografica"
cecho "blue" "-----------------------------------------------------"

cecho "blue" "Recreamos la base bibliografica."
id2i tmp/biblio3.id create=biblio tell=$TELL || error "Hubo una falla al ejecutar id2i"

echo
cecho "blue" "Ordenamos la base bibliografica."
msrt biblio 100 @LOCATION_SORT.PFT tell=$TELL || error "Hubo una falla al ejecutar msrt"


# ------------------------------------------------------------------
# FULLINV
# ------------------------------------------------------------------

# -------------------------------------------------------------------
# Generacion de archivos invertidos.
# ATENCION: AC-ANSI.TAB envia los numeros al diccionario.
# -------------------------------------------------------------------

echo
cecho "blue" " Archivo invertido - Base de temas..."
mx subj fst=@HEADINGS.FST actab=AC-ANSI.TAB uctab=UC-ANSI.TAB fullinv=subj tell=$TELL || error "Hubo una falla al ejecutar mx"

echo
cecho "blue" " Archivo invertido - Base de nombres..."
mx name fst=@HEADINGS.FST actab=AC-ANSI.TAB uctab=UC-ANSI.TAB fullinv=name tell=$TELL || error "Hubo una falla al ejecutar mx"

echo
cecho "blue" " Archivo invertido - Base de titulos..."
mx title "fst=2 0 '~',@HEADSORT.PFT" actab=AC-ANSI.TAB uctab=UC-ANSI.TAB fullinv=title tell=$TELL || error "Hubo una falla al ejecutar mx"

echo
cecho "blue" " Archivo invertido - Base bibliografica..."
# Antes de la FST, aplicamos un gizmo a los campos que generan puntos de acceso
mx biblio gizmo=DICTGIZ,100,110,111,130,700,710,711,730,800,810,811,830 gizmo=DICTGIZ,240,245,246,440,740,600,610,611,630,650,651,653,655,656 fst=@BIBLIO.FST actab=AC-ANSI.TAB uctab=UC-ANSI.TAB stw=@BIBLIO.STW fullinv=biblio tell=$TELL || error "Hubo una falla al ejecutar mx"


# ------------------------------------------------------------------
# REGISTROS ANALÍTICOS
# ------------------------------------------------------------------

echo
cecho "blue" "Detectando registros analíticos..."
# Para los registros analíticos, creamos un 773$9 donde guardar el MFN
# del registro asociado, y así ahorrar futuros lookups en el diccionario
# ATENCION: esto debe hacerse *después* de aplicado el msrt y generado el diccionario

mx biblio "proc=if p(v773^w) then 'd773a773¦',v773,'^9',f(l('-NC=',v773^w),1,0),'¦', fi" copy=biblio now -all tell=$TELL || error "Hubo una falla al ejecutar mx"

# Compactamos la base
mx biblio create=bibliotmp now -all || error "Hubo una falla al ejecutar mx"
# no usamos rename, porque su sintaxis depende de la distribución de Linux
mv -f bibliotmp.mst biblio.mst || error
mv -f bibliotmp.xrf biblio.xrf || error


#echo
#cecho "blue" "Títulos de seriadas..."
#mx biblio "-BIBLEVEL=S" "pft=replace(v245*2,'^','~')" now -all > title_serial.txt


# ------------------------------------------------------------------
# POSTINGS
# ------------------------------------------------------------------

echo
# --------------------------------------------------------
cecho "blue" "Asignamos postings a los terminos del indice de temas."
# --------------------------------------------------------
mx subj "proc='d11a11#',f(npost(['biblio']'_SUBJ_'v9),1,0),'#'" copy=subj now -all tell=$TELL || error "Hubo una falla al ejecutar mx"

echo
# ----------------------------------------------------------
cecho "blue" "Asignamos postings a los terminos del indice de nombres."
# ----------------------------------------------------------
mx name "proc='d11a11#',f(npost(['biblio']'_NAME_'v9),1,0),'#'" copy=name now -all tell=$TELL || error "Hubo una falla al ejecutar mx"

# TO-DO: necesitamos postings para los títulos controlados (series, títulos uniformes).
# Para eso necesitamos un subcampo $9 en la base de títulos.


# ------------------------------------------------------------------
# DICCIONARIOS PARA AGREP
# ------------------------------------------------------------------

echo
# -----------------------------------------------------
cecho "blue" "Generamos diccionarios para AGREP."
# Solo nos interesan claves asociadas a ciertos tags.
# /100 restringe la cantidad de postings (de lo contrario, da error)
# ATENCION: los sufijos NAME, SUBJ, TITLE van en mayusculas o minusculas
# en base a los valores que tome el parámetro CGI correspondiente.
# -----------------------------------------------------
cecho "blue" "   - subj"
# Para bibima usamos la base MSC; para el resto, la base SUBJ
# TO-DO: la base subj también sirve para bibima; usar cat & uniq
if [ "$DB_NAME" = "bibima" ]; then
    mx dict=MSC "pft=v1^*/" k1=a k2=zz now > dictSUBJ.txt || error "Hubo una falla al ejecutar mx"
else
    mx dict=subj "pft=v1^*/" k1=a k2=zz now > dictSUBJ.txt || error "Hubo una falla al ejecutar mx"
fi

cecho "blue" "   - name"
mx dict=name "pft=v1^*/" k1=a k2=zz now > dictNAME.txt || error "Hubo una falla al ejecutar mx"

cecho "blue" "   - title (incluye series)"
#mx dict=biblio,1,2/100  "pft=if v2^t : '204' then v1^*/ fi" k1=a now > dicttitle.txt
ifkeys biblio +tags from=a to=zzzz > tmp/titlekeys.txt || error "Hubo una falla al ejecutar ifkeys"
mx seq=tmp/titlekeys.txt "pft=if '204~404' : right(v2,3) then v3/ fi" now > tmp/titlekeys2.txt || error "Hubo una falla al ejecutar mx"
cat tmp/titlekeys2.txt | uniq > dictTITLE.txt || error

cecho "blue" "   - any"
# union de los diccionarios anteriores (eliminando términos duplicados)
cat dict*.txt | sort | uniq > dictANY.txt || error


# ------------------------------------------------------------------
# ARCHIVOS AUXILIARES
# ------------------------------------------------------------------

echo
# -----------------------------------------------------
cecho "blue" "Lista de codigos de idioma."
# -----------------------------------------------------
mx seq=LANG.TXT create=tmp/lang now -all || error "Hubo una falla al ejecutar mx"
mx tmp/lang fst=@LANG.FST fullinv=tmp/lang || error "Hubo una falla al ejecutar mx"
mx dict=biblio "k1=-LANG=A" "k2=-LANG=ZZZ" "pft=v1^**6.3,'|',v1^t/" now > tmp/langcode.txt || error "Hubo una falla al ejecutar mx"
mx seq=tmp/langcode.txt create=tmp/langcode now -all || error "Hubo una falla al ejecutar mx"
msrt tmp/langcode 30 "ref(['tmp/lang']l(['tmp/lang']v1.3),s(mpu,v3))" || error "Hubo una falla al ejecutar msrt"
mx tmp/langcode "pft=v1,'^p',v2,'^',/" now -all > langcode.txt || error "Hubo una falla al ejecutar mx"


if [ "$DB_NAME" = "bibima" ]; then
	echo
	# -----------------------------------------------------
	cecho "blue" "Actualizamos los postings para cada código MSC"
	# -----------------------------------------------------
	mx MSC "proc=if l(['biblio']'-MSC='v1) > 0 then 'd7a7@',f(npost(['biblio']'-MSC='v1),1,0),'@' fi" copy=MSC now -all tell=$TELL || error "Hubo una falla al ejecutar mx"
	# TO-DO: compactar la base MSC
fi


echo
# -----------------------------------------------------
cecho "blue" "Lista de codigos de bibliotecas."
# -----------------------------------------------------
mx dict=biblio "k1=-BIB=A" "k2=-BIB=ZZZ" "pft=v1^**5,'^p',v1^t/" now > bibcode.txt || error "Hubo una falla al ejecutar mx"


echo
# -----------------------------------------------------
cecho "blue" "Fechas extremas."
# -----------------------------------------------------
mx dict=biblio "k1=-F=1" "k2=-F=2999" "pft=v1^**3/" now > tmp/dates1.txt || error "Hubo una falla al ejecutar mx"
mx tmp to=1 "proc='a1~',replace(s(cat('tmp/dates1.txt')),s(#),'&'),'~'" "pft=v1.4,'-',s(right(v1,5)).4" > dates.txt || error "Hubo una falla al ejecutar mx"

# -----------------------------------------------------
# Total de registros disponibles
# -----------------------------------------------------
echo > bases.txt || error
mx biblio count=1 "pft=proc('a5001~',f(maxmfn-1,1,0),'~'),'BIBLIOGRAPHIC_TOTAL=',left(v5001,size(v5001)-3),if size(v5001) > 3 then '.' fi,right(v5001,3)/" >> bases.txt || error "Hubo una falla al ejecutar mx"
mx name count=1 "pft=proc('a5001~',f(maxmfn-1,1,0),'~'),'NAME_TOTAL=',left(v5001,size(v5001)-3),if size(v5001) > 3 then '.' fi,right(v5001,3)/" >> bases.txt || error "Hubo una falla al ejecutar mx"
mx subj count=1 "pft=proc('a5001~',f(maxmfn-1,1,0),'~'),'SUBJ_TOTAL=',left(v5001,size(v5001)-3),if size(v5001) > 3 then '.' fi,right(v5001,3)/" >> bases.txt || error "Hubo una falla al ejecutar mx"
mx title count=1 "pft=proc('a5001~',f(maxmfn-1,1,0),'~'),'TITLE_TOTAL=',left(v5001,size(v5001)-3),if size(v5001) > 3 then '.' fi,right(v5001,3)/" >> bases.txt || error "Hubo una falla al ejecutar mx"

# -----------------------------------------------------
# Total de ejemplares disponibles
# -----------------------------------------------------

# ATENCION: necesitamos una buena definición de "ejemplares" (los "items" de FRBR)
# Por ahora, vamos a contar los nros. de inventario, 859$p
mx biblio "pft=(v859^p/)" now | wc -l > tmp/items-total.txt || error "Hubo una falla al ejecutar mx"
mx seq=tmp/items-total.txt "pft=proc('d1a1|',replace(v1,' ',''),'|'), if size(v1) > 3 then left(v1,size(v1)-3),'.',right(v1,3), else v1, fi" now > tmp/items-total-punto.txt || error "Hubo una falla al ejecutar mx"
echo "ITEMS_TOTAL=`cat tmp/items-total-punto.txt`" >> bases.txt || error

cat bases.txt || error

echo
# -----------------------------------------------------
cecho "blue" "Listado de novedades."
# -----------------------------------------------------
# TO-DO: generalizar para cualquier año y/o mes, y para otros criterios (e.g. en ABCI por inventario)
mx biblio "pft=if v859^y[1]*6 = '2006' then v1/ fi" now | sort > novedades.txt || error "Hubo una falla al ejecutar mx"

echo
# -----------------------------------------------------
cecho "blue" "Fecha de esta actualizacion."
# -----------------------------------------------------
mx tmp "pft=s(date)*6.2,'/',s(date)*4.2,'/',s(date).4,' a las ',s(date)*9.2,':',s(date)*11.2" to=1 > updated.txt || error "Hubo una falla al ejecutar mx"


# ------------------------------------------------------------------
# CONVERSION A WINDOWS
# ------------------------------------------------------------------

if [ "$CONVERT_WINDOWS" = "1" ]; then
	echo
	cecho "blue" "Conversion a Windows: bases de datos."
	if [ ! -d "windows" ]; then
		mkdir windows || error "No se pudo crear el directorio windows"
	fi
	#cecho "blue" "Directorio $2/windows creado."

	cecho "blue" "   - biblio"
	crunchmf biblio windows/biblio || error "Hubo una falla al ejecutar crunchmf"
	crunchif biblio windows/biblio || error "Hubo una falla al ejecutar crunchif"

	cecho "blue" "   - name"
	crunchmf name windows/name || error "Hubo una falla al ejecutar crunchmf"
	crunchif name windows/name || error "Hubo una falla al ejecutar crunchif"

	cecho "blue" "   - subj"
	crunchmf subj windows/subj || error "Hubo una falla al ejecutar crunchmf"
	crunchif subj windows/subj || error "Hubo una falla al ejecutar crunchif"

	cecho "blue" "   - title"
	crunchmf title windows/title || error "Hubo una falla al ejecutar crunchmf"
	crunchif title windows/title || error "Hubo una falla al ejecutar crunchif"
	
	cecho "blue" "Conversion a Windows: archivos de texto."
	cp *.txt windows/
	unix2dos windows/*.txt     
fi


# Eliminamos archivos temporales generados por este script
if [ "$CLEAN" = "1" ]; then
	echo
	cecho "blue" "Eliminando archivos temporales..."
	rm -rf tmp/ || error "No se puede eliminar el directorio tmp"
	rm -rf *.ln* 2>/dev/null
	rm -rf *.lk* 2>/dev/null
fi


# Movemos los archivos generados (previamente vaciamos $TARGET_DIR)
# TO-DO: supongamos que alguien quiere mover la versión para Windows de las bases...  
if [ "$MOVE" = "1" ]; then
	echo
	cecho "blue" "Moviendo los archivos generados..."
	rm -rf $TARGET_DIR/* || error "No se puede vaciar el directorio $TARGET_DIR"
	mv -f *.* $TARGET_DIR || error "No se puede mover los archivos a $TARGET_DIR"
fi

# ¿esto es necesario?
CIPAR=

echo
cecho "blue" "`basename $0` finalizó exitosamente. Hasta pronto."
echo
exit 0
