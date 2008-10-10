@echo off
:: Script para testear opacmarc en Windows
:: Creado: FG, 2008-10-06

:: -----------------------------------
:: begin config
:: -----------------------------------

:: Directorio para el test. Es eliminado con cada nuevo test.
set TEST_DIR=G:\opacmarc-test

:: directorio de los cisis 16/60
set CISIS_DIR=G:\programas\cisis\5.2\1660

:: wxis 16/60
set WXIS=G:\svn\opacmarc\cgi-bin\wxis.exe

:: agrep
set AGREP=G:\svn\opacmarc\bin\agrep.exe

:: Archivo con la configuración de un virtual host para OpacMarc
:: El método para que este archivo sea leído por Apache depende del
:: sistema operativo y de la versión de Apache.  
set APACHE_VHOST=G:\programas\Apache Software Foundation\Apache2.2\conf\extra\httpd-vhost-opacmarc-test-8081.conf

:: -----------------------------------
:: end config
:: -----------------------------------


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
python %TEST_DIR%\bin\install.py

:: procesamos la base demo
python %TEST_DIR%\bin\add_db.py demo
%CISIS_DIR%\id2i %TEST_DIR%\bin\install\data\demo.id create=%TEST_DIR%\local-data\bases\demo\db\original\biblio
copy %TEST_DIR%\bin\install\data\demo-img\* %TEST_DIR%\local-data\bases\demo\htdocs\img\
python %TEST_DIR%\bin\update_db.py demo

:: pisamos configuración de apache
copy "%TEST_DIR%\config\httpd-opacmarc.conf" "%APACHE_VHOST%"

:: reiniciamos Apache
::G:
::cd \programas\Apache Software Foundation\Apache2.2\bin\
::httpd
::cd \

:: vemos qué onda
start firefox "http://127.0.0.1:8081/cgi-bin/wxis.exe?IsisScript=xis/opac.xis&db=demo"
