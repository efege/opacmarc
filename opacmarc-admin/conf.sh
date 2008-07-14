# ------------------------------------------------------------------
# CONFIGURACION para update-opac.sh
# ------------------------------------------------------------------

# Ubicación de mx y demás utilitarios
export PATH=$PATH:/home/fer/bin/cisis

# En este directorio se encuentran los archivos necesarios para generar el OPAC
# contiene los directorios bin, common, opac, work
OPACMARC_DIR=/home/fer/opacmarc-admin

# En este directorio están almacenadas las imágenes de las tapas (si las hay)
DIR_IMG=/home/fer/www/html/catalis_pack_devel/opac/img/$DB_NAME

# A este directorio van a parar los archivos generados (si se usa MOVE=1)
TARGET_DIR=/home/fer/www/bases/catalis_pack_devel/opac/$DB_NAME

# Use MOVE=1 para mover los archivos generados al directorio destino ($TARGET_DIR)
MOVE=0

# Use CLEAN=1 para eliminar archivos temporales creados durante la generación del OPAC
CLEAN=0

# Use CONVERT_WINDOWS=1 si desea usar en un servidor Windows las bases generadas
CONVERT_WINDOWS=0


# ------------------------------------------------------------------
# En la mayoría de las situaciones, las opciones que siguen
# pueden dejarse tal como están
# ------------------------------------------------------------------

# Valor del parametro tell del mx
TELL=5000

# Lista de tags de los cuales vamos a extraer los encabezamientos
export SUBJ_TAGS='v600v610v611v630v650v651v653v655v656'  # subject headings
export NAME_TAGS='v100v110v111v700v710v711'              # name headings

# Lista de campos que se incluyen en la base title.
# ATENCION: completar/revisar. Ver title.pft.
# Faltarian: subcampos $t de campos 505 y 7xx; campos de relación: 76x-78x
export TITLE_TAGS=v130v240v245v246v730v740v765v773v440v830

# Valores del 2do indicador que no deseamos considerar en campos 6xx
export IGNORE_SUBJ_HEADINGS='#6'
