#############################################################################
#
# Parámetros de configuración predeterminados.
#
# ATENCION: NO MODIFIQUE ESTE ARCHIVO.
#
# Si desea alterar localmente los valores que aparecen en la configuración
# predeterminada, utilice alguno de estos archivos:
#
#     - local-settings.conf: para cambios que afecten a todas las bases
#     - db-settings.conf: para cambios que sólo afecten a una base
#
#############################################################################


# DEBUG: use 'DEBUG=1' para generar información de utilidad para la depuración
# de errores.
# ATENCION: Para el OPAC en producción, use siempre 'DEBUG=0'.
DEBUG=0


# -------------------------------------------------------
#  PATHS
# -------------------------------------------------------

# SCRIPT_URL: la URL de wxis (relativa a la raíz del servidor).
# TO-DO: abandonar este parámetro y usar en cambio getenv('SCRIPT_NAME')
SCRIPT_URL=/cgi-bin/__WXIS__

# PATH_HTDOCS: prefijo para las URLs de imágenes, scripts, estilos.
# Si instala OPACMARC en la raíz del servidor, el valor será "/" (sin las comillas).
PATH_HTDOCS=/
  
# PATH_TEMP: directorio para archivos temporales. Necesita permiso de escritura
# para el usuario del servidor web (e.g. www-data en Ubuntu).
PATH_TEMP=__TEMP_DIR__

# PATH_AGREP: ubicación del ejecutable agrep
PATH_AGREP=__APP_DIR__/bin/agrep

 
# -------------------------------------------------------
#  VISUALIZACIONES
# -------------------------------------------------------

# MAIN_ENTRY_TOP: mostramos el encabezamiento principal (campo 1xx) en la parte superior de la ficha?
MAIN_ENTRY_TOP=false

# DEFAULT_RECORD_STYLE: estilo por defecto para los registros bibliográficos: {Modular|Ficha|MARC}
DEFAULT_RECORD_STYLE=Modular

# DISPLAY_DOC_TYPE: mostrar el tipo de documento (para estilos Breve y Modular)
# En catálogos con un único tipo de material, e.g. libros, no sería
# necesario presentar esta información.
# Escribir la lista de bases donde se desea aplicar esta opción, e.g. DISPLAY_DOC_TYPE=baseA~baseB
#DISPLAY_DOC_TYPE=

# SHOW_EXTERNAL_LINKS: Generación de enlaces a sitios externos (amazon.com, etc.).
SHOW_EXTERNAL_LINKS=1

# ETIQ_773_MODE: pruebas con el campo 773 en el estilo Etiquetado {label|header}
ETIQ_773_MODE=header



# --------------------------------------------------
# Display de la lista de resultados (estilo Breve)
# --------------------------------------------------

# TEXT_INDENT: uso de TEXT-INDENT (sangría negativa en la 1ra línea)
# TO-DO: posiblemente esta opción no tenga sentido; creo que podemos usar
# siempre el valor TEXT_INDENT=1
TEXT_INDENT=1

# COMPACT_RESULT_LIST: compactación de resultados
# En una ordenación de resultados por main entry, permite que cada main entry heading
# se visualice sólo una vez
COMPACT_RESULT_LIST=1

# DISPLAY_LOCATION: habilita la columna para mostrar la ubicación del documento
DISPLAY_LOCATION=1

# SHOW_245h: display de DGM (245$h)
SHOW_245h=0

# SHOW_245c: display del subcampo 245$c (mención de responsabilidad)
SHOW_245c=1


# --------------------------------------------------
# Varios
# --------------------------------------------------

# ADMIN_EMAIL: dirección electrónica del administrador del OPAC
#ADMIN_EMAIL=user@domain

# RECORD_STYLE_CONTROL: controles para cambiar de estilo en la visualización de un
# registro bibliográfico: {text|select|button}
RECORD_STYLE_CONTROL=text

# MAX_HITS_BIB: número máximo de resultados procesados en una búsqueda
MAX_HITS_BIB=250

# DEFAULT_RECORDS_PER_PAGE: cantidad de registros bibliográficos por página
BIB_RECORDS_PER_PAGE=20

# DEFAULT_HEADINGS_PER_PAGE: cantidad de headings por página
HEADINGS_PER_PAGE=20

# AGREP_MAX_SUG: cantidad máxima de sugerencias (coincidencias aproximadas) que se aceptan del AGREP
AGREP_MAX_SUG=6

# AGREP_AUTO_SEARCH: con valor '1' se habilita la búsqueda automática en el caso en que
# agrep genere una única coincidencia aproximada.
AGREP_AUTO_SEARCH=0

# SHOW_SUGGESTIONS: generación de sugerencias en búsquedas por headings
# e.g. "Hay también obras acerca de Fulano (2 resultados)"
SHOW_SUGGESTIONS=1

# FORM_STYLE: estilo de los formularios en la página de acceso. Opciones: 1|2
# TO-DO: implementar esta opción.
FORM_STYLE=

# CALL_NUMBER_BROWSE: permite recorrer el catálogo en orden de signatura topográfica
CALL_NUMBER_BROWSE=1

# EMAIL_RECORDS: presenta el formulario para poder enviar resultados por email
# ATENCION: no está completamente implementado
EMAIL_RECORDS=0

# USE_MSC: usar la Mathematics Subject Classification para búsquedas temáticas.
#USE_MSC=1

# SHOW_RECORD_ID: mostrar datos de identificación del registro (campos 001, 005)
# en el estilo Modular.
SHOW_RECORD_ID=1

# SHOW_INV: mostrar el nro. de inventario (junto a la signatura topográfica)
#SHOW_INV=1

# GOOGLE_BOOK_PREVIEW: permite interactuar con la API de Google Book Search
#GOOGLE_BOOK_PREVIEW=1

  
# --------------------------------------------------
# Textos y mensajes
# (Esto fue apenas un ensayo; necesitamos manejar todos los mensajes desde un
# archivo de configuración específico, o bien desde una base de datos).
# --------------------------------------------------

# Formularios de búsqueda
KEYWORD_SEARCH=Buscar por palabras
INDEX_BROWSE=Explorar índices alfabéticos
#ACCESO A LOS INDICES

# Botones, enlaces
PREV_RECORDS=Registros anteriores
NEXT_RECORDS=Registros siguientes
NEW_SEARCH=Nueva búsqueda
AVAILABLE_IN=Consultar en
SEND_MAIL=Enviar
