#!/usr/bin/env python
# coding=windows-1252

"""
'Instala' la base demo en el OPAC.

TO-DO: generar un mensaje final que indique cómo acceder a la base con un navegador.
"""

import os
import shutil
import add_db
import update_db
from opac_util import CISIS_PATH, APP_DIR, LOCAL_DATA_DIR
from opac_util import run_command as run

def copy_demo_data():

    db_src = '%s/bin/install/data/demo.id' % APP_DIR
    db_dst = '%s/bases/demo/db/original/biblio' % LOCAL_DATA_DIR
    run('%s/id2i %s create=%s' % (CISIS_PATH, db_src, db_dst))
    
    img_src = '%s/bin/install/data/demo-img' % APP_DIR
    img_dst = '%s/bases/demo/htdocs/img' % LOCAL_DATA_DIR
    images = os.listdir(img_src)
    for img in images:
        shutil.copy(os.path.join(img_src, img), img_dst)

def main():
    add_db.main('demo')
    copy_demo_data()
    update_db.main('demo')
    
if __name__ == "__main__":
    main()
