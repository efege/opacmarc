#############################################################################
#
# Archivo cipar predeterminado.
#
# ATENCION - NO MODIFIQUE ESTE ARCHIVO
#
# Si necesita sobrescribir alguno de estos parámetros, o agregar nuevos,
# hágalo desde estos archivos:
#     - local-cipar.par: para cambios que afecten a todas las bases
#     - db-cipar.par: para cambios que sólo afecten a una base
#
#############################################################################

# -----------------------------------------------------------------
# BASES
# -----------------------------------------------------------------
BIBLIO.FST=__APP_DIR__/util/biblio.fst
BIBLIO.STW=__APP_DIR__/util/biblio.stw
COUNTRY.*=__APP_DIR__/util/country.*
DICTGIZ.*=__APP_DIR__/util/dictgiz.*
REMOVE-CHARS.*=__APP_DIR__/util/gizmo-remove-chars.*
HEADSORT.PFT=__APP_DIR__/util/headsort.pft
LANG.*=__APP_DIR__/util/lang.*
SELSUBJ.PFT=__APP_DIR__/util/selsubj.pft
SELNAME.PFT=__APP_DIR__/util/selname.pft
SELTITLE.PFT=__APP_DIR__/util/seltitle.pft

AC-ANSI.TAB=__APP_DIR__/util/ac-ansi.tab
UC-ANSI.TAB=__APP_DIR__/util/uc-ansi.tab

MSC.*=__APP_DIR__/util/msc2000/msc2000.*

# -----------------------------------------------------------------
# HTMLPFT
# -----------------------------------------------------------------
BIB-LIST-HEAD.HTM=__APP_DIR__/cgi-bin/html/bib-list-head.htm
BIB-NAV.HTM=__APP_DIR__/cgi-bin/html/bib-nav.htm
BIB-RECORD-1.HTM=__APP_DIR__/cgi-bin/html/bib-record-1.htm
BIB-RECORD-2.HTM=__APP_DIR__/cgi-bin/html/bib-record-2.htm
BIB-RECORD-3.HTM=__APP_DIR__/cgi-bin/html/bib-record-3.htm
BROWSE-CATALOG-NAV.HTM=__APP_DIR__/cgi-bin/html/browse-catalog-nav.htm
COMPLETO.HTM=__APP_DIR__/cgi-bin/html/complete.htm
CONTROL-FORM.HTM=__APP_DIR__/cgi-bin/control-form.htm
FEEDBACK_REPLY.HTM=__APP_DIR__/cgi-bin/html/feedback-reply.htm
FEEDBACK_FORM.HTM=__APP_DIR__/cgi-bin/html/feedback-form.htm
FORM-SIMPLE.HTM=__APP_DIR__/cgi-bin/html/form-simple.htm
FORM_ADVANCED.HTM=__APP_DIR__/cgi-bin/html/form-advanced.htm
HEADING-BROWSE-MIDDLE.HTM=__APP_DIR__/cgi-bin/html/heading-browse-middle.htm
HEADING-BROWSE-NAV.HTM=__APP_DIR__/cgi-bin/html/heading-browse-nav.htm
HEADING-BROWSE-TOP.HTM=__APP_DIR__/cgi-bin/html/heading-browse-top.htm
H-SEARCH-BOTTOM.HTM=__APP_DIR__/cgi-bin/html/h-search-bottom.htm
H-SEARCH-TOP-1.HTM=__APP_DIR__/cgi-bin/html/h-search-top-1.htm
H-SEARCH-TOP-2.HTM=__APP_DIR__/cgi-bin/html/h-search-top-2.htm
MAIL-RESULTS.HTM=__APP_DIR__/cgi-bin/html/mail.htm
NOVEDAD.HTM=__APP_DIR__/cgi-bin/html/novedad.htm
PAGE-END.HTM=__APP_DIR__/cgi-bin/html/page-end.htm
PAGE-BEGIN.HTM=__APP_DIR__/cgi-bin/html/page-begin.htm
SAMPLE-RECORD.TXT=__APP_DIR__/cgi-bin/sample-record.txt
SORTED-BY.HTM=__APP_DIR__/cgi-bin/html/sorted-by.htm
ABOUT-MSC.HTM=__APP_DIR__/cgi-bin/html/about-msc.htm

# -----------------------------------------------------------------
# PFT
# -----------------------------------------------------------------
AACR2.PFT=__APP_DIR__/cgi-bin/pft/aacr2.pft
CITA.PFT=__APP_DIR__/cgi-bin/pft/cita.pft
CLEAN-HEADING.PFT=__APP_DIR__/cgi-bin/pft/clean-heading.pft
COMPACT-DATES.PFT=__APP_DIR__/cgi-bin/pft/compact-dates.pft
DICTGIZ.PFT=__APP_DIR__/cgi-bin/pft/dictgiz.pft
HEADINGS.PFT=__APP_DIR__/cgi-bin/pft/headings.pft
MAIL.PFT=__APP_DIR__/cgi-bin/pft/mail.pft
MSC.PFT=__APP_DIR__/cgi-bin/pft/msc.pft

BIB_SORT_KEY.PFT=__APP_DIR__/cgi-bin/pft/bib-sort-key.pft
DOCUMENT-TYPE.PFT=__APP_DIR__/cgi-bin/pft/doc-type.pft
ETIQUETADO.PFT=__APP_DIR__/cgi-bin/pft/etiquetado.pft
URLENCODE.PFT=__APP_DIR__/cgi-bin/pft/urlencode.pft
WORK_HEADING.PFT=__APP_DIR__/cgi-bin/pft/wh.pft

# -----------------------------------------------------------------
# Directorio para archivos temporales (ignorado en Linux!)
# -----------------------------------------------------------------
CI_TEMPDIR=__TEMP_DIR__



# Todo lo que sigue depende de la petición que está siendo procesada por
# el servidor.

# -----------------------------------------------------------------
# BASES
# -----------------------------------------------------------------
BASES.PAR=__LOCAL_DATA_DIR__/bases/__DB__/db/public/bases.txt
BIB_CODES.TXT=__LOCAL_DATA_DIR__/bases/__DB__/db/public/bibcode.txt
BIBLIO.*=__LOCAL_DATA_DIR__/bases/__DB__/db/public/biblio.*
DATES.TXT=__LOCAL_DATA_DIR__/bases/__DB__/db/public/dates.txt
LANG_CODES.TXT=__LOCAL_DATA_DIR__/bases/__DB__/db/public/langcode.txt
LIT_CODES.TXT=__LOCAL_DATA_DIR__/bases/__DB__/db/public/litcode.txt
MAP_859b.*=__LOCAL_DATA_DIR__/bases/__DB__/db/public/map_859b.*
NAME.*=__LOCAL_DATA_DIR__/bases/__DB__/db/public/name.*
NOVEDADES.TXT=__LOCAL_DATA_DIR__/bases/__DB__/db/public/novedades.txt
SUBJ.*=__LOCAL_DATA_DIR__/bases/__DB__/db/public/subj.*
TITLE.*=__LOCAL_DATA_DIR__/bases/__DB__/db/public/title.*
UPDATED.TXT=__LOCAL_DATA_DIR__/bases/__DB__/db/public/updated.txt

# -----------------------------------------------------------------
# HTMLPFT
# -----------------------------------------------------------------
DB-ABOUT.HTM=__LOCAL_DATA_DIR__/bases/__DB__/cgi-bin/html/db-about.htm
DB-EXTRA.HTM=__LOCAL_DATA_DIR__/bases/__DB__/cgi-bin/html/db-extra.htm
DB-FOOTER.HTM=__LOCAL_DATA_DIR__/bases/__DB__/cgi-bin/html/db-footer.htm
DB-HEADER.HTM=__LOCAL_DATA_DIR__/bases/__DB__/cgi-bin/html/db-header.htm

# -----------------------------------------------------------------
# Archivo de logs, uno por fecha
# -----------------------------------------------------------------
LOGFILE.TXT=__LOCAL_DATA_DIR__/logs/opac/log-__DATE__.txt
