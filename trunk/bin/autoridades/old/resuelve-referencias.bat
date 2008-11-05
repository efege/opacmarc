:: Script para resolver las referencias a los registros de la base de
:: autoridades
::
:: $1: nombre de la base bibliográfica
:: $2: nombre de la base de autoridades

set _BIBLIO=%1
set _AUTO=%2

mx %1 "proc=if p(v100^0) then fi" copy=%1 now -all

i2id %1 > %1.id
mx seq=%1.id lw=8000 create=%1-campos now -all
mx %1-campos "fst=1 0 v1^0" fullinv=%1-ref now -all

:: mx %1-campos lw=8000 "pft=ref(['%2']l(['%2'] '-CN=', v1^0), v999)"

::
mx %1-campos "proc=@reemplaza-puntero.pft" lw=8000 "pft=putenv('TARGET=',ref(['%2']l(['%2'] '-CN=', v1^0), v999)), if getenv('TARGET') <> '0' then 'mfn=', mfn(0), x4, '$target=|', getenv('TARGET'), '|', x5, replace(v1,s('^0',v1^0),s('^0', getenv('TARGET'))), /, fi, x2, 'Resultado_ref= |', ref(['%2']l(['%2'] '-CN=', v1^0), v999), '|', /" copy=%1-campos now -all tell=100 > salida-reemplazo.txt

::
mx %1-campos lw=8000 "pft=v1, /" now > %1-campos.id
::
id2i %1-campos.id create=%1-new
