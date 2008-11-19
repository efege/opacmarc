#!/usr/bin/env python
# coding=windows-1252

"""
Copia los datos de la base demo en local-data.

Debe ejecutarse luego de haber creado las carpetas para la base demo
usando add_db.py.

Este script debería ser reemplazado localmente por algún script similar
(a ser ubicado en local-data/bin/), que se ocupe de copiar base de datos
y/o los archivos de imágenes en las carpetas donde update_db.py espera
encontrarlos.  
"""

import os
import shutil
from opac_util import CISIS_PATH, APP_DIR, LOCAL_DATA_DIR
from opac_util import run_command as run

def main():

    # base de datos bibliográfica
    db_src = '%s/bin/install/data/demo.id' % APP_DIR
    db_dst = '%s/bases/demo/db/original/biblio' % LOCAL_DATA_DIR
    run('%s/id2i %s create=%s' % (CISIS_PATH, db_src, db_dst))

    # registros de autoridad (referencias)
    db_src = '%s/bin/install/data/demo-ref-name.id' % APP_DIR
    db_dst = '%s/bases/demo/db/original/name-references.id' % LOCAL_DATA_DIR
    shutil.copy(db_src, db_dst)
    
    # imágenes
    img_src = '%s/bin/install/data/demo-img' % APP_DIR
    img_dst = '%s/bases/demo/htdocs/img' % LOCAL_DATA_DIR
    images = os.listdir(img_src)
    for img in images:
        shutil.copy(os.path.join(img_src, img), img_dst)

if __name__ == "__main__":
    main()
