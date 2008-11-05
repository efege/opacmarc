#
# Adaptación a Linux. Completar. Consultar update-opac.sh
#

# ===============================================================================
# Creación de una base de pseudo-autoridades a partir de una base bibliográfica
# existente.
#
# Uso:   auto </path/to/archivo_maestro_biblio>
#
# Ejemplos:  auto /var/www/bases/test/biblio
#            auto biblio  (si la base biblio está en el directorio 'autoridades')
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


# --------------------------------------------------------------
# COMIENZO DE CONFIGURACION
# --------------------------------------------------------------

# Directorio de trabajo. Aquí se almacenan archivos temporales.
WORK=work

# Directorio de salida. Aquí se almacenan las bases e informes generados.
OUTPUT=output

# Lista de tags de los cuales vamos a extraer los encabezamientos.
# TO-DO: ver cómo manejar los encabezamientos de nombre-título:
#     100, 110, 111 pueden estar asociados a un 240 (título uniforme)
#     700, 710, 711, 600, 610, 611 pueden incluir un $t (título uniforme)
#     800, 810 y 811 siempre incluyen un $t (título uniforme de serie)
MAIN_ENTRY=v100~v110~v111~v130
ADDED_ENTRY=v700~v710~v711~v730
SERIES=v440~v800~v810~v811~v830
SUBJECT1=v600~v610~v611~v630
SUBJECT2=v650~v651~v655~v656
CONTROLLED_TAGS=$MAIN_ENTRY~$ADDED_ENTRY~$SERIES~$SUBJECT1

# Prefijo usado en el identificador de los registros de autoridad (número de control, campo 001).
# Usamos 'a' por 'autoridad'.
PREFIX=a

# Límite de tolerancia usado en la detección de posibles duplicados mediante la distancia de Levenshtein.
# Usar '0' para que no tolere errores (i.e., 2 encabezamiento se consideran duplicados sólo si son
# exactamente iguales), '1' para que tolere un error (i.e., si la distancia de Levenshtein es 1 se
# consideran duplicados), etc.
# Es conveniente probar con diferentes valores para tener una idea del tipo de "duplicados" que detecta.
# Más info: http://www.php.net/manual/en/function.levenshtein.php
LEV_LIMIT=5

# Delimitador de campos usado por el comando 'mx seq=archivo'.
# El delimitador por defecto es la barra vertical ('|'). Como este carácter puede estar presente
# en los registros --p.ej. en el campo 008-- necesitamos usar cualquier otro carácter
# que no esté presente en la base biblio.
# Parece que anda bien con un carácter de control como p.ej. asc 30 (hex 1E, "record separator").
# ATENCION: mx 5.2 no admite algunos delimitadores! (e.g. '¬', '´', '§', etc).
# TO-DO: averiguar si mx permite una solución más elegante a este problema.
# 2007-08-27: Según E. Spinak, la solución pasa por usar el separador '\', entre comillas:  mx "seq=<file>\".
# Anda, pero sólo si no uso ningún parámetro a continuación del seq. :(
SEQ_DELIM=

# Longitud de línea. Valor para el parámetro lw de mx. Debe ser mayor que la máxima
# longitud de un campo de la base biblio, para evitar que un campo pueda quedar partido.
LW=10000

# Valor del parámetro tell de mx. Es preferible usar un valor muy grande, o bien '0',
# para que los mensajes frecuentes de tell no impidan ver posibles mensajes de error.
TELL=0

# Usar '1' para que al finalizar la ejecución se eliminen los archivos temporales (directorio $WORK).
CLEAN=0

# Comando usado para procesar errores.
CHECK_ERROR=if errorlevel 1 goto ERROR

# --------------------------------------------------------------
# FIN DE CONFIGURACION
# --------------------------------------------------------------


# La base bibliográfica de origen.
BIBLIO=$1

# Creamos directorios auxiliares.
# Método para detectar existencia de directorios tomado de http://www.macalester.edu/~fines/batch_tricks.htm
if not exist $WORK/nul if not exist $WORKnul mkdir $WORK
%CHECK_ERROR%_MKDIR
rm -f $WORK/*.*
if not exist $OUTPUT/nul  if not exist $OUTPUTnul  mkdir $OUTPUT
%CHECK_ERROR%_MKDIR
rm -f $OUTPUT/*.*

# cipar para mx
#echo map.*=\svn\campi\autoridades\$WORK/map.* >cipar.txt
echo AC-ANSI.TAB=ac-ansi.tab>$WORK/cipar.txt
echo UC-ANSI.TAB=uc-ansi.tab>>$WORK/cipar.txt
cipar=$WORK/cipar.txt

# Verificamos que no haya problemas con el delimitador elegido.
# TO-DO: sugerir el uso de mxf0 para determinar caracteres no usados.
# ATENCION: esto no sería necesario si usáramos la sugerencia de E. Spinak.
echo x| mx $BIBLIO "text/show=$SEQ_DELIM" > $WORK/delim.txt
mx tmp count=1 "pft=if size(cat('$WORK/delim.txt')) > 0 then system('echo ERROR>$WORK/delim-error.txt'), fi" now
if exist $WORK/delim-error.txt goto ERROR_DELIM


echo.
echo --------------------------------------------------
echo 1 - CONSTRUCCION DE BASE AUTO
echo --------------------------------------------------

# Si está presente el campo 240, creamos un campo auxiliar 1xx + $t (nombre/título)
#mx $BIBLIO proc=@v240.pft create=$WORK/biblio-240 now -all

echo $PREFIX>$WORK/prefix

# Eliminamos campo 1106 y creamos una copia de trabajo de la base bibliográfica.
mx $BIBLIO "proc='d1106'" create=$WORK/biblio now -all tell=$TELL

# Cada campo de la base bibliográfica pasa a ser un registro de la base biblio-campos.
echo Creando lista de campos...
i2id $WORK/biblio >$WORK/biblio.id
mx "seq=$WORK/biblio.id$SEQ_DELIM" lw=$LW create=$WORK/biblio-campos now -all tell=$TELL
%CHECK_ERROR%

# Eliminamos espacios en blanco en los extremos (¿a qué se deben esos espacios?)
# TO-DO: ¿vale la pena hacer la limpieza sobre toda la base, si solo nos interesan los encabezamientos?
echo Eliminando espacios en blanco...
mxcp $WORK/biblio-campos create=$WORK/biblio-campos-clean clean log=$OUTPUT/mxcp-biblio-campos.txt >nul tell=$TELL

# Extraemos los campos con encabezamientos controlados, y creamos una base con ellos.
# ATENCION: para filtrar subcampos $e, $4, $5, podemos usar algo como name.pft del OPAC. (??)
# TO-DO: para uctab necesitamos usar una tabla ad hoc.
echo Extrayendo encabezamientos controlados...
mx $WORK/biblio-campos-clean uctab=UC-ANSI.TAB lw=$LW pft=@extract-headings.pft now tell=$TELL >$WORK/auto-dup.seq
%CHECK_ERROR%
mx seq=$WORK/auto-dup.seq create=$WORK/auto-dup now -all tell=$TELL
%CHECK_ERROR%

# Ordenamos la lista de encabezamientos.
# Usamos el formato "mpu,v1*4" para comparar en mayúsculas, ignorando los indicadores y el primer delimitador de subcampo.
# Necesitamos guardar la clave en un campo auxiliar (99) para poder usar la tabla correcta de conversión a mayúsculas.
echo Ordenando lista de encabezamientos...
mx $WORK/auto-dup uctab=UC-ANSI.TAB "proc='a99|',mpu,v1*4,'|'" copy=$WORK/auto-dup now -all tell=$TELL
%CHECK_ERROR%
msrt $WORK/auto-dup 1000 v99

# Eliminamos encabezamientos duplicados.
# Usamos el formato "v1*2" para comparar encabezamientos ignorando los indicadores.
# La comparación es directa (sin conversión a mayúsculas ni de otro tipo), por lo tanto detecta *cualquier* diferencia.
# ATENCION: si normalizamos *antes* el 2do indicador de x00, x10, x11, ¿podemos acá incluir los indicadores en la comparación?
echo Eliminando encabezamientos duplicados...
mx $WORK/auto-dup lw=$LW "pft=if v1*2 <> ref(mfn-1,v1*2) then v1,'|',v2,'|',v3/ fi" now >$WORK/auto-uniq.seq
mx seq=$WORK/auto-uniq.seq lw=$LW create=$WORK/auto-uniq now -all
%CHECK_ERROR%

# Reasignamos tags y ajustamos los indicadores en los registros de autoridades.
echo Reasignando tags y ajustando indicadores...
mx $WORK/auto-uniq "proc=@fix-tags-indicators.pft" create=$WORK/auto now -all tell=$TELL
%CHECK_ERROR%

# Agregamos campos a los registros de autoridades: leader, 005, 008, 999.
echo Agregando campos: leader, 005, 008, 999...
mx $WORK/auto "proc=@008etc.pft" copy=$WORK/auto now -all
%CHECK_ERROR%

# Ordenamos por tag los campos de cada registro de autoridad.
echo Ordenando campos en los registros de autoridad...
mx $WORK/auto "proc='s'" create=$OUTPUT/auto now -all

# PRUEBA: generar registros inactivos en la base auto a partir del 2do registro
#         Todos los registros de la base auto son alias del primero.
#mx $WORK/auto from=2 "proc='d999a999@001766@'" copy=$WORK/auto now -all

# Diccionario para la base de autoridades.
echo Generando diccionario para la base de autoridades...
mx $OUTPUT/auto fst=@auto.fst actab=AC-ANSI.TAB uctab=UC-ANSI.TAB fullinv=$OUTPUT/auto

echo.
echo --------------------------------------------------
echo 2 - GENERACION DE INFORMES
echo --------------------------------------------------

# Generamos algunos informes sobre las bases biblio y auto.

echo mxf0...
# mxf0 para biblio.
mxf0 $BIBLIO create=$WORK/biblio-mxf0
mx $WORK/biblio-mxf0 "pft=@mxf0.pft" now >$OUTPUT/biblio-mxf0.html

# mxf0 para auto.
mxf0 $WORK/auto create=$WORK/auto-mxf0
mx $WORK/auto-mxf0 "pft=@mxf0.pft" now >$OUTPUT/auto-mxf0.html

# Frecuencia de los campos usados para generar encabezamientos.
echo Frecuencia de campos de encabezamientos...
mxtb $WORK/auto-uniq create=$WORK/tag-freq 3:v3
msrt $WORK/tag-freq 3 v1
mx $WORK/tag-freq "pft=v1,c10,v999/" now >$OUTPUT/tag-freq.txt

# Listados de encabezamientos por tipo.
echo Listados de encabezamientos por tipo...
mx $WORK/auto lw=$LW "pft=v100/" now >$OUTPUT/auto-100.txt
mx $WORK/auto lw=$LW "pft=v110/" now >$OUTPUT/auto-110.txt
mx $WORK/auto lw=$LW "pft=v111/" now >$OUTPUT/auto-111.txt
mx $WORK/auto lw=$LW "pft=v130/" now >$OUTPUT/auto-130.txt

# Algunos listados por valor de indicadores.
echo Listados por valor de indicadores...
mx $WORK/auto lw=$LW "pft=if p(v100) and v100.1 <> '1' then v100/ fi" now >$OUTPUT/auto-100-not1.txt
mx $WORK/auto lw=$LW "pft=if p(v110) and v110.1 <> '2' then v110/ fi" now >$OUTPUT/auto-110-not2.txt
mx $WORK/auto lw=$LW "pft=if p(v111) and v111.1 <> '2' then v111/ fi" now >$OUTPUT/auto-111-not2.txt
mx $WORK/auto lw=$LW "pft=if p(v130) and v130*1.1 <> '0' then v130/ fi" now >$OUTPUT/auto-130-not0.txt

# Listado de encabezamientos de nombre-título.
echo Listado de encabezamientos de nombre-título...
echo --------- 100 --------->$OUTPUT/auto-nombre-titulo.txt
mx $WORK/auto lw=$LW "pft=if p(v100^t) then v100/ fi" now >>$OUTPUT/auto-nombre-titulo.txt
echo. >>$OUTPUT/auto-nombre-titulo.txt
echo --------- 110 --------->>$OUTPUT/auto-nombre-titulo.txt
mx $WORK/auto lw=$LW "pft=if p(v110^t) then v110/ fi" now >>$OUTPUT/auto-nombre-titulo.txt
echo. >>$OUTPUT/auto-nombre-titulo.txt
echo --------- 111 --------->>$OUTPUT/auto-nombre-titulo.txt
mx $WORK/auto lw=$LW "pft=if p(v111^t) then v111/ fi" now >>$OUTPUT/auto-nombre-titulo.txt

# Lista de posibles duplicados (requiere que el ejecutable PHP esté en el PATH).
# TO-DO: considerar la aplicación de un criterio como el de NACO <http://www.loc.gov/catdir/pcc/naco/normrule.html>
# TO-DO: incluir número de control en el listado
echo Generando lista de posibles duplicados...
mx $OUTPUT/auto lw=$LW "pft=v100/v110/v111/v130/v150/v151/v155/" now >$WORK/auto-lista.txt
php compara-lev.php $WORK/auto-lista.txt $LEV_LIMIT >$OUTPUT/auto-posibles-duplicados.txt
if errorlevel 1 echo *** Se produjo un error al llamar a php. Verifique si php esta en el PATH.


echo.
echo --------------------------------------------------
echo 3 - GENERACION DE LINKS ENTRE BIBLIO y AUTO
echo --------------------------------------------------

# TO-DO: explicar bien qué sucede en cada paso de este proceso, usando un ejemplo.

# Construimos tabla de mapeo de punteros a la base bibliográfica.
echo Construyendo tabla para mapear punteros...
mx $WORK/auto-dup "pft=if v1*2 <> ref(mfn-1,v1*2) then putenv('PTR=',v2) fi, v2,'|',getenv('PTR')/" now -all >$WORK/map.seq
mx seq=$WORK/map.seq create=$WORK/map now -all
%CHECK_ERROR%

# Diccionario para map.
mx $WORK/map "fst=1 0 v1/" fullinv=$WORK/map

# Creamos un subcampo $0 en cada punto de acceso.
# ¿Por qué subcampo $0? Ver http://www.loc.gov/marc/marbi/2007/2007-06.html
echo Creando subcampos $0 en los puntos de acceso...
mx $WORK/biblio-campos-clean proc=@create-subfield-0.pft create=$WORK/biblio-campos-ref1 now -all tell=$TELL
%CHECK_ERROR%

# Consultamos la base map para reasignar punteros en la base bibliográfica.
echo Reasignando el valor de los subcampos $0...
mx $WORK/biblio-campos-ref1 proc=@update-subfield-0.pft create=$WORK/biblio-campos-ref2 now -all tell=$TELL
%CHECK_ERROR%

# Regeneramos la base bibliográfica.
echo Regenerando la base bibliografica...
mx $WORK/biblio-campos-ref2 lw=$LW "pft=v1/" now -all tell=$TELL >$WORK/biblio-campos-ref2.id
id2i $WORK/biblio-campos-ref2.id create=$OUTPUT/biblio-ref

# TO-DO: ¿cómo indizamos los registros de la nueva base biblio?
# La respuesta, como siempre, es: "depende". Depende de qué búsquedas queremos poder hacer.

# Para probar el funcionamiento de los links entre la base bibliográfica y la base
# de autoridades, se puede usar esto, que presenta los títulos (245) junto con
# los puntos de acceso 100 y 700 asociados (aunque sin añadir puntuación): mx output/biblio-ref "pft=@test-ref.pft"

echo.
echo --------------------------------------------------
echo Y esto ha sido todo. Vea el directorio $OUTPUT.
echo --------------------------------------------------

goto END


:ERROR
echo.
echo ------------------------------------------------------------------
echo    *** ATENCION ***
echo    Se produjo un error.
echo ------------------------------------------------------------------
echo.
goto END

:ERROR_DELIM
echo.
echo ------------------------------------------------------------------
echo    *** ATENCION ***
echo    El delimitador elegido '$SEQ_DELIM' ya está presente en la base.
echo    Cambie el valor de SEQ_DELIM.
echo ------------------------------------------------------------------
echo.
goto END

:ERROR_MKDIR
echo.
echo ------------------------------------------------------------------
echo    *** ATENCION ***
echo    No se pudo crear un directorio.
echo    Nota: bajo Windows 2000 a veces se genera este error, sin razon
echo    aparente; en tal caso, reintente. Si el directorio ya existe,
echo    eliminelo y reintente.
echo ------------------------------------------------------------------
echo.
goto END

:END
if $CLEAN==1 rm -f $WORK/*.*
cipar=
