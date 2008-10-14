@echo off
:: Script para testear opacmarc en Windows
:: Creado: FG, 2008-10-06


:: Leemos par�metros locales de un archivo externo.
:: Esta es la lista de par�metros esperados, con valores s�lo a modo
:: de ejemplo:
::
:: Directorio para el test. Es eliminado con cada nuevo test.
:: set TEST_DIR=G:\opacmarc-test
::
:: directorio de los cisis 16/60
:: set CISIS_DIR=G:\programas\cisis\5.2\1660
::
:: wxis 16/60
:: set WXIS=G:\svn\opacmarc\cgi-bin\wxis.exe
::
:: agrep
:: set AGREP=G:\svn\opacmarc\bin\agrep.exe
::
:: Archivo con la configuraci�n de un virtual host para OpacMarc
:: set APACHE_VHOST=G:\programas\Apache Software Foundation\Apache2.2\conf\extra\httpd-vhost-opacmarc-test-8081.conf
call test-config.bat

:: eliminamos el directorio si ya existe
rmdir /s /q %TEST_DIR% 2>NUL

:: obtenemos una copia fresca del c�digo
echo.
svn export G:\svn\opacmarc %TEST_DIR%

:: colocamos los binarios en su lugar
echo.
mkdir %TEST_DIR%\bin\cisis-1660
copy %CISIS_DIR%\*.* %TEST_DIR%\bin\cisis-1660\
copy %WXIS% %TEST_DIR%\cgi-bin\wxis.exe
copy %AGREP% %TEST_DIR%\bin\agrep.exe

:: ejecutamos script de inicializaci�n
python %TEST_DIR%\bin\install.py

:: pisamos configuraci�n de Apache
copy "%TEST_DIR%\config\httpd-opacmarc.conf" "%APACHE_VHOST%"

:: procesamos la base demo
python %TEST_DIR%\bin\demo.py

:: reiniciamos Apache
::G:
::cd \programas\Apache Software Foundation\Apache2.2\bin\
::httpd
::cd \

::echo Reinicie Apache, y luego...
::pause

:: vemos qu� onda
start firefox "http://127.0.0.1:8081/cgi-bin/wxis.exe?IsisScript=xis/opac.xis&db=demo"
