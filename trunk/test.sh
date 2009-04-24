# Script para testear la instalación de opacmarc en Linux
# Creado: FG, 2008-10-03
#
# Este script me resulta útil para testear la aplicación a partir de una
# working copy local. Para usarlo en otro contexto, habría que ajustar
# los parámetros de configuración y tal vez algún otro detalle.
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


CONFIG_FILE=test-config.sh
if [ ! -f $CONFIG_FILE ]; then
    echo "Missing configuration file: $CONFIG_FILE"
    echo "Test aborted"
    exit
fi

# Read configuration file
source $CONFIG_FILE

APP_DIR=$TEST_DIR/app
LOCAL_DATA_DIR=$TEST_DIR/local-data

sudo rm -rf $TEST_DIR
mkdir $TEST_DIR

# bajamos el código del repositorio
#svn checkout http://opacmarc.googlecode.com/svn/trunk/ $APP_DIR

# o bien exportamos desde la working copy local
svn export $SVN_DIR $APP_DIR

# creamos links a binarios
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

# Apache: pisamos config del virtual host y reiniciamos el servidor.
# Esto sólo se requiere si hay alguna modificación al template httpd-opacmarc.conf.
sudo cp $APP_DIR/config/httpd-opacmarc.conf $APACHE_VHOST
sudo apache2ctl restart

# Visitamos el opac
firefox "http://127.0.0.1:$APACHE_PORT/cgi-bin/wxis?IsisScript=xis/opac.xis&db=demo&showForm=simple" &

exit



# Test con una base local
TEST_DB=bibima
python $APP_DIR/bin/add_db.py $TEST_DB
ln -s $HOME/dev/opacmarc/local-testdata/bases/$TEST_DB/db/original/biblio.mst $LOCAL_DATA_DIR/bases/$TEST_DB/db/original/
ln -s $HOME/dev/opacmarc/local-testdata/bases/$TEST_DB/db/original/biblio.xrf $LOCAL_DATA_DIR/bases/$TEST_DB/db/original/

# Actualización de base local
python $APP_DIR/bin/update_db.py $TEST_DB

# Visitamos el opac
firefox "http://127.0.0.1:$APACHE_PORT/cgi-bin/wxis?IsisScript=xis/opac.xis&db=$TEST_DB&showForm=simple" &

