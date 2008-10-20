# coding=latin-1

# ------------------------------------------------------------------
# CONFIGURACION para update_db.py
# ------------------------------------------------------------------

# Using module ConfigParser, a section header is mandatory
[Global]

# ------------------------------------------------------------------
# Paths
# ------------------------------------------------------------------

# Ubicaci�n de mx y dem�s utilitarios
PATH_CISIS = __APP_DIR__/bin/cisis

# En este directorio est�n almacenadas las im�genes de las tapas (si las hay).
# ATENCION: no incluir al final de la ruta el directorio con el nombre de la base.
DIR_IMG = __LOCAL_DATA_DIR__/bases/__DB__/htdocs/img/

# A este directorio van a parar los archivos generados (si se usa MOVE=1).
# ATENCION: no incluir al final de la ruta el directorio con el nombre de la base.
TARGET_DIR = __LOCAL_DATA_DIR__/bases/__DB__/db/public/

# ------------------------------------------------------------------
# Opciones
# ------------------------------------------------------------------

# Procesar im�genes asociadas a registros bibliogr�ficos
IMAGES=1

# Tomar registros bibliogr�ficos de publicaciones seriadas de SeCS - OBSOLETO
#SECS=0

# Use MOVE=1 para mover los archivos generados al directorio destino (TARGET_DIR).
MOVE=1

# Use CLEAN=1 para eliminar archivos temporales creados durante la actualizaci�n del OPAC.
CLEAN=0


# ------------------------------------------------------------------
# En la mayor�a de las situaciones, las opciones que siguen
# pueden dejarse tal como est�n
# ------------------------------------------------------------------

# Valor del par�metro tell del mx
TELL = 5000

# Lista de tags de los cuales vamos a extraer los encabezamientos.
# subject headings
SUBJ_TAGS = v600v610v611v630v650v651v653v655v656
# name headings
NAME_TAGS = v100v110v111v700v710v711

# Lista de campos que se incluyen en la base title.
# ATENCION: completar/revisar. Ver title.pft.
# Faltarian: subcampos $t de campos 505 y 7xx; campos de relaci�n: 76x-78x
TITLE_TAGS = v130v240v245v246v730v740v765v773v440v830

# Valores del 2do indicador que no deseamos considerar en campos 6xx
IGNORE_SUBJ_HEADINGS = #6
