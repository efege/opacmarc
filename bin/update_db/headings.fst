0 0 /* ========================================================= */
0 0 /*  FST compartida por las dos bases de encabezamientos      */
0 0 /*  (subj & name).                                           */
0 0 /*                                                           */
0 0 /*  (c) 2003 Fernando J. Gómez - CONICET - INMABB            */
0 0 /* ========================================================= */


0 0 /* Invertimos todos los subcampos, palabra por palabra */
1 4 proc('a1002¦', replace(v1*1, '~', '¦a1002¦'), '¦'),,,  (v1002*1/)


0 0 /* Para los "saltos" dentro del indice, invertimos el campo completo */

0 0 /* ATENCION: el orden resultante debe coincidir con el orden de la base */
0 0 /* de encabezamientos -- Actualmente el espacio en blanco queda antes */
0 0 /* que el '~', y no deberia ser asi */
0 0 /* replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(v1,'~x','^'),'~y','^'),'~z','^'),'~v','^'),'.~b','^'),'.~t','^'),'~q','^'),'^','~'),', ',' '),'-',' '),'.',' '),s("'"n9999),'') */

0 0 /* Approach novedoso: asegura la consistencia con el orden de la base */
2 0 '~',@HEADSORT.PFT,


0 0 /* Campo 9: número de identificación del heading */
9 0 |_HEAD_|v9


0 0 /* Campo 8: lista de subcatálogos donde aparece el heading */
8 0 (|_SC_|v8/)

