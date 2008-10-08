@echo off
:: Script para testear opacmarc en Windows
:: Creado: FG, 2008-10-06

set TEST_DIR=G:\opacmarc-test
set CISIS_DIR=G:\programas\cisis\5.2\1660
set WXIS=G:\svn\opacmarc\cgi-bin\wxis.exe
set AGREP=G:\svn\opacmarc\bin\agrep.exe
set APACHE_VHOST=G:\programas\Apache Software Foundation\Apache2.2\conf\extra\httpd-vhost-opacmarc-test-8081.conf


:: eliminamos el directorio si ya existe
rmdir /s /q %TEST_DIR%

:: obtenemos una copia fresca del código
svn export G:\svn\opacmarc %TEST_DIR%

:: colocamos los binarios en su lugar
mkdir %TEST_DIR%\bin\cisis-1660
copy %CISIS_DIR%\*.* %TEST_DIR%\bin\cisis-1660\
copy %WXIS% %TEST_DIR%\cgi-bin\wxis.exe
copy %AGREP% %TEST_DIR%\bin\agrep.exe

:: ejecutamos script de inicialización
python %TEST_DIR%\install.py

:: pisamos configuración de apache
copy "%TEST_DIR%\local-data\config\httpd-opacmarc.conf" "%APACHE_VHOST%"

:: procesamos con la base demo
python %TEST_DIR%\bin\newdb.py demo
:: FIXME - crear base original a partir de id
python %TEST_DIR%\bin\update-opac.py demo


:: reiniciamos Apache
::G:
::cd \programas\Apache Software Foundation\Apache2.2\bin\
::httpd
::cd \

:: vemos qué onda
start firefox "http://127.0.0.1:8081/cgi-bin/wxis.exe?IsisScript=xis/opac.xis&db=demo"
