// -----------------------------------------------------------------------------
function getMaterialType(leader06,leader07)
// Cómo interpretar las posiciones 18-34 del campo 008, en base a los valores 
// LDR/O6 y LDR/07.
// Llamada desde Catalis y desde el OPAC, pues la necesitamos en marc2aacr().

// Documentación:
// http://www.loc.gov/marc/formatintegration.html
// http://www.oclc.org/bibformats/en/introduction/default.shtm
// http://www.loc.gov/marc/marbi/2002/2002-dp02.html

// (c) 2003-2004  Fernando J. Gómez - CONICET - INMABB
// -----------------------------------------------------------------------------
{
	// (v906='a' and not 'b~s':v907) or v906='t' --> BK
	// [pft]else if 'c~d~i~j':v906 then[/pft] --> MU
	// [pft]else if v906='m' then[/pft] --> CF
	// [pft]else if 'g~k~o~r' : v906 then[/pft] --> VM
	// [pft]else if v906='a' and 'b~s':v907 then[/pft] --> CR
	// [pft]else if 'e~f' : v906 then[/pft] --> MP
	
	var materialType;
	
	if ( ( leader06.search(/[at]/) != -1 && leader07.search(/[bis]/) == -1) )
		materialType = "BK";   // BK = books (also manuscripts)
	else if ( "a" == leader06 && leader07.search(/[bis]/) != -1 )
		materialType = "CR";   // CR = continuing resource / serial
	else if ( leader06.search(/[cdij]/) != -1 )
		materialType = "MU";   // MU = music (scores & recordings) & nonmusical sound recording
	else if ( leader06.search(/[ef]/) != -1 )
		materialType = "MP";   // MP = maps
	else if ( leader06.search(/[gkor]/) != -1 )
		materialType = "VM";   // VM = visual materials
	else if ( leader06.search(/m/) != -1 )
		materialType = "CF";   // CF = computer files
	else if ( leader06.search(/p/) != -1 )
		materialType = "MIX";  // MIX = mixed materials
	else
		materialType = "??";
	
	return materialType;
}
