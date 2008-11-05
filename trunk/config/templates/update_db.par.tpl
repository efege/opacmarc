#############################################################################
#
# Archivo cipar para update_db.py.
#
# Este archivo es concatenado con default-cipar.par para que update_db.py
# tenga acceso a otros parámetros de uso común. 
#
# ATENCION - NO MODIFIQUE ESTE ARCHIVO
#
#############################################################################


# BASES
DELIMSUBCAMPO.*=__APP_DIR__/bin/update_db/delimsubcampo.*
LANG.*=__APP_DIR__/bin/update_db/lang.*
MSC.*=__APP_DIR__/util/msc2000/msc2000.*

# --------------------------------------------------------------------------
# Nota: OEM2ANSI sólo se requiere si la base a procesar proviene de MS-DOS.
# --------------------------------------------------------------------------
OEM2ANSI.*=__APP_DIR__/bin/update_db/oem2ansi.*

LANG.SEQ=__APP_DIR__/bin/update_db/lang.seq

# FST
HEADINGS.FST=__APP_DIR__/bin/update_db/headings.fst
LANG.FST=__APP_DIR__/bin/update_db/lang.fst

# PFT
BLANCOS.PFT=__APP_DIR__/bin/update_db/blancos.pft
ELIMDUP2.PFT=__APP_DIR__/bin/update_db/elimdup2.pft
HEAD.PFT=__APP_DIR__/bin/update_db/head.pft
LIST-HEADING-IDS.PFT=__APP_DIR__/bin/update_db/list-heading-ids.pft
LIST-SUBCATS.PFT=__APP_DIR__/bin/update_db/list-subcats.pft
LOCATION_SORT.PFT=__APP_DIR__/bin/update_db/location_sort.pft
NAME.PFT=__APP_DIR__/bin/update_db/name.pft
RECODE.PFT=__APP_DIR__/bin/update_db/recode.pft
REGPUNT.PFT=__APP_DIR__/bin/update_db/regpunt.pft
SECS2MARC.PROC=__APP_DIR__/bin/update_db/secs2marc.proc
SUBJ.PFT=__APP_DIR__/bin/update_db/subj.pft
TITLE.PFT=__APP_DIR__/bin/update_db/title.pft
