# ===========================================================================
# default-settings.conf - Par�metros de configuraci�n predeterminados.
#
# ATENCION: Para facilitar futuras actualizaciones de OPACMARC,
# no modifique este archivo. Si desea cambiar esta configuraci�n
# predeterminada, utilice el archivo local-settings.conf.
# ===========================================================================


# DEBUG: '1' para generar informaci�n �til en la depuraci�n de errores.
# ATENCION: Para el OPAC en producci�n, siempre usar DEBUG=0.
DEBUG=0


# -------------------------------------------------------
#  PATHS
# -------------------------------------------------------

# SCRIPT_URL: la URL de wxis (relativa a la ra�z del servidor).
# TO-DO: abandonar este par�metro y usar en cambio getenv('SCRIPT_NAME')
SCRIPT_URL=/cgi-bin/__WXIS__

# PATH_HTDOCS: prefijo para las URLs de im�genes, scripts, estilos.
# Si instala OPACMARC en la ra�z del servidor, el valor ser� "/" (sin las comillas).
PATH_HTDOCS=/
  
# PATH_TEMP: directorio para archivos temporales. Necesita permiso de escritura
# para el usuario del servidor web (e.g. www-data en Ubuntu).
PATH_TEMP=__TEMP_DIR__

# PATH_AGREP: ubicaci�n del ejecutable agrep
PATH_AGREP=__OPACMARC_DIR__/bin/agrep

 
# -------------------------------------------------------
#  VISUALIZACIONES
# -------------------------------------------------------

# MAIN_ENTRY_TOP: mostramos el encabezamiento principal (campo 1xx) en la parte superior de la ficha?
MAIN_ENTRY_TOP=false

# DEFAULT_RECORD_STYLE: estilo por defecto para los registros bibliogr�ficos: {Modular|Ficha|MARC}
DEFAULT_RECORD_STYLE=Modular

# DISPLAY_DOC_TYPE: mostrar el tipo de documento (para estilos Breve y Modular)
# En cat�logos con un �nico tipo de material, e.g. libros, no ser�a
# necesario presentar esta informaci�n.
# Escribir la lista de bases donde se desea aplicar esta opci�n, e.g. DISPLAY_DOC_TYPE=baseA~baseB
#DISPLAY_DOC_TYPE=

# SHOW_EXTERNAL_LINKS: Generaci�n de enlaces a sitios externos (amazon.com, etc.).
SHOW_EXTERNAL_LINKS=1

# ETIQ_773_MODE: pruebas con el campo 773 en el estilo Etiquetado {label|header}
ETIQ_773_MODE=header



# --------------------------------------------------
# Display de la lista de resultados (estilo Breve)
# --------------------------------------------------

# TEXT_INDENT: uso de TEXT-INDENT (sangr�a negativa en la 1ra l�nea)
# TO-DO: posiblemente esta opci�n no tenga sentido; creo que podemos usar
# siempre el valor TEXT_INDENT=1
TEXT_INDENT=1

# COMPACT_RESULT_LIST: compactaci�n de resultados
# En una ordenaci�n de resultados por main entry, permite que cada main entry heading
# se visualice s�lo una vez
COMPACT_RESULT_LIST=1

# DISPLAY_LOCATION: habilita la columna para mostrar la ubicaci�n del documento
DISPLAY_LOCATION=1

# SHOW_245h: display de DGM (245$h)
SHOW_245h=0

# SHOW_245c: display del subcampo 245$c (menci�n de responsabilidad)
SHOW_245c=1


# --------------------------------------------------
# Varios
# --------------------------------------------------

# ADMIN_EMAIL: direcci�n electr�nica del administrador del OPAC
#ADMIN_EMAIL=user@domain

# RECORD_STYLE_CONTROL: controles para cambiar de estilo en la visualizaci�n de un
# registro bibliogr�fico: {text|select|button}
RECORD_STYLE_CONTROL=text

# MAX_HITS_BIB: n�mero m�ximo de resultados procesados en una b�squeda
MAX_HITS_BIB=250

# DEFAULT_RECORDS_PER_PAGE: cantidad de registros bibliogr�ficos por p�gina
BIB_RECORDS_PER_PAGE=20

# DEFAULT_HEADINGS_PER_PAGE: cantidad de headings por p�gina
HEADINGS_PER_PAGE=20

# AGREP_MAX_SUG: cantidad m�xima de sugerencias (coincidencias aproximadas) que se aceptan del AGREP
AGREP_MAX_SUG=6

# AGREP_AUTO_SEARCH: con valor '1' se habilita la b�squeda autom�tica en el caso en que
# agrep genere una �nica coincidencia aproximada.
AGREP_AUTO_SEARCH=0

# SHOW_SUGGESTIONS: generaci�n de sugerencias en b�squedas por headings
# e.g. "Hay tambi�n obras acerca de Fulano (2 resultados)"
SHOW_SUGGESTIONS=1

# FORM_STYLE: estilo de los formularios en la p�gina de acceso. Opciones: 1|2
# TO-DO: implementar esta opci�n.
FORM_STYLE=

# CALL_NUMBER_BROWSE: permite recorrer el cat�logo en orden de signatura topogr�fica
CALL_NUMBER_BROWSE=1

# EMAIL_RECORDS: presenta el formulario para poder enviar resultados por email
# ATENCION: no est� completamente implementado
EMAIL_RECORDS=0

# USE_MSC: usar la Mathematics Subject Classification para b�squedas tem�ticas.
#USE_MSC=1

# SHOW_RECORD_ID: mostrar datos de identificaci�n del registro (campos 001, 005)
# en el estilo Modular.
SHOW_RECORD_ID=1

# SHOW_INV: mostrar el nro. de inventario (junto a la signatura topogr�fica)
#SHOW_INV=1

# GOOGLE_BOOK_PREVIEW: permite interactuar con la API de Google Book Search
#GOOGLE_BOOK_PREVIEW=1

  
# --------------------------------------------------
# Textos y mensajes
# (Esto fue apenas un ensayo; necesitamos manejar todos los mensajes desde un
# archivo de configuraci�n espec�fico, o bien desde una base de datos).
# --------------------------------------------------

# Formularios de b�squeda
KEYWORD_SEARCH=Buscar por palabras
INDEX_BROWSE=Explorar �ndices alfab�ticos
#ACCESO�A�LOS�INDICES

# Botones, enlaces
PREV_RECORDS=Registros anteriores
NEXT_RECORDS=Registros siguientes
NEW_SEARCH=Nueva b�squeda
AVAILABLE_IN=Consultar en
SEND_MAIL=Enviar
