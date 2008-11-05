<?php
    /**
    * @param 1 Archivo de nombres autorizados
    * @param 2 Límite para la distancia de Levenshtein
    */
   
    /* TO-DO: añadir normalizeNACO(). Ver http://www.loc.gov/catdir/pcc/naco/normrule.html y algunas pruebas que hice en PHP */
    
    /* TO-DO: mostrar número de control de los registros */

    $handle = fopen($argv[1], "r");
    $limit = $argv[2];

    if ($line0 = fgets($handle, 1024)){

        while (!feof($handle)) {
            $line1 = fgets($handle, 1024);

            //comparar line0 y line1
            $dist = levenshtein($line0, $line1);
            if ($dist <= $limit) {
                print('distancia: ' . $dist . "\r\n" . '  ' . $line0 . '  ' . $line1 . "\r\n");
            }

            $line0 = $line1;
        }
    }

    fclose($handle);

?>
