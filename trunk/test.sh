# Script para testear la instalación de opacmarc en Linux
# Creado: FG, 2008-10-03
#
# TO-DO: enviar la config a un archivo aparte.
#
# TO-DO: considerar dos tipos de test:
#            - new install (crea local-data)
#            - upgrade (usa local-data existente)
#        Podemos llamar al script de dos maneras:
#            - test install
#            - test upgrade
#        o bien:
#            - test i
#            - test u


# -----------------------------------
# begin config
# -----------------------------------

# versión de utilitarios cisis + wxis
CISIS_VERSION=5.2b-1030

# Directorio para el test. Es eliminado con cada nuevo test.
TEST_DIR=$HOME/opacmarc-test

# Directorio de los cisis
CISIS_DIR=$HOME/bin/cisis-$CISIS_VERSION

# wxis
WXIS=$HOME/www/cgi-bin/wxis-$CISIS_VERSION

# agrep
AGREP=`which agrep`

# Archivo con la configuración de un virtual host para OpacMarc
# El método para que este archivo sea leído por Apache depende del
# sistema operativo y de la versión de Apache.  
APACHE_VHOST=/etc/apache2/sites-available/opacmarc-test

# usuario asociado al servidor apache
APACHE_USER=www-data

# -----------------------------------
# end config
# -----------------------------------


rm -rf $TEST_DIR

# bajamos el código del repositorio
#svn checkout http://opacmarc.googlecode.com/svn/trunk/ $TEST_DIR

# o bien exportamos desde la working copy local
svn export $HOME/svn/opacmarc $TEST_DIR

# links a binarios
ln -s $WXIS $TEST_DIR/cgi-bin/wxis
ln -s $CISIS_DIR $TEST_DIR/bin/cisis
ln -s $AGREP $TEST_DIR/bin/agrep

# instalación
python $TEST_DIR/bin/install.py msc

# permisos de escritura
for dir in logs temp
do
    sudo chgrp $APACHE_USER $TEST_DIR/local-data/$dir
    chmod g+w $TEST_DIR/local-data/$dir
done

# Procesamos la base demo
python $TEST_DIR/bin/demo.py

# Pisamos config para apache y lo reiniciamos.
# Esto sólo se requiere si hay alguna modificación al template httpd-opacmarc.conf.
sudo cp $TEST_DIR/config/httpd-opacmarc.conf $APACHE_VHOST
sudo apache2ctl restart

# Accedemos al OPAC con un browser.
firefox "http://127.0.0.1:8081/cgi-bin/wxis?IsisScript=xis/opac.xis&db=demo&showForm=simple" &

exit

# nueva base: bibima
python $TEST_DIR/bin/add_db.py bibima
ln -s $HOME/svn/opacmarc/local-data/bases/bibima/db/original/biblio.mst $TEST_DIR/local-data/bases/bibima/db/original/
ln -s $HOME/svn/opacmarc/local-data/bases/bibima/db/original/biblio.xrf $TEST_DIR/local-data/bases/bibima/db/original/

# actualización de base bibima
python $TEST_DIR/bin/update_db.py bibima

# browser
firefox "http://127.0.0.1:8081/cgi-bin/wxis?IsisScript=xis/opac.xis&db=bibima&showForm=simple" &
