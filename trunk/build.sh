# Script for building an OpacMarc release.
#
# Since we are including binaries, we must create separate builds
# for Windows and Linux.
#
# NOTE: the build dir path is relative to the current directory.
#
# Usage: ./build.sh
#
# TO-DO: add common header to all code files (copyright, license, etc)
#
# TO-DO: para Windows generar .zip y no .tgz; para Linux .tgz o .tar.gz? 
#
# TO-DO: concat & compress JS, CSS (see min.sh in Catalis)
#
# TO-DO: add cisis version (1030/1660) as an option
#
# TO-DO: para subir los archivos a Google Code, ver http://support.googlecode.com/svn/trunk/scripts/googlecode_upload.py
#        Parece que hay problemas con el proxy en la UNS (2008-10-15)
#
# FIXME - el binario de agrep no funciona en cualquier plataforma Linux; p.ej. aparece "Excepción de coma flotante"
#         en una máquina 'x86_64'. Por lo tanto, lo mejor será no incluirlo en el paquete,
#         y que cada usuario se ocupe de instalarlo o compilarlo desde las fuentes. 
#


CONFIG_FILE=build-config.sh

if [ ! -f $CONFIG_FILE ]; then
    echo 'Missing configuration file:' $CONFIG_FILE
    echo 'Build process aborted'
    exit
fi


# Read configuration
source $CONFIG_FILE

build() {

    echo 'Building for' $SYSTEM '...'

    case $SYSTEM in
        linux)
            # Directory containing cisis
            CISIS_DIR=$BINARIES/linux/cisis-$CISIS_VERSION
            
            # wxis
            WXIS=$BINARIES/linux/wxis-$CISIS_VERSION
            WXIS_NAME='wxis'
            
            # agrep
            AGREP=`which agrep`
            ;;
        windows)
            # Directory containing cisis
            CISIS_DIR=$BINARIES/windows/cisis-$CISIS_VERSION
            
            # wxis
            WXIS=$BINARIES/windows/wxis-$CISIS_VERSION.exe
            WXIS_NAME='wxis.exe'
            
            # agrep
            AGREP=$BINARIES/windows/agrep.exe
            ;;
    esac
    
    # remove previous build with same name, if any
    rm -rf $BUILD_DIR
    rm -f $BUILD_DIR-$SYSTEM.tgz
    
    # export a clean copy
    svn export $WORKING_COPY $BUILD_DIR
    
    # links to binaries (requieres option -h in tar below)
    # we could copy them instead
    ln -s $WXIS      $BUILD_DIR/cgi-bin/$WXIS_NAME
    ln -s $CISIS_DIR $BUILD_DIR/bin/cisis
    ln -s $AGREP     $BUILD_DIR/bin/
    
    # modify files which include version number
    # TO-DO: loop over a list of filenames
    sed "s/__VERSION__/$BUILD_DATE/" $BUILD_DIR/cgi-bin/html/page-end.htm > tmpfile
    mv tmpfile $BUILD_DIR/cgi-bin/html/page-end.htm
    
    case $SYSTEM in
        linux)
            rm $BUILD_DIR/test.bat
            ;;
        windows)
            rm $BUILD_DIR/test.sh
            # TO-DO: remove any other .sh files
            ;;
    esac
    
    cd $BUILD_DIR/..

    # option -h (--dereference): don’t dump symlinks; dump the files they point to
    tar -czhf $BUILD_DIR-$SYSTEM.tgz $BUILD_DIR/
    
    rm -rf $BUILD_DIR
}

upload() {
    # upload file to public server
    echo 'Uploading...'
    scp $BUILD_DIR-$SYSTEM.tgz $SERVER_INFO
}


for SYSTEM in linux windows
do
    build
    upload
done
