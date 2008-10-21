# Script para testear la instalación de opacmarc en Linux
# Creado: FG, 2008-10-03
#
# Este script me resulta útil para testear la aplicación a partir de una
# working copy local. Para usarlo en otro contexto, habría que ajustar
# los parámetros de configuración y tal vez algún otro detalle.
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

APP_DIR=$TEST_DIR/app
LOCAL_DATA_DIR=$TEST_DIR/local-data

sudo rm -rf $TEST_DIR
mkdir $TEST_DIR

# bajamos el código del repositorio
#svn checkout http://opacmarc.googlecode.com/svn/trunk/ $APP_DIR

# o bien exportamos desde la working copy local
svn export $HOME/svn/opacmarc $APP_DIR

# links a binarios
ln -s $WXIS      $APP_DIR/cgi-bin/wxis
ln -s $CISIS_DIR $APP_DIR/bin/cisis
ln -s $AGREP     $APP_DIR/bin/agrep

# instalación
python $APP_DIR/bin/install.py msc

# permisos de escritura
for dir in logs temp
do
    sudo chgrp -R $APACHE_USER $LOCAL_DATA_DIR/$dir
    chmod -R g+w $LOCAL_DATA_DIR/$dir
done

# Procesamos la base demo
#python $APP_DIR/bin/demo.py
python $APP_DIR/bin/add_db.py demo
python $APP_DIR/bin/copy_demo_data.py
python $APP_DIR/bin/update_db.py demo

# Pisamos config para apache y lo reiniciamos.
# Esto sólo se requiere si hay alguna modificación al template httpd-opacmarc.conf.
sudo cp $APP_DIR/config/httpd-opacmarc.conf $APACHE_VHOST
sudo apache2ctl restart

# Visitamos el opac
firefox "http://127.0.0.1:8081/cgi-bin/wxis?IsisScript=xis/opac.xis&db=demo&showForm=simple" &

exit

# Nueva base: bibima
python $APP_DIR/bin/add_db.py bibima
ln -s $HOME/svn/opacmarc/local-data/bases/bibima/db/original/biblio.mst $LOCAL_DATA_DIR/bases/bibima/db/original/
ln -s $HOME/svn/opacmarc/local-data/bases/bibima/db/original/biblio.xrf $LOCAL_DATA_DIR/bases/bibima/db/original/

# Actualización de base bibima
python $APP_DIR/bin/update_db.py bibima

# Visitamos el opac
firefox "http://127.0.0.1:8081/cgi-bin/wxis?IsisScript=xis/opac.xis&db=bibima&showForm=simple" &
