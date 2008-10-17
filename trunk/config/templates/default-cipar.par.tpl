##########################################
#  ATENCION - NO MODIFIQUE ESTE ARCHIVO  #
##########################################

# -----------------------------------------------------------------
# BASES (common)
# -----------------------------------------------------------------
BIBLIO.FST=__OPACMARC_DIR__/util/biblio.fst
BIBLIO.STW=__OPACMARC_DIR__/util/biblio.stw
COUNTRY.*=__OPACMARC_DIR__/util/country.*
DICTGIZ.*=__OPACMARC_DIR__/util/dictgiz.*
HEADSORT.PFT=__OPACMARC_DIR__/util/headsort.pft
LANG.*=__OPACMARC_DIR__/util/lang.*
SELSUBJ.PFT=__OPACMARC_DIR__/util/selsubj.pft
SELNAME.PFT=__OPACMARC_DIR__/util/selname.pft
SELTITLE.PFT=__OPACMARC_DIR__/util/seltitle.pft

ACTAB=__OPACMARC_DIR__/util/ac-ansi.tab
UCTAB=__OPACMARC_DIR__/util/uc-ansi.tab

MSC.*=__OPACMARC_DIR__/util/msc2000/msc2000.*

# -----------------------------------------------------------------
# HTMLPFT
# -----------------------------------------------------------------
BIB-LIST-HEAD.HTM=__OPACMARC_DIR__/cgi-bin/html/bib-list-head.htm
BIB-NAV.HTM=__OPACMARC_DIR__/cgi-bin/html/bib-nav.htm
BIB-RECORD-1.HTM=__OPACMARC_DIR__/cgi-bin/html/bib-record-1.htm
BIB-RECORD-2.HTM=__OPACMARC_DIR__/cgi-bin/html/bib-record-2.htm
BIB-RECORD-3.HTM=__OPACMARC_DIR__/cgi-bin/html/bib-record-3.htm
BROWSE-CATALOG-NAV.HTM=__OPACMARC_DIR__/cgi-bin/html/browse-catalog-nav.htm
COMPLETO.HTM=__OPACMARC_DIR__/cgi-bin/html/complete.htm
CONTROL-FORM.HTM=__OPACMARC_DIR__/cgi-bin/control-form.htm
FEEDBACK_REPLY.HTM=__OPACMARC_DIR__/cgi-bin/html/feedback-reply.htm
FEEDBACK_FORM.HTM=__OPACMARC_DIR__/cgi-bin/html/feedback-form.htm
FORM-SIMPLE.HTM=__OPACMARC_DIR__/cgi-bin/html/form-simple.htm
FORM_ADVANCED.HTM=__OPACMARC_DIR__/cgi-bin/html/form-advanced.htm
HEADING-BROWSE-MIDDLE.HTM=__OPACMARC_DIR__/cgi-bin/html/heading-browse-middle.htm
HEADING-BROWSE-NAV.HTM=__OPACMARC_DIR__/cgi-bin/html/heading-browse-nav.htm
HEADING-BROWSE-TOP.HTM=__OPACMARC_DIR__/cgi-bin/html/heading-browse-top.htm
H-SEARCH-BOTTOM.HTM=__OPACMARC_DIR__/cgi-bin/html/h-search-bottom.htm
H-SEARCH-TOP-1.HTM=__OPACMARC_DIR__/cgi-bin/html/h-search-top-1.htm
H-SEARCH-TOP-2.HTM=__OPACMARC_DIR__/cgi-bin/html/h-search-top-2.htm
MAIL-RESULTS.HTM=__OPACMARC_DIR__/cgi-bin/html/mail.htm
NOVEDAD.HTM=__OPACMARC_DIR__/cgi-bin/html/novedad.htm
PAGE-END.HTM=__OPACMARC_DIR__/cgi-bin/html/page-end.htm
PAGE-BEGIN.HTM=__OPACMARC_DIR__/cgi-bin/html/page-begin.htm
SAMPLE-RECORD.TXT=__OPACMARC_DIR__/cgi-bin/sample-record.txt
SORTED-BY.HTM=__OPACMARC_DIR__/cgi-bin/html/sorted-by.htm
ABOUT-MSC.HTM=__OPACMARC_DIR__/cgi-bin/html/about-msc.htm

# -----------------------------------------------------------------
# PFT
# -----------------------------------------------------------------
AACR2.PFT=__OPACMARC_DIR__/cgi-bin/pft/aacr2.pft
CITA.PFT=__OPACMARC_DIR__/cgi-bin/pft/cita.pft
CLEAN-HEADING.PFT=__OPACMARC_DIR__/cgi-bin/pft/clean-heading.pft
COMPACT-DATES.PFT=__OPACMARC_DIR__/cgi-bin/pft/compact-dates.pft
DICTGIZ.PFT=__OPACMARC_DIR__/cgi-bin/pft/dictgiz.pft
HEADINGS.PFT=__OPACMARC_DIR__/cgi-bin/pft/headings.pft
MAIL.PFT=__OPACMARC_DIR__/cgi-bin/pft/mail.pft
MSC.PFT=__OPACMARC_DIR__/cgi-bin/pft/msc.pft

# -----------------------------------------------------------------
# PFT (compartidos con Catalis)
# -----------------------------------------------------------------
BIB_SORT_KEY.PFT=__OPACMARC_DIR__/cgi-bin/pft/bib-sort-key.pft
DOCUMENT-TYPE.PFT=__OPACMARC_DIR__/cgi-bin/pft/doc-type.pft
ETIQUETADO.PFT=__OPACMARC_DIR__/cgi-bin/pft/etiquetado.pft
URLENCODE.PFT=__OPACMARC_DIR__/cgi-bin/pft/urlencode.pft
WORK_HEADING.PFT=__OPACMARC_DIR__/cgi-bin/pft/wh.pft

# -----------------------------------------------------------------
# Directorio para archivos temporales (ignorado en Linux!)
# -----------------------------------------------------------------
CI_TEMPDIR=__TEMP_DIR__



# Todo lo que sigue depende de la consulta que est� siendo procesada

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
#DB-PRESENTATION.HTM=__LOCAL_DATA_DIR__/bases/__DB__/cgi-bin/html/db-present.htm

# -----------------------------------------------------------------
# Archivo de logs, uno por fecha
# -----------------------------------------------------------------
LOGFILE.TXT=__LOCAL_DATA_DIR__/logs/log-__DATE__.txt