# Script de instalación para OpacMarc
# Issue 10: http://code.google.com/p/opacmarc/issues/detail?id=10

'''
  - Crear las bases isis auxiliares a partir de archivos de texto (.id), para favorecer la portabilidad
  
    bases/common/{country,lang,dictgiz}
    
    id2i bases/common/country.id create=bases/common/country 
    id2i bases/common/lang.id create=bases/common/lang
    id2i bases/common/dictgiz.id create=bases/common/dictgiz
    
    opacmarc-admin/work/demo/biblio
    
    id2i opacmarc-admin/work/demo/biblio.id create=opacmarc-admin/work/demo/biblio

  - Generar los invertidos correspondientes
  
    mx bases/common/country "fst=@" fullinv=bases/common/country
    mx bases/common/lang "fst=@" fullinv=bases/common/lang
    mx bases/common/dictgiz "fst=@" fullinv=bases/common/dictgiz

  - Ajustar los paths en los archivos de configuración

  - Generar un identificador de la versión (svnversion) para insertarlo en opac-footer.htm

  - Ejecutar update-opac.py para la base de prueba
  
  - Realizar tests? E.g. búsquedas con acentos y agrep.

  - Mostrar mensajes útiles para el usuario (tips, tareas que debe realizar luego de instalar)
  
  - En Windows crear directorio temp para búsquedas de wxis, y ajustar config.
'''