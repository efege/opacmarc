0000 0 /* =================================================     */
0000 0 /*  FST para bases bibliográficas MARC 21                */
0000 0 /*                                                       */
0000 0 /*  Compartida por el OPAC y Catalis.                    */
0000 0 /*                                                       */
0000 0 /*  Mejor mantener este archivo con la codificación      */
0000 0 /*  ISO-8859-1                                           */
0000 0 /*                                                       */
0000 0 /*  (c) 2003-2006 Fernando J. Gómez - CONICET - INMABB   */
0000 0 /* =================================================     */


0000 0 /* ================================================= */
0000 0 /*           Nro. de control del registro            */
0000 0 /* ================================================= */
9001 0 '-NC=',v001

0000 0 /* ================================================= */
0000 0 /*          Tipo de registro (default: 'a')          */
0000 0 /* ================================================= */
9001 0 if not v906 = 'a' then '-TYPE=',v906, fi

0000 0 /* ================================================= */
0000 0 /*        Nivel bibliográfico (default: 'm')         */
0000 0 /* ================================================= */
9001 0 if not v907 = 'm' then '-BIBLEVEL=',v907, fi

0000 0 /* ================================================= */
0000 0 /*                     Fecha                         */
0000 0 /* ================================================= */
9008 0 '-F=',v008*07.4                                 /* 008 date1 */
9008 0 if v008*11.4 <> '####' then '-F=',v008*11.4, fi /* 008 date2 */


0000 0 /* ================================================= */
0000 0 /*               Idiomas, traducciones               */
0000 0 /* ================================================= */
0000 0 /* Usamos prefijo en los idiomas para "facilitar" la generacion del listado */
9041 0 if a(v041) then '-LANG=',v008*35.3 fi
9041 8 '#-LANG=#', if p(v041^a) then proc('d1000',(,'a1000¦',replace(v041*3,'^','¦a1000¦'),'¦'),), ( if 'a' : v1000.1 then v1000*1/ fi ), fi

0000 0 /* Multiples códigos en un mismo subcampo. ATENCION: estamos ignorando *todo* el campo cada vez que hay mas de n idiomas! */
0000 0 /* Segun MARC 21, se pueden repiten subcampos, pero cada subcampo tiene solo un codigo */
9041 8 '#-LANG=#', if v041.1='0' AND size(v41^a) > 3 then v41^a.3/, if size(v41^a)=6 then v41^a*3.3/, else if size(v41^a)=9 then v41^a*3.3/,v41^a*6.3/ else if size(v41^a)=12 then v41^a*3.3/,v41^a*6.3/,v41^a*9.3/ else if size(v41^a)=15 then v41^a*3.3/,v41^a*6.3/,v41^a*9.3/,v41^a*12.3/ fi,fi,fi,fi,fi

0000 0 /* Traducciones (tomamos la ausencia de v41 como no-traducción?) */
9041 0 select v041.1 case '1' : '-TRANS=YES', case '0' : '-TRANS=NO', endsel


0000 0 /* ================================================= */
0000 0 /*              Números normalizados                 */
0000 0 /* ================================================= */
0000 0 /* TO-DO: Faltan 024, 027, 510^x, 534^x, 534^z, 556^z, 581^z, 7XX^x */
9020 0 if p(v020) then proc('d1000',(,'a1000¦',replace(v020*3,'^','¦a1000¦'),'¦'),), ( if 'a' : v1000.1 then '-SN='v1000*1.10/ fi ), fi
9020 0 if p(v022) then proc('d1000',(,'a1000¦',replace(v022*3,'^','¦a1000¦'),'¦'),), ( if 'a' : v1000.1 then '-SN='v1000*1.9/ fi ), fi
9020 8 '#-SN=#', ( replace(v247^x.10,'-','')/ )
9020 8 '#-SN=#', ( replace(v440^x.10,'-','')/ )
9020 8 '#-SN=#', ( replace(v490^x.10,'-','')/ )


0000 0 /* ================================================= */
0000 0 /*             Otra información codificada           */
0000 0 /* ================================================= */
9008 0 /* 008: Festchrift */ if v008*30.1='1' then '-FEST' fi
9008 0 /* 008: Fiction    */ if '0eis' : v008*33.1 then '-FICTION=NO' else if '1cdfhjmp' : v008*33.1 then '-FICTION=YES' fi,fi
9008 0 /* 008: Biography  */ if 'abcd' : v008*34.1 then '-BIOGR=YES' fi
9008 0 /* 008: Reference  */ if s(v008*24.4) : 'd' or s(v008*24.4) : 'e' then '-REFERENCE' fi /* diccionarios, enciclopedias */
9050 0 /* if p(v050) then ( '-LCC=', if '0123456789' : v050^a*1.1 then v050^a.1 else v050^a.2 fi/ ), fi */
9995 0 /* (|-BIB=|v995/) */


0000 0 /* ================================================= */
0000 0 /*               Lugar de publicación                */
0000 0 /* ================================================= */
0000 0 /* Por palabras individuales (si tomo subcampo completo, debo eliminar puntuacion) */
0000 0 /* Incluimos 260$e (lugar de fabricacion) */
9260 4 proc('d1000a1000¦',replace(v260*2,'^','¦a1000¦'),'¦'), ( if 'ae' : v1000.1 then v1000*1/ fi )
0000 0 /* TO-DO: agregar campo 044 */


0000 0 /* ================================================= */
0000 0 /*                Editorial (publisher)              */
0000 0 /* (molestan comitas finales, no siempre presentes)  */
0000 0 /* ================================================= */
0000 0 /* Por palabras individuales (si tomo subcampo completo, debo eliminar puntuacion) */
0000 0 /* Incluimos 260$f (fabricante) */
9261 4 proc('d1000a1000¦',replace(v260*2,'^','¦a1000¦'),'¦'), ( if 'bf' : v1000.1 then v1000*1/ fi )


0000 0 /* ================================================= */
0000 0 /*  Nombres: personales, institucionales, reuniones  */
0000 0 /* ================================================= */
0000 0 /* Basado parcialmente en: http://www.unt.edu/wmoen/Z3950/MARC21Indexing/IndexingRecommendationsAuthorSearches.pdf */
0000 0 /* No incluimos ningun 6xx */
0000 0 /* Que pasa con v505^r, nombres no controlados? */

0000 0 /* =================================================== */
0000 0 /* Encabezamientos completos (subcampos seleccionados) */
0000 0 /* =================================================== */
9100 0 if p(v100) then proc('d1000',  'a1000¦',replace(v100*3,'^','¦a1000¦'),'¦','a1000¦##¦',),   ,(,if v1000 = '##' then / else if 'abcdq'  : v1000.1 then '~'v1000*1, else if '9'=v1000.1 then /'_NAME_',v1000*1/ fi,fi,fi ,), fi,
9100 0 if p(v110) then proc('d1000',  'a1000¦',replace(v110*3,'^','¦a1000¦'),'¦','a1000¦##¦',),   ,(,if v1000 = '##' then / else if 'abcdknt': v1000.1 then '~'v1000*1, else if '9'=v1000.1 then /'_NAME_',v1000*1/ fi,fi,fi ,), fi,
9100 0 if p(v111) then proc('d1000',  'a1000¦',replace(v111*3,'^','¦a1000¦'),'¦','a1000¦##¦',),   ,(,if v1000 = '##' then / else if 'acdenq' : v1000.1 then '~'v1000*1, else if '9'=v1000.1 then /'_NAME_',v1000*1/ fi,fi,fi ,), fi,
9100 0 if p(v700) then proc('d1000',(,'a1000¦',replace(v700*3,'^','¦a1000¦'),'¦','a1000¦##¦',) ), ,(,if v1000 = '##' then / else if 'abcdq'  : v1000.1 then '~'v1000*1, else if '9'=v1000.1 then /'_NAME_',v1000*1/ fi,fi,fi ,), fi,
9100 0 if p(v710) then proc('d1000',(,'a1000¦',replace(v710*3,'^','¦a1000¦'),'¦','a1000¦##¦',) ), ,(,if v1000 = '##' then / else if 'abcdknt': v1000.1 then '~'v1000*1, else if '9'=v1000.1 then /'_NAME_',v1000*1/ fi,fi,fi ,), fi,
9100 0 if p(v711) then proc('d1000',(,'a1000¦',replace(v711*3,'^','¦a1000¦'),'¦','a1000¦##¦',) ), ,(,if v1000 = '##' then / else if 'acdenq' : v1000.1 then '~'v1000*1, else if '9'=v1000.1 then /'_NAME_',v1000*1/ fi,fi,fi ,), fi,

0000 0 /* ================================================= */
0000 0 /*  Palabras individuales (subcampos seleccionados)  */
0000 0 /* ================================================= */
9104 4 if p(v100) then proc('d1000',  'a1000¦',replace(v100*3,'^','¦a1000¦'),'¦','a1000¦##¦',),   ,(,if v1000 = '##' then / else if 'abcdq'  : v1000.1 then '~'v1000*1, fi,fi ,), fi,
9104 4 if p(v110) then proc('d1000',  'a1000¦',replace(v110*3,'^','¦a1000¦'),'¦','a1000¦##¦',),   ,(,if v1000 = '##' then / else if 'abcdknt': v1000.1 then '~'v1000*1, fi,fi ,), fi,
9104 4 if p(v111) then proc('d1000',  'a1000¦',replace(v111*3,'^','¦a1000¦'),'¦','a1000¦##¦',),   ,(,if v1000 = '##' then / else if 'acdenq' : v1000.1 then '~'v1000*1, fi,fi ,), fi,
9104 4 if p(v700) then proc('d1000',(,'a1000¦',replace(v700*3,'^','¦a1000¦'),'¦','a1000¦##¦',) ), ,(,if v1000 = '##' then / else if 'abcdq'  : v1000.1 then '~'v1000*1, fi,fi ,), fi,
9104 4 if p(v710) then proc('d1000',(,'a1000¦',replace(v710*3,'^','¦a1000¦'),'¦','a1000¦##¦',) ), ,(,if v1000 = '##' then / else if 'abcdknt': v1000.1 then '~'v1000*1, fi,fi ,), fi,
9104 4 if p(v711) then proc('d1000',(,'a1000¦',replace(v711*3,'^','¦a1000¦'),'¦','a1000¦##¦',) ), ,(,if v1000 = '##' then / else if 'acdenq' : v1000.1 then '~'v1000*1, fi,fi ,), fi,


0000 0 /* ================================================= */
0000 0 /*              Títulos (por palabras)               */
0000 0 /* ================================================= */
0000 0 /* Basado parcialmente en: http://www.unt.edu/wmoen/Z3950/MARC21Indexing/IndexingRecommendationsTitleSearches.pdf */
0000 0 /* ATENCION: algunos subcampos (^n, ^p) se pueden repetir */

0000 0 /* Títulos en la descripcion */
0000 0 /* ========================= */
9204 4 /* 210 */ (v210^a/ v210^b/), /* Abbrev. title */
9204 4 /* 222 */ (v222^a/ v222^b/), /* Key title */
9204 4 /* 240 */ proc('d1000a1000¦',replace(v240*3,'^','¦a1000¦'),'¦'), ( if 'adfgkmnoprs'  : v1000.1 then v1000*1/ fi )
9204 4 /* 245 */ proc('d1000a1000¦',replace(v245*3,'^','¦a1000¦'),'¦'), ( if 'abfgknps'     : v1000.1 then v1000*1/ fi )
9204 4 /* 246 */ ( proc('d1000a1000¦',replace(v246*2,s('^i',v246^i),''),'¦') ), (mhl,v1000/)
9204 4 /* 500 */ /* ( if v500^a : 'Translation of' then mid(v500^a,instr(v500^a,'Translation of')+15,size(v500^a))/ fi ) */
9204 4 /* 505 */ proc('d1000a1000¦',v505*2,'¦'), proc('d1000a1000¦',replace(v1000,'^','¦a1000¦'),'¦'), ( if 't' : v1000.1 then v1000*1/ fi )
9204 4 /* 534 */ (v534^t/)  /* Original version note */

0000 0 /* Títulos en puntos de acceso */
0000 0 /* =========================== */
9204 4 /* 100 */ v100^n/ v100^p/ v100^t/
9204 4 /* 110 */ v110^n/ v110^p/ v110^t/
9204 4 /* 111 */ v111^n/ v111^p/ v111^t/
9204 4 /* 130 */ proc('d1000a1000¦',replace(v130*3,'^','¦a1000¦'),'¦'), ( if 'adfgkmnoprst' : v1000.1 then v1000*1/ fi )
9204 4 /* 700 */ (v700^n/ v700^p/ v700^t/)
9204 4 /* 710 */ (v710^n/ v710^p/ v710^t/)
9204 4 /* 711 */ (v711^n/ v711^p/ v711^t/)
9204 4 /* 730 */ (v730^a/ v730^n/ v730^p/ v730^t/)
9204 4 /* 740 */ (v740^a/ v740^n/ v740^p/)
9204 4 /* 760 */ (v760^s/ v760^t/)
9204 4 /* 762 */ (v762^s/ v762^t/)
9204 4 /* 770 */ (v770^s/ v770^t/)
9204 4 /* 772 */ (v772^s/ v772^t/)
9204 4 /* 773 */ (v773^p/ v773^s/ v773^t/)
9204 4 /* 774 */ (v774^s/ v774^t/)
9204 4 /* 780 */ (v780^s/ v780^t/)
9204 4 /* 785 */ (v785^s/ v785^t/)
9204 4 /* 787 */ (v787^s/ v787^t/)

0000 0 /* Títulos como temas ?? */
0000 0 /* ===================== */
9204 4 /* 600 */ (v600^n/ v600^p/ v600^t/)
9204 4 /* 610 */ (v610^n/ v610^p/ v610^t/)
9204 4 /* 611 */ (v611^n/ v611^p/ v611^t/)
9204 4 /* 630 */ (v630^a/ v630^n/ v630^p/ v630^t/)


0000 0 /* ================================================= */
0000 0 /*     Títulos completos (para links, tecnica 0)     */
0000 0 /* ================================================= */
9200 0 if p(v130)   then proc('d1000',  'a1000¦',replace(v130*3,'^','¦a1000¦'),'¦'),                ,(,                            if 'adfgkmnoprst': v1000.1 then '~'v1000*1/ fi    ,), fi,
9200 0 if p(v240)   then proc('d1000',  'a1000¦',replace(v240*3,'^','¦a1000¦'),'¦'),                ,(,                            if 'a           ': v1000.1 then '~'v1000*1/ fi    ,), fi,
9200 0 if p(v245)   then proc('d1000',  'a1000¦',replace(v245*3,'^','¦a1000¦'),'¦','a1000¦##¦',),   ,(,if v1000 = '##' then / else if 'abfgknps'    : v1000.1 then '~',replace(v1000*1,'_/',''), fi,fi ,), fi,
9200 0 if p(v246)   then proc('d1000',(,'a1000¦',replace(v246*3,'^','¦a1000¦'),'¦','a1000¦##¦',) ), ,(,if v1000 = '##' then / else if 'abgnp'       : v1000.1 then '~'v1000*1, fi,fi ,), fi,
9200 0 if p(v505^t) then proc('d1000',(,'a1000¦',replace(v505*3,'^','¦a1000¦'),'¦','a1000¦##¦',) ), ,(,if v1000 = '##' then / else if 't'           : v1000.1 then '~'v1000*1, fi,fi ,), fi,
9200 0 if p(v700^t) then proc('d1000',(,'a1000¦',replace(v700*3,'^','¦a1000¦'),'¦','a1000¦##¦',) ), ,(,if v1000 = '##' then / else if 'npt'         : v1000.1 then '~'v1000*1, fi,fi ,), fi,
9200 0 if p(v730)   then proc('d1000',(,'a1000¦',replace(v730*3,'^','¦a1000¦'),'¦','a1000¦##¦',) ), ,(,if v1000 = '##' then / else if 'adfgkmnoprst': v1000.1 then '~'v1000*1/ fi,fi ,), fi,
9200 0 if p(v740)   then proc('d1000',(,'a1000¦',replace(v740*3,'^','¦a1000¦'),'¦','a1000¦##¦',) ), ,(,if v1000 = '##' then / else if 'anp'         : v1000.1 then '~'v1000*1/ fi,fi ,), fi,


0000 0 /* ================================================= */
0000 0 /*          Series (por palabras)           */
0000 0 /* ================================================= */
9404 4 /* 440 */ ( proc('d1000a1000¦',replace(v440*4,s('^v',v440^v),''),'¦') ), (mhl,v1000/)
9404 4 /* 490 */ ( proc('d1000a1000¦',replace(v490*4,s('^v',v490^v),''),'¦') ), (mhl,v1000/)
9404 4 /* 800 */ (v800^n/ v800^p/ v800^t/)
9404 4 /* 810 */ (v810^n/ v810^p/ v810^t/)
9404 4 /* 811 */ (v811^n/ v811^p/ v811^t/)
9404 4 /* 830 */ (v830^a/ v830^n/ v830^p/ v830^t/)


0000 0 /* ================================================= */
0000 0 /*          Series (para links, técnica 0)           */
0000 0 /* ================================================= */
0000 0 /* ATENCION: revisar subcampos (quitar $6,$8), repetibilidad, etc. */
0000 0 /* ATENCION: en el 440 usamos el 2do indicador */
9400 0 if p(v440) then proc('d1000',(,'a1000¦',v440*3.1,replace(mid(v440*4,val(v440*1.1)+1,size(v440)),'^','¦a1000¦'),'¦','a1000¦##¦',), ), ,(,if v1000 = '##' then / else if 'a' : v1000.1 then '~'v1000*1, fi,fi ,), fi,
0000 0 /* TO-DO: 800, 810, 811 */
9400 0 if p(v830) then proc('d1000',(,'a1000¦',replace(v830*3,'^','¦a1000¦'),'¦','a1000¦##¦',), ), ,(,if v1000 = '##' then / else if 'a' : v1000.1 then '~'v1000*1, fi,fi ,), fi,


0000 0 /* ================================================= */
0000 0 /*                      Temas                        */
0000 0 /* ================================================= */
0000 0 /* Basado parcialmente en: http://www.unt.edu/wmoen/Z3950/MARC21Indexing/IndexingRecommendationsSubjectSearches.pdf */

0000 0 /* --- Encabezamientos completos (subcampos seleccionados) --- */
9600 0 if p(v600) then proc('d1000',(,'a1000¦',replace(v600*3,'^','¦a1000¦'),'¦','a1000¦##¦',), ), ,(,if v1000 = '##' then / else if not '234689': v1000.1 then '~'v1000*1, else if '9'=v1000.1 then /'_SUBJ_',v1000*1/ fi,fi,fi ,), fi,
9600 0 if p(v610) then proc('d1000',(,'a1000¦',replace(v610*3,'^','¦a1000¦'),'¦','a1000¦##¦',), ), ,(,if v1000 = '##' then / else if not '234689': v1000.1 then '~'v1000*1, else if '9'=v1000.1 then /'_SUBJ_',v1000*1/ fi,fi,fi ,), fi,
9600 0 if p(v611) then proc('d1000',(,'a1000¦',replace(v611*3,'^','¦a1000¦'),'¦','a1000¦##¦',), ), ,(,if v1000 = '##' then / else if not '234689': v1000.1 then '~'v1000*1, else if '9'=v1000.1 then /'_SUBJ_',v1000*1/ fi,fi,fi ,), fi,
9600 0 if p(v630) then proc('d1000',(,'a1000¦',replace(v630*3,'^','¦a1000¦'),'¦','a1000¦##¦',), ), ,(,if v1000 = '##' then / else if not '23689' : v1000.1 then '~'v1000*1, else if '9'=v1000.1 then /'_SUBJ_',v1000*1/ fi,fi,fi ,), fi,
9600 0 if p(v650) then proc('d1000',(,'a1000¦',replace(v650*3,'^','¦a1000¦'),'¦','a1000¦##¦',), ), ,(,if v1000 = '##' then / else if not '23689' : v1000.1 then '~'v1000*1, else if '9'=v1000.1 then /'_SUBJ_',v1000*1/ fi,fi,fi ,), fi,
9600 0 if p(v651) then proc('d1000',(,'a1000¦',replace(v651*3,'^','¦a1000¦'),'¦','a1000¦##¦',), ), ,(,if v1000 = '##' then / else if not '23689' : v1000.1 then '~'v1000*1, else if '9'=v1000.1 then /'_SUBJ_',v1000*1/ fi,fi,fi ,), fi,
9600 0 if p(v653) then proc('d1000',(,'a1000¦',replace(v653*3,'^','¦a1000¦'),'¦','a1000¦##¦',), ), ,(,if v1000 = '##' then / else if not '9'     : v1000.1 then '~'v1000*1, else if '9'=v1000.1 then /'_SUBJ_',v1000*1/ fi,fi,fi ,), fi,
9600 0 if p(v655) then proc('d1000',(,'a1000¦',replace(v655*3,'^','¦a1000¦'),'¦','a1000¦##¦',), ), ,(,if v1000 = '##' then / else if not '235689': v1000.1 then '~'v1000*1, else if '9'=v1000.1 then /'_SUBJ_',v1000*1/ fi,fi,fi ,), fi,
9600 0 if p(v656) then proc('d1000',(,'a1000¦',replace(v656*3,'^','¦a1000¦'),'¦','a1000¦##¦',), ), ,(,if v1000 = '##' then / else if not '23689' : v1000.1 then '~'v1000*1, else if '9'=v1000.1 then /'_SUBJ_',v1000*1/ fi,fi,fi ,), fi,

0000 0 /* --- Palabras individuales (subcampos seleccionados) --- */
9604 4 if p(v600) then proc('d1000',(,'a1000¦',replace(v600*3,'^','¦a1000¦'),'¦','a1000¦##¦',), ), ,(,if v1000 = '##' then / else if not '234689': v1000.1 then '~'v1000*1, fi,fi ,), fi,
9604 4 if p(v610) then proc('d1000',(,'a1000¦',replace(v610*3,'^','¦a1000¦'),'¦','a1000¦##¦',), ), ,(,if v1000 = '##' then / else if not '234689': v1000.1 then '~'v1000*1, fi,fi ,), fi,
9604 4 if p(v611) then proc('d1000',(,'a1000¦',replace(v611*3,'^','¦a1000¦'),'¦','a1000¦##¦',), ), ,(,if v1000 = '##' then / else if not '234689': v1000.1 then '~'v1000*1, fi,fi ,), fi,
9604 4 if p(v630) then proc('d1000',(,'a1000¦',replace(v630*3,'^','¦a1000¦'),'¦','a1000¦##¦',), ), ,(,if v1000 = '##' then / else if not '23689' : v1000.1 then '~'v1000*1, fi,fi ,), fi,
9604 4 if p(v650) then proc('d1000',(,'a1000¦',replace(v650*3,'^','¦a1000¦'),'¦','a1000¦##¦',), ), ,(,if v1000 = '##' then / else if not '23689' : v1000.1 then '~'v1000*1, fi,fi ,), fi,
9604 4 if p(v651) then proc('d1000',(,'a1000¦',replace(v651*3,'^','¦a1000¦'),'¦','a1000¦##¦',), ), ,(,if v1000 = '##' then / else if not '23689' : v1000.1 then '~'v1000*1, fi,fi ,), fi,
9604 4 if p(v653) then proc('d1000',(,'a1000¦',replace(v653*3,'^','¦a1000¦'),'¦','a1000¦##¦',), ), ,(,if v1000 = '##' then / else if not '9'     : v1000.1 then '~'v1000*1, fi,fi ,), fi,
9604 4 if p(v655) then proc('d1000',(,'a1000¦',replace(v655*3,'^','¦a1000¦'),'¦','a1000¦##¦',), ), ,(,if v1000 = '##' then / else if not '235689': v1000.1 then '~'v1000*1, fi,fi ,), fi,
9604 4 if p(v656) then proc('d1000',(,'a1000¦',replace(v656*3,'^','¦a1000¦'),'¦','a1000¦##¦',), ), ,(,if v1000 = '##' then / else if not '23689' : v1000.1 then '~'v1000*1, fi,fi ,), fi,

0000 0 /* --- Códigos de clasificación --- */
9080 0 if p(v080) then ('-CDU=',v080^a/) fi
9082 0 if p(v082) then ('-DEWEY=',v082^a.3,"."v082^a*3/) fi
0000 0 /* Para los códigos MSC, necesitamos separarlos si aparecen varios juntos, e.g. "12A05 (12-01 16B40)" */
9084 0 if s(mpu,v084^2) : 'MSC' or v084^2 : 'MR' then proc('d1000', ( 'a1000@',replace(replace(replace(v84^a,')',''),'(',''),' ','@a1000@'),'@' ) ), ('-MSC=',v1000/), fi,

0000 0 /* ================================================= */
0000 0 /* Algunas notas */
0000 0 /* ================================================= */
9504 4 /* 500 */ (v500^a/)
9504 4 /* 505 */ proc('d1000a1000¦',v505*2,'¦'), proc('d1000a1000¦',replace(v1000,'^','¦a1000¦'),'¦'), ( if 'ar' : v1000.1 then v1000*1/ fi ) /* sólo $a y $r; el $t va con los títulos */
9504 4 /* 520 */ (v520^a/)

0000 0 /* ================================================= */
0000 0 /* Mención de responsabilidad */
0000 0 /* (parece conveniente para recuperar, p.ej., por nombres que no generan puntos de acceso) */
0000 0 /* ================================================= */
9245 4 v245^c

0000 0 /* ================================================= */
0000 0 /* Algunos campos locales */
0000 0 /* ================================================= */
9859 0 if p(v859) then ( '-INV=',v859^p/, '-ST=', if v859^k <> '' then v859^k,' ', fi, v859^h, if v859^i <> '' then ' ',v859^i, fi / ) fi 
9859 0 if nocc(v859) > 1 then '-MULTIEJEMPLAR' fi
9980 0 if p(v980^d) then '-ANOTACION-DESCR' fi
9980 0 if p(v980^a) then '-ANOTACION-ACCESO' fi
9980 0 if p(v980^s) then '-ANOTACION-TEMA' fi
9980 0 if p(v980^o) or (p(v980) and not v980 : '^') then '-ANOTACION-OTRA' fi
9991 0 '-CREADO_POR=',v991


0000 0 /* La siguiente línea permite resolver el error de la 2da grabación en Catalis */
0000 0 proc('d1000')
