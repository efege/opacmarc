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
:: Directorio que almacena la working copy de svn
::set SVN_DIR=G:\opacmarc\svn
::
:: Directorio para el test. Es eliminado con cada nuevo test.
::set TEST_DIR=G:\opacmarc\test
::
:: versión de cisis/wxis
::set CISIS_VERSION=5.2b-1660
::
:: directorio de los cisis
::set CISIS_DIR=G:\opacmarc\binaries\windows\cisis-%CISIS_VERSION%
::
:: wxis
::set WXIS=G:\opacmarc\binaries\windows\wxis-%CISIS_VERSION%.exe
::
:: agrep
::set AGREP=G:\opacmarc\binaries\windows\agrep.exe
::
:: Archivo con la configuración de un virtual host para OpacMarc
:: El método para que este archivo sea leído por Apache depende del
:: sistema operativo y de la versión de Apache.  
::set APACHE_VHOST=G:\programas\Apache Software Foundation\Apache2.2\conf\extra\httpd-vhost-opacmarc-test-8081.conf
call test-config.bat

:: eliminamos el directorio de testeo si ya existe
rmdir /s /q %TEST_DIR% 2>NUL

mkdir %TEST_DIR%

set APP_DIR=%TEST_DIR%\app

:: obtenemos una copia fresca del código
echo.
svn export %SVN_DIR% %APP_DIR%

:: copiamos los binarios
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
::python %APP_DIR%\bin\demo.py
python %APP_DIR%\bin\add_db.py demo
python %APP_DIR%\bin\copy_demo_data.py
python %APP_DIR%\bin\update_db.py demo


:: reiniciamos Apache -- volver a probar --
::G:
::cd \programas\Apache Software Foundation\Apache2.2\bin\
::httpd -k restart
::cd \

::echo Reinicie Apache, y luego...
::pause

:: visitamos el opac
start firefox "http://127.0.0.1:8081/cgi-bin/wxis.exe?IsisScript=xis/opac.xis&db=demo"
