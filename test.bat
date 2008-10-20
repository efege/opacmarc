@echo off
:: Script para testear opacmarc en Windows
:: Creado: FG, 2008-10-06

:: Este script me resulta útil para testear la aplicación a partir de una
:: working copy local. Para usarlo en otro contexto, habría que ajustar
:: los parámetros de configuración y tal vez algún otro detalle.

:: Leemos parámetros locales de un archivo externo (test-config.bat).
:: Esta es la lista de parámetros esperados; los valores mostrados son
:: sólo ejemplos:
::
:: versión de utilitarios cisis + wxis
:: set CISIS_VERSION=5.2b-1030
::
:: Directorio para el test. Es eliminado con cada nuevo test.
:: set TEST_DIR=G:\opacmarc-test
::
:: directorio de los cisis
:: set CISIS_DIR=G:\programas\cisis-%CISIS_VERSION%
::
:: wxis
:: set WXIS=G:\svn\opacmarc\cgi-bin\wxis-%CISIS_VERSION%.exe
::
:: agrep
:: set AGREP=G:\svn\opacmarc\bin\agrep.exe
::
:: Archivo con la configuración de un virtual host para OpacMarc
:: set APACHE_VHOST=G:\programas\Apache Software Foundation\Apache2.2\conf\extra\httpd-vhost-opacmarc-test-8081.conf
call test-config.bat

:: eliminamos el directorio si ya existe
rmdir /s /q %TEST_DIR% 2>NUL

mkdir %TEST_DIR%

set APP_DIR=%TEST_DIR%\app

:: obtenemos una copia fresca del código
echo.
svn export G:\svn\opacmarc %APP_DIR%

:: colocamos los binarios en su lugar
echo.
mkdir %APP_DIR%\bin\cisis
copy %CISIS_DIR%\*.* %APP_DIR%\bin\cisis\
copy %WXIS%          %APP_DIR%\cgi-bin\wxis.exe
copy %AGREP%         %APP_DIR%\bin\agrep.exe

:: ejecutamos script de inicialización
python %APP_DIR%\bin\install.py

:: pisamos configuración de Apache
copy "%APP_DIR%\config\httpd-opacmarc.conf" "%APACHE_VHOST%"

:: procesamos la base demo
python %APP_DIR%\bin\demo.py

:: reiniciamos Apache (no me funciona)
::G:
::cd \programas\Apache Software Foundation\Apache2.2\bin\
::httpd
::cd \

::echo Reinicie Apache, y luego...
::pause

:: visitamos el opac
start firefox "http://127.0.0.1:8081/cgi-bin/wxis.exe?IsisScript=xis/opac.xis&db=demo"
