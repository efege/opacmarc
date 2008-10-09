# Script para testear la instalación de opacmarc en Linux
# Creado: FG, 2008-10-03


# -----------------------------------
# begin config
# -----------------------------------

# Directorio para el test. Es eliminado con cada nuevo test.
TEST_DIR=$HOME/opacmarc-test

# Directorio de los cisis 16/60
CISIS_DIR=$HOME/bin/cisis1660

# wxis 16/60
WXIS=$HOME/www/cgi-bin/wxis1660-7.1

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
ln -s $CISIS_DIR $TEST_DIR/bin/cisis-1660
ln -s $AGREP $TEST_DIR/bin/agrep

# instalación
python $TEST_DIR/bin/install.py

# permisos de escritura
for dir in logs temp
do
    sudo chgrp $APACHE_USER $TEST_DIR/local-data/$dir
    chmod g+w $TEST_DIR/local-data/$dir
done

# creación de base demo
python $TEST_DIR/bin/add_db.py demo
$CISIS_DIR/id2i $TEST_DIR/bin/install/data/demo.id create=$TEST_DIR/local-data/bases/demo/db/original/biblio
cp $TEST_DIR/bin/install/data/demo-img/* $TEST_DIR/local-data/bases/demo/htdocs/img/ 

# actualización de base demo
python $TEST_DIR/bin/update_db.py demo

# pisamos config para apache y lo reiniciamos
sudo cp $TEST_DIR/local-data/config/httpd-opacmarc.conf $APACHE_VHOST
sudo apache2ctl restart

# browser
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
