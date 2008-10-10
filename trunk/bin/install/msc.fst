1 0 "-MSC:"v1
1 0 v1
2 4 if v1*3.2 <> '99' then v2 fi  /* palabras de la descripcion, excepto "None of the above, but in this section" */
3 0 if v1*3.2 = 'xx' then '-MSC:NI:2' else if v1*2.3 = '-XX' then '-MSC:NI:1' else '-MSC:NI:3' fi,fi
3 0 if v1*2.1 = '-' and not v1 : '-XX' then '-MSC:NI:2' fi
3 0 if '15A~41A~43A~44A~85A~86A' : v1.3 then '-MSC:NI:2' fi
9 0 if p(v9) then '-MSC:NI:2' fi
