// -----------------------------------------------------------------------------
function arabic2Roman(arabic)
// C�digo tomado de http://www.roman-britain.org/a2r.htm
// -----------------------------------------------------------------------------
{
/* Note: this function requires custom style-sheet values for <SPAN> */
/* fncArabic2Roman variables */
	var RomanI = new Array("","I","II","III","IV","V","VI","VII","VIII","IX");
	var RomanX = new Array("","X","XX","XXX","XL","L","LX","LXX","LXXX","XC");
	var RomanC = new Array("","C","CC","CCC","CD","D","DC","DCC","DCCC","CM");
	var RomanM = new Array("","M","MM","MMM","<SPAN>IV</SPAN>","<SPAN>V</SPAN>","<SPAN>VI</SPAN>","<SPAN>VII</SPAN>","<SPAN>VIII</SPAN>","<SPAN>IX</SPAN>");
	var arabicString = new String(arabic);
	var romanString = new String("");
	var aLen = arabicString.length;
	var n = 1;
	while (n <= aLen) {
		var i = aLen - n;
		var s = parseInt(arabicString.charAt(i));
		if (n == 1) { romanString = RomanI[s]; }
		if (n == 2) { romanString = RomanX[s]+romanString; }
		if (n == 3) { romanString = RomanC[s]+romanString; }
		if (n == 4) { romanString = RomanM[s]+romanString; }
		n++;
	}
	return romanString;
}


// -----------------------------------------------------------------------------
function extractSubfield(field,sfCode)
//	Extracci�n de un subcampo. Por ejemplo,
//		extractSubfield(fields_byTag["856"][0],"u")
//	equivale a lo que en ISIS ser�a
//		v856^u[1]
//
//	TO-DO: usar el tag y la ocurrencia del campo como par�metros.
// -----------------------------------------------------------------------------
{
	var theSubfield = "";
	// ATENCION: 2004/03/08  split(/\^(?=\w)/) --> split(/\^/) por compatib. con IE 5.0
	var tmpSubfields = field.substr(3).split(/\^/);  // Moz-safe-split
	for (var i=0; i < tmpSubfields.length; i++) {
		if ( tmpSubfields[i].substr(0,1) == sfCode ) {
			theSubfield = tmpSubfields[i].substr(1);
			break;
		}
	}
	return theSubfield;
}


// -----------------------------------------------------------------------------
function fieldHighlight(tag,className) {
// TO-DO: eliminar espacio en blanco que queda cuando className es vac�o.
// -----------------------------------------------------------------------------
	var myString = "";
	if ( AACR_FIELD_HL ) {
		myString += " title='Campo " + tag + "'";
		myString += " onmouseover='this.className=\"" + className + " aacrHighlight\"'";
		myString += " onmouseout='this.className=\"" + className + " aacrLowlight\"'";
	}
	return myString;
}


// -----------------------------------------------------------------------------
function newNote(tag)
// C�digo HTML para cerrar un p�rrafo de nota y abrir uno nuevo.
// -----------------------------------------------------------------------------
{
	return "</div>\n<div class='aacrNote aacrLowlight'" + fieldHighlight(tag,"aacrNote") + ">";
}


//--------------------------------------------------------
function sortEjemplares(ej1,ej2)
//--------------------------------------------------------
{
	if ( ej1["3"] && ej2["3"] && ej1["3"] < ej2["3"] )
		return -1;
	if ( ej1["3"] && ej2["3"] && ej1["3"] > ej2["3"] )
		return 1;
	// A igual parte, ordenamos por n�mero de ejemplar
	var n1 = ej1["t"] ? ej1["t"].replace(/\D/g,"") : "";
	var n2 = ej2["t"] ? ej2["t"].replace(/\D/g,"") : "";
	return n1 - n2;
}


// -----------------------------------------------------------------------------
function printCallNumber(ejemplar)
// Devuelve la signatura topogr�fica correspondiente a 'ejemplar'.
// -----------------------------------------------------------------------------
{
	var callNumber = "";
	if ( ejemplar["k"] ) {
		callNumber += ejemplar["k"] + "<br>";
	}
	if ( ejemplar["h"] ) {
		callNumber += ejemplar["h"] + "<br>";
	}
	if ( ejemplar["i"] ) {
		callNumber += ejemplar["i"].replace(/\s+/g,"<br>") + "<br>";
	}
	callNumber += "<br style='line-height: 0.7em;'>";
	return callNumber;
}


// -----------------------------------------------------------------------------
function marc2aacr(materialType,f001,f005,f008,marcDatafields,ejemplares)
//	Input:  marcDatafields: array con un campo de datos MARC por elemento.
//	Output: String con el asiento AACR2 correspondiente.
//
//  Los campos de control 001 y 008 se usan, respectivamente, para mostrar
//  el n�mero de registro y para mostrar la frecuencia de una publicaci�n
//  seriada cuando no hay campo 310.
//
//	(c) 2003-2004  Fernando J. G�mez - CONICET - INMABB
// -----------------------------------------------------------------------------
{
	// TO-DO: �registrar los onmouseover & onmouseout v�a JavaScript, sin usar
	// atributos HTML? Considerar *opcional* el resaltado onmouseover.
	
	if ( "undefined" == typeof(MAIN_ENTRY_TOP) ) {
		MAIN_ENTRY_TOP = false;
	}
	
	// �Mostramos la signatura topogr�fica en la ficha?
	var DISPLAY_CALL_NUMBER = true;

	var REGEX_SUBDIV = /\^a|\^x|\^y|\^z|\^v/g;				// subdiv. en campos 6xx; ^a puede aparecer en 653
	var REGEX_CTRL_SF = /\^4\w\w\w|\^5\w+|\^6[^\^]+|\^8/g;	// subcampos de control (o m�s bien, num�ricos), que no se visualizan. TO-DO: revisar (�ponemos el ^9? �el ^4?).
	var NEW_NOTE = "</div><div class='aacrNote'>";

	// Separador de �reas. Son equivalentes: &mdash; &#8212; &#x2014; \u2014
	// ATENCION: de acuerdo con OCLC, el separador debe usarse s�lo cuando el
	// c�digo Desc (Leader/18) es "a" o "i". V�ase http://www.oclc.org/bibformats/en/fixedfield/desc.shtm
	var LONG_DASH = "<span class='mdash'>&mdash;</span>";

	var INDENT_SPACE = "   ";//"   ";
	var REGEX_INDENT = new RegExp(INDENT_SPACE,"g");

	// El uso de espacios para la indentaci�n, y de "\r\n", se debe a que
	// queremos poder copiar el innerText de la ventana con la ficha, y pegarlo
	// en un procesador de texto, preservando tanto como sea posible el formato
	// visual.

	// Aqu� almacenamos el texto (HTML) que va siendo generando.
	// TO-DO: �usar m�todos DOM en lugar de un string HTML?
	var description = "";
	var tracing = "";

	// fields_byTag es un array donde se almacenan los campos de datos,
	// agrupando las ocurrencias de un mismo tag (y por lo tanto, alterando
	// posiblemente el orden original).
	var fields_byTag = new Array();
	for (var i=0; i < marcDatafields.length; i++) {
		var tag = marcDatafields[i].substr(0,3);
		if ( !fields_byTag[tag] ) {
			fields_byTag[tag] = new Array();
		}
		//fields_byTag[tag].push(marcDatafields[i].substr(4)); // push no funciona en IE < 5.5
		fields_byTag[tag][fields_byTag[tag].length] = marcDatafields[i].substr(4);
	}

	// fields_inOrder es un array donde se almacenan los campos de datos,
	// preservando el orden original (i.e., independientemente de los tags)
	var fields_inOrder = new Array();
	for (var i=0; i < marcDatafields.length; i++) {
		var fieldOcc = new Array();
		fieldOcc.tag = marcDatafields[i].substr(0,3);
		fieldOcc.value = marcDatafields[i].substr(4);
		//fields_inOrder.push(fieldOcc); // push() no funciona en IE < 5.5
		fields_inOrder[fields_inOrder.length] = fieldOcc;
	}


	// ---------------------------------------------------------
	// Campos 1xx: main entry heading
	// ---------------------------------------------------------
	var mainEntryTag = "";
	if ( fields_byTag["100"] ) {
		mainEntryTag = "100";
	} else if ( fields_byTag["110"] ) {
		mainEntryTag = "110";
	} else if ( fields_byTag["111"] ) {
		mainEntryTag = "111";
	} else if ( fields_byTag["130"] ) {
		mainEntryTag = "130";
	}

	if ( "" != mainEntryTag ) {
		var mainEntryHeading = fields_byTag[mainEntryTag][0].replace(REGEX_CTRL_SF,"").substr(4).replace(/\^9.+$/,"").replace(/\^\w/g," ");
		if ( MAIN_ENTRY_TOP ) {
			description += "<div id='mainEntryHeading'" + fieldHighlight(mainEntryTag) + ">";
			description += mainEntryHeading;
			description += "</div>\n\n";
		}
	} else if (MAIN_ENTRY_TOP && GHOST_MAIN_ENTRY) {    // Agregado para Museo Mitre, 2008-03-12
        description += "<div id='mainEntryHeading'>";
        description += "&nbsp;";
        description += "</div>\n\n";
    }


	/*if ( fields_byTag["100"] || fields_byTag["110"] || fields_byTag["111"] || fields_byTag["130"] )
	{
		description += "\r\n";
	}*/


	// ---------------------------------------------------------
	// Campo 240 (t�tulo uniforme)
	// ATENCION: Dado que el t�tulo uniforme cumple una funci�n relacionada
	// con el *acceso*, quiz�s debamos (en una visualizaci�n opcional que no destaca
	// el main entry) generar un punto de acceso por nombre/t�tulo (1xx/240).
	// ---------------------------------------------------------
	if ( fields_byTag["240"] && "1" == fields_byTag["240"][0].substr(0,1) && MAIN_ENTRY_TOP ) {
		description += "<div id='uniformTitle'" + fieldHighlight("240") + ">";
		description += INDENT_SPACE + "[" + fields_byTag["240"][0].replace(REGEX_CTRL_SF,"").substr(4).replace(/\^\w/g," ") + "]";
		description += "</div>\n\n";
	}


	// -------------------------------------------------------------
	// Begin bibliographic description
	// -------------------------------------------------------------

	description += "<div id='Description' " + (("" != mainEntryTag && MAIN_ENTRY_TOP) ? " class='mainEntryTop'" : "") + ">\n";

	// ---------------------------------------------------------
	// Campo 245
	// ---------------------------------------------------------
	description += "<div id='aacrTitleParagraph'>";
	if ( fields_byTag["245"] ) {
		description += "<span " + fieldHighlight("245") + ">";
		description += INDENT_SPACE + fields_byTag["245"][0].replace(REGEX_CTRL_SF,"").substr(4).replace(/\^\w/g," ");
		description += "</span>";
	}

	if ( fields_byTag["250"] ) {
		description += " " + LONG_DASH + " ";
		description += "<span " + fieldHighlight("250") + ">";
		description += fields_byTag["250"][0].substr(4).replace(/\^\w/g," ");
		description += "</span>";
	}

	// ----------------------------------------------------------
	// 362 - Dates of publication and/or sequential designation
	// OCLC: If field 362 begins with a hyphen, the print program supplies three spaces preceding the hyphen.
	// If field 362 ends with a hyphen, the print program supplies three spaces after the hyphen.
	// ----------------------------------------------------------
	if ( fields_byTag["362"] && "0" == fields_byTag["362"][0].substr(0,1) ) {
		//TO-DO: es Repetible
		description += " " + LONG_DASH + " ";
		description += "<span " + fieldHighlight("362") + ">";
		description += fields_byTag["362"][0].substr(4).replace(/\^\w/g," ").replace(/-$/,"-&nbsp;&nbsp;&nbsp;&nbsp;").replace(/^-/,"&nbsp;&nbsp;&nbsp;&nbsp;-");
		description += "</span>";
		description += ".";
	}

	if ( fields_byTag["254"] ) {
		description += " " + LONG_DASH + " ";
		description += "<span " + fieldHighlight("254") + ">";
		description += fields_byTag["254"][0].substr(4).replace(/\^\w/g," ");
		description += "</span>";
	}

	if ( fields_byTag["255"] ) {   // TO-DO: Repetible
		description += " " + LONG_DASH + " ";
		description += "<span " + fieldHighlight("255") + ">";
		description += fields_byTag["255"][0].substr(4).replace(/\^\w/g," ");
		description += "</span>";
	}

	if ( fields_byTag["256"] ) {
		description += " " + LONG_DASH + " ";
		description += "<span " + fieldHighlight("256") + ">";
		description += fields_byTag["256"][0].substr(4).replace(/\^\w/g," ");
		description += "</span>";
	}

	if ( fields_byTag["260"] ) {   // TO-DO: Repetible
		description += " " + LONG_DASH + " ";
		description += "<span" + fieldHighlight("260") + ">";
		description += fields_byTag["260"][0].substr(4).replace(/\^\w/g," ");
		description += "</span>";
	}
	
	
	
	if ( !fields_byTag["300"] && fields_byTag["773"] ) {
		description += "</div>";
	}

	// ---------------------------------------------------------------------------
	// Descripci�n f�sica
	// TO-DO: campo 300 es repetible
	// ---------------------------------------------------------------------------
	if ( fields_byTag["300"] ) {
		if ( fields_byTag["773"] ) {   // ATENCION: �miramos 773 o leader/07?
			description += " " + LONG_DASH + " ";
		}
		else {
			description += "</div>"   // cierra el titleParagraph para no-anal�ticas
			description += "<div id='aacrPhysDescParagraph'>"
			description += INDENT_SPACE;
		}
		description += "<span " + fieldHighlight("300") + ">";
		
		// OCLC: [BKS, SER, VIS, MAP, REC, SCO, COM] The print program provides three
		// leading spaces if subfield �a does not contain a number.
		var subfield_a = extractSubfield(fields_byTag["300"][0],"a");
		if ( subfield_a != "" && subfield_a.replace(/\D/g,"") == "" ) {
			description += "&nbsp;&nbsp;&nbsp;";
		}
		description += fields_byTag["300"][0].substr(4).replace(/\^\w/g," "); // 300$3 se deja como viene
		description += "</span>";
		if ( fields_byTag["773"] ) {
			description += "</div>";   // cierra el titleParagraph para anal�ticas
		}
		
		//description += (fields_byTag["773"]) ? " \u2014 " : "\r\n" + INDENT_SPACE;
		/*
		if (fields_byTag["300"][0].search(/\^a\d|\^ai|\^av|\^ax|\^al/i) == -1)
		{
			// TO-DO: mejorar esta expresi�n regular para detectar "n�meros"
			description += INDENT_SPACE;
		}
		*/
	}
	

	// ---------------------------------------------------------------------------
	// Serie (campos 4xx, en orden de aparici�n)
	// ---------------------------------------------------------------------------
	if ( fields_byTag["440"] || fields_byTag["490"] ) {
		description += " " + LONG_DASH;
	}

	for (var i=0; i < fields_inOrder.length; i++)  {
		var tag = fields_inOrder[i].tag;
		if ( tag.substr(0,1) == "4" ) {
			description += " (";
			description += "<span " + fieldHighlight(tag) + ">";
			description += fields_inOrder[i].value.replace(/\^x/," ISSN^x").replace(REGEX_CTRL_SF,"").substr(4).replace(/\^\w/g," ");
			description += "</span>";
			description += ")";
		}
	}

	if ( !fields_byTag["773"] ) {
		description += "</div>\n";  // cierra el physDescParagraph para no-anal�ticas
	}


	// ---------------------------------------------------------------------------
	// NOTAS: campos 5xx, m�s algunos otros.
	// Ver http://www.oclc.org/bibformats/en/5xx/ para el orden de impresi�n
	// sugerido por OCLC.
	// ---------------------------------------------------------------------------

	description += "<div id='aacrNotesParagraphs'>";
	description += "<div class='_aacrNote'>";  // para abrir la 1ra nota (�a�n es necesario? Parece que s�, en base a la definici�n de NEW_NOTE)


	// ---------------------------------------------------------------------------
	// Campo 773: "In" analytics
	// TO-DO: si hay subcampo $w, �tenemos que solicitar los datos del host al
	// servidor?
	// ---------------------------------------------------------------------------
	if ( fields_byTag["773"] && fields_byTag["773"][0].substr(0,1) == "0" ) {
		// TO-DO: 773 es repetible
		description += newNote("773") + INDENT_SPACE + "<span class='displayConstant'>En:</span> ";
		var subfieldArray = fields_byTag["773"][0].substr(3).split(/\^/);
		
		// Averiguamos posici�n del subcampo $t
		var tPosition = -1;
		for (var i=0; i < subfieldArray.length; i++) {
			var code = subfieldArray[i].substr(0,1);
			if ( "t" == code ) {
				tPosition = i; break;
			}
		}
		// Presentamos los subcampos
		for (var i=0; i < subfieldArray.length; i++) {
			var code = subfieldArray[i].substr(0,1);
			if ( code.search(/[hmnruwyz7]/) == -1 ) {
				if ( tPosition > -1 && i > tPosition ) {
					description += LONG_DASH + " ";
				}
				if ( "z" == code ) {
					description += "ISBN ";
				} else if ( "x" == code ) {
					description += "ISSN ";
				}
				description += subfieldArray[i].substr(1) + " ";
			}
		}
	}
	

	// ----------------------------------------------------------
	// 310 - Current publication frequency 
	// 321 - Former publication frequency
	// ----------------------------------------------------------
	// OCLC a�ade par�ntesis alrededor de las fechas en el subcampo $b del 310 y del 321: replace(/\^b(.+)/,"^b($1)")
	
	if ( fields_byTag["321"] || fields_byTag["310"] ) {
		description += newNote("321 y/o 310") + INDENT_SPACE;
		
		if ( fields_byTag["321"] ) {
			for (var i=0; i < fields_byTag["321"].length; i++) {
				if ( i > 0 ) description += "; ";
				description += fields_byTag["321"][i].substr(4).replace(/-$/,"-&nbsp;&nbsp;&nbsp;").replace(/\^\w/g," ");
			}
		}
		
		if ( fields_byTag["310"] ) {
			if ( fields_byTag["321"] ) description += "; ";
			description += fields_byTag["310"][0].substr(4).replace(/-$/,"-&nbsp;&nbsp;&nbsp;").replace(/\^\w/g," ");
		}
		
		if ( description.charAt(description.length - 1).search(/\.|!|\?/) == -1 ) {
			description += ".";
		}
	}

	// OCLC: If a record has no 310 field, the print program supplies a frequency
	// note based on the Freq code. (006/01 ??)
	if ( "CR" == materialType && !fields_byTag["310"] ) {
		var Freq = f008.substr(18,1);
		var frequency = "";
		switch ( Freq ) {
			case "#" : frequency = "Irregular"; break;
			case "a" : frequency = "Annual"; break;
			case "b" : frequency = "Bimonthly"; break;
			case "c" : frequency = "Semiweekly"; break;
			case "d" : frequency = "Daily"; break;
			case "e" : frequency = "Biweekly"; break;
			case "f" : frequency = "Semiannual"; break;
			case "g" : frequency = "Biennial"; break;
			case "h" : frequency = "Triennial"; break;
			case "i" : frequency = "Three times a week"; break;
			case "j" : frequency = "Three times a month"; break;
			case "m" : frequency = "Monthly"; break;
			case "q" : frequency = "Quarterly"; break;
			case "s" : frequency = "Semimonthly"; break;
			case "t" : frequency = "Three times a year"; break;
			case "w" : frequency = "Weekly"; break;
			// If you use u or z, no frequency note prints.
		}
		if ( frequency != "" ) {
			description += newNote("008/18") + INDENT_SPACE;
			description += frequency + "."; 
		}
	}
	

	// ----------------------------------------------------------
	// 362 - Dates of publication and/or sequential designation
	// ----------------------------------------------------------
	// OCLC: If the 1st indicator value is 1, field 362 prints as a note.
	// Print following the frequency note (Freq or fields 310 and 321).
	// If there is no frequency note, field 362 prints as the first note.
	if ( fields_byTag["362"] && "1" == fields_byTag["362"][0].substr(0,1) ) {
		description += newNote("362") + INDENT_SPACE;
		description += fields_byTag["362"][0].substr(4).replace(/\^\w/g," ").replace(/-$/,"-&nbsp;&nbsp;&nbsp;&nbsp;").replace(/^-/,"&nbsp;&nbsp;&nbsp;&nbsp;-");
		//description += "."; (se supone que el punto es parte del campo cuando va como nota)
	}
	
	
	// ---------------------------------------------------------------------------
	// Campo 246: Notas de variantes de t�tulo
	// Las traducciones al espa�ol de las display constants est�n tomadas de la
	// edici�n colombiana de las Reglas.
	// TO-DO: si hay m�s de un 246, agruparlos en base al valor del 2do indicador
	// (ver OCLC). Encabezan la lista ind2 = 0, seguido por ind2 = 1.
	// ---------------------------------------------------------------------------
	
	if ( fields_byTag["246"] ) {
		for (var i=0; i < fields_byTag["246"].length; i++) {
			//if (fields_byTag["246"][i].substr(0,1).search(/[01]/) != -1 && fields_byTag["246"][i].substr(1,1).search(/[#2345678]/) != -1)
			if ( fields_byTag["246"][i].substr(0,2).search(/[01][#2-8]/) != -1 ) {
				description += newNote("246") + INDENT_SPACE;
				var displayConstant = "";
				switch ( fields_byTag["246"][i].substr(1,1) ) {  // 2nd indicator
					case "2" :
						displayConstant = "Distinctive title: ";  // Distinctive title
						break;
					case "3" :
						displayConstant = "Otro t�tulo: ";  // Other title
						break;
					case "4" :
						displayConstant = "T�tulo de la cubierta: ";  // Cover title
						break;
					case "5" :
						displayConstant = "T�tulo de la portada adicional: ";  // Added title page title
						break;
					case "6" :
						displayConstant = "T�tulo de partida: ";  // Caption title
						break;
					case "7" :
						displayConstant = "Titulillo: ";  // Running title
						break;
					case "8" :
						displayConstant = "T�tulo del lomo: ";  // Spine title
						break;
				}
				description += "<span class='displayConstant'>" + displayConstant + "</span>";
				// TO-DO: subcampo $i en italics
				description += fields_byTag["246"][i].replace(/\^[g5][^\^]+/g,"").replace(/\^f/,", ").replace(/\^i([^\^]+)/,"^i<span class='displayConstant'>$1</span>").substr(4).replace(/\^\w/g," ");
				
				if ( description.charAt(description.length - 1).search(/[-\.!\?]/) == -1 ) {
					description += ".";
				}
			}
		}
	}

	// Field 247 Former title - Second indicator must be 0
	// OCLC: Subfields �g and �x do not print.
	if ( fields_byTag["247"] && "0" == fields_byTag["247"][0].substr(1,1) ) {
		description += newNote("247") + INDENT_SPACE;
		description += "<span class='displayConstant'>" + "T�tulo var�a: " + "</span>";
		description += fields_byTag["247"][0].substr(4).replace(/\^f/,",^f").replace(/\^\w/g," ");
		if ( description.charAt(description.length - 1) != "-" ) {
			description += ".";
		}
	}
	
	// Field 028 Publisher number - First indicator must be 0 or 1, Second indicator must be 1 or 2
	
	// Field 307 Hours, etc.
	
	// ---------------------------------------------------------------------------
	// Campos 5xx, en orden de aparici�n (recorremos todos los campos, y
	// tomamos s�lo los 5xx).
	// ---------------------------------------------------------------------------
	for (var i=0; i < fields_inOrder.length; i++)  {
		if ( fields_inOrder[i].tag.substr(0,1) == "5" ) {
			var tag = fields_inOrder[i].tag;
			description += newNote(tag) + INDENT_SPACE;
			var displayConstant = "";
			
			// Casos especiales: pueden llevar una display constant controlada
			// desde un indicador.
			switch (tag) {
				
				case "505" :   // Formatted contents note
					// TO-DO: uso de m�s de un 505
					var ind1 = fields_inOrder[i].value.substr(0,1);
					switch ( ind1 ) {
						case "0" :
							displayConstant = "Contenido: "; // Contents
							break;
						case "1" :
							displayConstant = "Contenido incompleto: "; // Incomplete contents (OCLC muestra 'Contents:')
							break;
						case "2" :
							displayConstant = "Contenido parcial: "; // Partial contents
							break;
					}
					// TO-DO: concatenar campos 505 si hay m�s de uno (?)
					break;
				
				case "508" :   // Creation/production credits note
					displayConstant = "Cr�ditos: "; // Credits
					break;
				
				case "510" :   // Citation/references note
					// TO-DO: ver indicaciones de OCLC para cuando hay varios 510.
					// Duda: indizado o indexado?
					var ind1 = fields_inOrder[i].value.substr(0,1);
					switch ( ind1 ) {
						case "0" :
							displayConstant = "Indizado por: "; // Indexed by
							break;
						case "1" :
							displayConstant = "Indizado en su totalidad por: "; // Indexed in its entirety by
							break;
						case "2" :
							displayConstant = "Indizado selectivamente por: "; // Indexed selectively by
							break;
						case "3" :
						case "4" :
							displayConstant = ( "bibima" == g_databases._activeDB_ ) ? "Rese�a: " : "Referencias: "; // References
							break;
					}
					break;
				
				case "511" :   // Participant or performer note
					// ATENCION: en OCLC, tambi�n se tiene en cuenta el valor de Leader/06 (type of record),
					// de modo que Leader/06 = j (Musical sound recording) --> No print constant
					var ind1 = fields_inOrder[i].value.substr(0,1);
					switch ( ind1 ) {
						case "1" :
							displayConstant = "Elenco: "; // Cast
							break;
					}
					break;
				
				case "516" :   // Type of computer file or data note
					// OCLC: does not print.
					var ind1 = fields_inOrder[i].value.substr(0,1);
					switch ( ind1 ) {
						case "#" :
							displayConstant = "Tipo de archivo: "; // Type of file
							break;
					}
					break;
				
				case "520" :   // Summary, etc.
					// TO-DO: uso de m�s de un 505
					var ind1 = fields_inOrder[i].value.substr(0,1);
					switch ( ind1 ) {
						case "#" :
							displayConstant = "Resumen: "; // Summary
							break;
						case "0" :
							displayConstant = "Subject: "; // Subject
							break;
						case "1" :
							displayConstant = "Rese�a: "; // Review
							break;
						case "2" :
							displayConstant = "Scope and content: "; // Scope and content
							break;
						case "3" :
							displayConstant = "Abstract: "; // Abstract
							break;
					}
					break;
				
				case "521" :   // Target audience note
					var ind1 = fields_inOrder[i].value.substr(0,1);
					switch ( ind1 ) {
						case "#" :
							displayConstant = "Audience: ";
							break;
						case "0" :
							displayConstant = "Reading grade level: ";
							break;
						case "1" :
							displayConstant = "Interest age level: ";
							break;
						case "2" :
							displayConstant = "Interest grade level: ";
							break;
						case "3" :
							displayConstant = "Special audience characteristics: ";
							break;
						case "4" :
							displayConstant = "Motivation/interest level: ";
							break;
					}
					break;
				
				case "522" :   // Geographic coverage note
					var ind1 = fields_inOrder[i].value.substr(0,1);
					switch ( ind1 ) {
						case "#" :
							displayConstant = "Cobertura geogr�fica: "; // Geographic coverage
							break;
					}
					break;
				
				case "524" :   // Preferred citation of described materials note
					// OCLC: does not print.
					var ind1 = fields_inOrder[i].value.substr(0,1);
					switch ( ind1 ) {
						case "#" :
							displayConstant = "Citar como: "; // Cite as
							break;
					}
					break;
				
				case "526" :   // Study program information note
					var ind1 = fields_inOrder[i].value.substr(0,1);
					switch ( ind1 ) {
						case "0" :
							displayConstant = "Reading program: "; // Reading program
							break;
					}
					break;
				
				case "555" :   // Cumulative index/finding aids note
					var ind1 = fields_inOrder[i].value.substr(0,1);
					switch ( ind1 ) {
						case "#" :
							displayConstant = "�ndices: "; // Indexes
							break;
						case "0" :
							displayConstant = "Finding aids: "; // Finding aids
							break;
					}
					break;
				
				case "556" :   // Information about documentation note
					var ind1 = fields_inOrder[i].value.substr(0,1);
					switch ( ind1 ) {
						case "#" :
							displayConstant = "Documentaci�n: "; // Documentation
							break;
					}
					break;
				
				case "565" :   // Case file characteristics note
					// OCLC: does not print.
					var ind1 = fields_inOrder[i].value.substr(0,1);
					switch ( ind1 ) {
						case "#" :
							displayConstant = "File size: "; // File size
							break;
						case "0" :
							displayConstant = "Case file characteristics: "; // Case file characteristics
							break;
					}
					break;
				
				case "567" :   // Methodology note
					// OCLC: does not print.
					var ind1 = fields_inOrder[i].value.substr(0,1);
					switch ( ind1 ) {
						case "#" :
							displayConstant = "Metodolog�a: "; // Methodology
							break;
					}
					break;
				
				case "581" :   // Publications about described materials note
					var ind1 = fields_inOrder[i].value.substr(0,1);
					switch ( ind1 ) {
						case "#" :
							displayConstant = "Publicaciones: "; // Publications
							break;
					}
					break;
				
				case "586" :   // Awards note
					var ind1 = fields_inOrder[i].value.substr(0,1);
					switch ( ind1 ) {
						case "#" :
							displayConstant = "Premios: "; // Awards
							break;
					}
					break;
				
				//default : description += fields_inOrder[i].value.substr(4).replace(/\^\w/g," ").replace(/--/g,LONG_DASH);
			}
			
			description += "<span class='displayConstant'>" + displayConstant + "</span>";
			
			// El campo 510 es especial porque queremos usarlo para generar un link
			if ( "510" == tag && "bibima" == g_databases._activeDB_ && extractSubfield(fields_inOrder[i].value,"a").search(/^(Math\. Rev\.|MR),$/) != -1 ) {
				description += "MR, ";
				var reviewNumbers = extractSubfield(fields_inOrder[i].value,"c").split(/,\s/g);
				for ( var j=0; j < reviewNumbers.length; j++ ) {
					if ( j > 0 ) description += ", ";
					var mrURL = "http://www.ams.org/mathscinet-getitem?mr=" + reviewNumbers[j].replace(/\s#/,":");
					description += "<a target='_blank' href='" + mrURL + "' title='Enlace a la rese�a en MathSciNet' onclick='auxWin(this.href); return false'>";
					description += reviewNumbers[j];
					description += "</a>";
				}
				if ( "" != extractSubfield(fields_inOrder[i].value,"3") ) {
					description += " " + extractSubfield(fields_inOrder[i].value,"3");
				}
			} else {
				// Com�n al resto de las notas
				description += fields_inOrder[i].value.substr(4).replace(/\^5.+$/,"").replace(/\^\w/g," ").replace(/--/g, LONG_DASH);
			}
			
			if ( "510" == tag ) {
				// OCLC
				if ( description.charAt(description.length - 1).search(/[\.!\?]/) == -1 ) {
					description += ".";
				}
			}
			
			// ATENCION: el subcampo 504$b no debe mostrarse.
		}
	}


	// ---------------------------------------------------------------------------
	// Campos 76x-78x, en el orden de aparici�n (recorremos todos los campos,
	// y tomamos s�lo los 76x-78x, excepto el 773 que fue tratado m�s arriba).
	// S�lo se genera una nota si el primer indicador vale 0.
	// TO-DO: combinar m�s de una ocurrencia, e.g. del campo 785.
	// ---------------------------------------------------------------------------
	for (var i=0; i < fields_inOrder.length; i++) {
		if ( fields_inOrder[i].tag.substr(0,3).search(/76.|77[^3]|78./) != -1 && "0" == fields_inOrder[i].value.substr(0,1) ) {
			var tag = fields_inOrder[i].tag;
			var displayConstant = "";
			description += newNote(tag) + INDENT_SPACE;
			switch ( tag ) {
				// --------------------------------------------------
				case "765" :
				// --------------------------------------------------
					switch ( fields_inOrder[i].value.substr(1,1) ) {
						case "#" :
							displayConstant = "Traducci�n de: ";
							break;
					}
					break;
				// --------------------------------------------------
				case "772" :
				// --------------------------------------------------
					switch ( fields_inOrder[i].value.substr(1,1) ) {
						case "#" :
							displayConstant = "Suplemento a: ";
							break;
						case "0" :
							displayConstant = "Parent: ";
							break;
					}
					break;
				// --------------------------------------------------
				case "780" :
				// --------------------------------------------------
					switch ( fields_inOrder[i].value.substr(1,1) ) {
						case "0" :
							displayConstant = "Continuaci�n de: ";
							break;
						case "1" :
							displayConstant = "Continuaci�n en parte de: ";
							break;
						// TO-DO: agregar otros casos
					}
					break;
				// --------------------------------------------------
				case "785" :
				// --------------------------------------------------
					switch ( fields_inOrder[i].value.substr(1,1) ) {
						case "0" :
							displayConstant = "Contin�a como: ";
							break;
						case "1" :
							displayConstant = "Contin�a en parte como: ";
							break;
					}
					break;
				/*
				default :
					description += fields_inOrder[i].value.replace(REGEX_CTRL_SF,"").substr(4).replace(/\^\w/g," ");
				*/
			}
			description += "<span class='displayConstant'>" + displayConstant + "</span>";
			description += fields_inOrder[i].value.replace(/\^w[^\^]+/g,"").replace(/\^i([^\^]+)/,"^i<span class='displayConstant'>$1</span>").substr(4).replace(/\^z/g,",^zISBN ").replace(/\^\w/g," ");
			description += ".";
		}
	}

	// Campo 555 ?
	// Campos 027, 028


	// ---------------------------------------------------------
	// ISBN
	// TO-DO: �C�mo presentar los $z : "ISBN (invalid)"?
	//        REVISAR hyphenation.
	//
	// OCLC: If subfield �a is not present, no data from field 020 prints.
	// If an ISBN in subfield �a has fewer or more than ten digits or has a letter
	// other than X as the tenth character, the ISBN does not print. 
	//
	// ATENCION: ver LCCN 81082555 (The Beatles' England): falla canonical_ISBN()
	//               LCCN 94077840 (The day John met Paul)
	//               LCCN 94069318 (Drugs, divorce, and a slipping image)
	// ---------------------------------------------------------
	
	if ( fields_byTag["020"] && fields_byTag["020"].toString().search(/\^a/) != -1 ) {
		
		description += newNote("020") + INDENT_SPACE;
		
		for (var i=0; i < fields_byTag["020"].length; i++) {
			
			if ( fields_byTag["020"][i].search(/\^a/) != -1 ) {
				
				// Separador entre ISBNs
				// ATENCION: se asume que, si alg�n 020 se imprime, entonces
				// fields_byTag["020"][0] se imprime. �Lo modificamos?
				if ( i > 0 ) {
					description += ". " + LONG_DASH + " ";
				}
				
				// Display constant
				description += "ISBN ";
				
				// Extraemos el ISBN tal como est� en el subcampo $a
				// OBSOLETO -- Se us� cuando los ISBN conten�an espacios o guiones
				//var RE_ISBN = /^\d[ -]?\d?[ -]?\d?[ -]?\d?[ -]?\d?[ -]?\d?[ -]?\d?[ -]?\d?[ -]?\d?[ -]?[\dxX]?/;
				//var myISBN = RE_ISBN.exec(fields_byTag["020"][i].substr(4))[0];
				
				var myISBN = fields_byTag["020"][i].substr(4,10);
				
				// Lo "normalizamos"
				var newISBN = canonical_ISBN(myISBN);
				
				// Y sustituimos el ISBN original (eliminando los subcampos $z si los hubiese)
				description += fields_byTag["020"][i].substr(4).replace(/\^z[^\^]+/g,"").replace(myISBN,newISBN).replace(/\^\w/g," ");
			}
		}
	}

	// ---------------------------------------------------------
	// ISSN + Key title (OCLC's last note)
	// TO-DO: c�mo presentar los $y [ISSN (incorrect)], $z [ISSN (canceled)]
	// TO-DO: Revisar en base a lo hecho con el ISBN en 020
	// �Puede haber 222 sin 022 ?
	// ---------------------------------------------------------
	if ( fields_byTag["022"] ) {
		description += newNote("022") + INDENT_SPACE;
		for (var i=0; i < fields_byTag["022"].length; i++) {
			if ( i > 0 ) {
				description += ". " + LONG_DASH + " ";
			}
			description += "ISSN ";
			description += fields_byTag["022"][i].substr(4).replace(/\^\w/g," ");
			if ( fields_byTag["222"] ) {
				description += " = " + fields_byTag["222"][i].substr(4).replace(/\^\w/g," ");
			}
		}
	}

	description += "</div>\n";   // cierra la �ltima nota
	description += "</div>\n";   // cierra notesParagraphs
	//description += "\r\n";


	// -----------------------------------------------------------------------
	// End bibliographic description
	// -----------------------------------------------------------------------
	description += "</div>\n";


	// -----------------------------------------------------------------------
	// TRAZADO: para que salga bien encolumnado, usamos una <table>
	// TO-DO: reescribir el trazado usando dos listas ordenadas <ol>, que
	// es lo sem�nticamente correcto. Eso adem�s permitir� ofrecer como
	// alternativa el display lineal usual en las fichas (para los nost�lgicos).
	// -----------------------------------------------------------------------
	tracing += "<table id='tracings' cellspacing='0' border='0'>\n";
	//tracing += "<div id='tracingDiv'>";
	//tracing += "<ol>";

	// ---------------------------------------------------------------------
	// Puntos de acceso tem�ticos: Campos 6xx, en orden de aparici�n
	// ---------------------------------------------------------------------
	subjCounter = 0;
	for (var i=0; i < fields_inOrder.length; i++) {
		if ( fields_inOrder[i].tag.substr(0,1) == "6" ) {
			var tag = fields_inOrder[i].tag;
			
			subjCounter++;
			//tracing += "\r\n" + INDENT_SPACE + subjCounter + ". ";
			tracing += "<tr><td class='tracingCounter'>" + subjCounter + ".&nbsp;</td>";
			tracing += "<td class='tracingCell aacrLowlight'" + fieldHighlight(tag,"tracingCell") + ">";
			switch ( tag ) {
				// ATENCION: 2004/03/08  replace(/\^2.+(?=\^|$)/,"") => replace(/\^2.+/,"") por compatib. con IE 5.0
				// TO-DO: revisar espacio luego de $y, p.ej. en $y1983-$vPeriodicals
				default : tracing += fields_inOrder[i].value.substr(4).replace(REGEX_SUBDIV,LONG_DASH).replace(/\^2.+/,"").replace(/\^9.+/,"").replace(/\^\w/g," ").replace(/--/g,LONG_DASH).replace("-"+LONG_DASH,"-&nbsp;&nbsp;&nbsp;"+LONG_DASH);
			}
			tracing += "</td></tr>";
			
			//tracing += "<li title='Campo " + tag + "' onmouseover='this.className=\"tracingCell aacrHighlight\"' onmouseout='this.className=\"tracingCell aacrLowlight\"'>";
			//switch ( tag ) {
			//	default : tracing += fields_inOrder[i].value.substr(4).replace(REGEX_SUBDIV,LONG_DASH).replace(/\^2.+(?=\^|$)/,"").replace(/\^\w/g," ");
			//}
			//tracing += "</li>\n";
		}
	}
	
	if ( subjCounter > 0 ) {
		tracing += "<tr><td colspan='2' style='line-height: 4px;'>&nbsp;</td></tr>";
	}
	
	//tracing += "</ol>";
	//tracing += "</div>";

	//tracing += "<table id='tracingTable' cellspacing='0' border='0'>";
	
	// ---------------------------------------------------------
	// A continuaci�n, los puntos de acceso no tem�ticos
	// ---------------------------------------------------------
	nonSubjCounter = 0;

	// -------------------------------------------------------------------
	// Opcionalmente, el primer punto de acceso es el main entry heading
	// (y el segundo, en caso de haber un 240, ser� un acceso por nombre-
	// t�tulo; pero este concepto debe ser REVISADO).
	// -------------------------------------------------------------------
	if ( "" != mainEntryTag && !MAIN_ENTRY_TOP ) {
		nonSubjCounter++;
		tracing += "<tr><td class='tracingCounter'>I.&nbsp;</td>";
		tracing += "<td class='tracingCell aacrLowlight' style='font-style: italic;'" + fieldHighlight(mainEntryTag,"tracingCell") + ">" + mainEntryHeading + "</td></tr>";
		
		if ( fields_byTag["240"] ) {
			nonSubjCounter++;
			tracing += "<tr><td class='tracingCounter'>II.&nbsp;</td>";
			tracing += "<td class='tracingCell aacrLowlight' title='Campos " + mainEntryTag + "-240' onmouseover='this.className=\"tracingCell aacrHighlight\"' onmouseout='this.className=\"tracingCell aacrLowlight\"'>";
			tracing += mainEntryHeading + "&nbsp;&nbsp;" + fields_byTag["240"][0].replace(REGEX_CTRL_SF,"").replace(/\^a([^\^]+)/,"^a<em>$1</em>").substr(4).replace(/\^\w/g," ");
			if ( tracing.charAt(tracing.length - 1).search(/\.|!|\?/) == -1 ) {
				tracing += ".";
			}
			tracing += "</td></tr>";
		}
	}

	// ---------------------------------------------------------
	// Campos 70x-75x, en el orden de aparici�n
	// ---------------------------------------------------------
	for (var i=0; i < fields_inOrder.length; i++) {
		var tag = fields_inOrder[i].tag;
		if ( tag.search(/7[0-5]./) != -1 ) {
			nonSubjCounter++;
			//tracing += "\r\n" + INDENT_SPACE + arabic2Roman(nonSubjCounter) + ". ";
			tracing += "<tr><td class='tracingCounter'>" + arabic2Roman(nonSubjCounter) + ".&nbsp;</td>";
			var tag = fields_inOrder[i].tag;
			switch ( tag ) {
				// ATENCION: REESCRIBIR
				// --------------------------------------------------
				case "740" :
				// --------------------------------------------------
					tracing += "<td class='tracingCell aacrLowlight'" + fieldHighlight("740","tracingCell") + ">";
					tracing += "T�tulo: " + fields_inOrder[i].value.replace(REGEX_CTRL_SF,"").substr(4).replace(/\^\w/g," ");
					tracing += "</td>";
					break;
				default :
					tracing += "<td class='tracingCell aacrLowlight'" + fieldHighlight(tag,"tracingCell") + ">";
					tracing += fields_inOrder[i].value.replace(REGEX_CTRL_SF,"").substr(4).replace(/\^9.+$/,"").replace(/\^\w/g," ");
					tracing += "</td>";
			}
			tracing += "</tr>";
		}
	}

	// -------------------------------------------------------------
	// Entrada secundaria de t�tulo (245)
	// TO-DO: reubicar esto para que aparezca *antes* que los 730/740
	// -------------------------------------------------------------
	if ( fields_byTag["245"] && fields_byTag["245"][0].substr(0,1) == "1" ) {
		nonSubjCounter++;
		tracing += "<tr><td class='tracingCounter'>" + arabic2Roman(nonSubjCounter) + ".&nbsp;</td>";
		tracing += "<td class='tracingCell aacrLowlight'" + fieldHighlight("245","tracingCell") + ">";
		tracing += "T�tulo.";
		tracing += "</td></tr>";
	}

	// -------------------------------------------------------------
	// Entrada secundaria de (variante de) t�tulo.
	// Basado en las indicaciones de OCLC.
	// -------------------------------------------------------------
	if ( fields_byTag["246"] ) {
		for (var i=0; i < fields_byTag["246"].length; i++) {
			if ( fields_byTag["246"][i].substr(0,1).search(/[13]/) != -1 ) {
				nonSubjCounter++;
				tracing += "<tr><td class='tracingCounter'>" + arabic2Roman(nonSubjCounter) + ".&nbsp;</td>";
				tracing += "<td class='tracingCell aacrLowlight' " + fieldHighlight("246","tracingCell") + ">";
				tracing += "T�tulo: " + fields_byTag["246"][i].replace(/\^[fghi5][^\^]+/g,"").substr(4).replace(/\^\w/g," ");
				
				if ( tracing.charAt(tracing.length - 1).search(/[-\.!\?]/) == -1 ) {
					tracing += ".";
				}
				tracing += "</td></tr>";
			}
		}
	}

	// -------------------------------------------------------------
	// Entrada secundaria de t�tulo anterior (247).
	// OCLC: "The title proper (subfields �a, �n, �p) prints as the added entry."
	// -------------------------------------------------------------
	if ( fields_byTag["247"] ) {
		for (var i=0; i < fields_byTag["247"].length; i++) {
			if ( "1" == fields_byTag["247"][i].substr(0,1) ) {
				nonSubjCounter++;
				tracing += "<tr><td class='tracingCounter'>" + arabic2Roman(nonSubjCounter) + ".&nbsp;</td>";
				tracing += "<td class='tracingCell aacrLowlight' " + fieldHighlight("247","tracingCell") + ">";
				tracing += "T�tulo: " + fields_byTag["247"][i].replace(/\^[^abnp][^\^]+/g,"").substr(4).replace(/\^\w/g," ");
				
				if ( tracing.charAt(tracing.length - 1).search(/[-\.!\?]/) == -1 ) {
					tracing += ".";
				}
				tracing += "</td></tr>";
			}
		}
	}
	
	// -------------------------------------------------------------
	// Entrada secundaria de serie (440, en orden de aparici�n)
	// -------------------------------------------------------------
	if ( fields_byTag["440"] ) {
		for (var i=0; i < fields_byTag["440"].length; i++) {
			nonSubjCounter++;
			tracing += "<tr><td class='tracingCounter'>" + arabic2Roman(nonSubjCounter) + ".&nbsp;</td>";
			tracing += "<td class='tracingCell aacrLowlight' " + fieldHighlight("440","tracingCell") + ">";
			if (i == 0) {
				tracing += "Serie.";
			} else {
				tracing += "Serie: " + fields_byTag["440"][i].replace(/,\^x[^\^]+/,"").replace(REGEX_CTRL_SF,"").substr(4).replace(/\^\w/g," ");
				tracing += ".";  // OCLC
			}
			tracing += "</td></tr>";
		}
	}

	// -------------------------------------------------------------
	// Entrada secundaria de serie (80x-83x, en orden de aparici�n)
	// -------------------------------------------------------------
	for (var i=0; i < fields_inOrder.length; i++) {
		var tag = fields_inOrder[i].tag;
		if ( tag.search(/800|810|811|830/) != -1 )  {
			nonSubjCounter++;
			tracing += "<tr><td class='tracingCounter'>" + arabic2Roman(nonSubjCounter) + ".&nbsp;</td>";
			tracing += "<td class='tracingCell' " + fieldHighlight(tag,"tracingCell") + ">";
			tracing += "Serie: " + fields_inOrder[i].value.replace(REGEX_CTRL_SF,"").substr(4).replace(/\^\w/g," ");
			tracing += "</td></tr>";
		}
	}

	// Fin del trazado
	tracing += "\n</table>\n";
	
	
	var recordNumbers = "";
	recordNumbers += "<table id='recordNumbers' border='0'>";
	recordNumbers += "<tr><td align='right'>";
	recordNumbers += "<span " + fieldHighlight("001") + ">" + f001 + "</span>";
	
	if ( fields_byTag["010"] ) {
		var LCCNnumber = extractSubfield(fields_byTag["010"][0],"a").replace(/#/g,"");
		var LCCNlink = "<a target='_blank' href='http://catalog.loc.gov/cgi-bin/Pwebrecon.cgi?v4=1&DB=local&CMD=010a+" + LCCNnumber + "&CNT=10+records+per+page'>LCCN " + LCCNnumber + "</a>";
		recordNumbers += "&nbsp;&#183;&nbsp;" + "<span " + fieldHighlight("010 -- Enlace al cat�logo de LC") + ">" + LCCNlink + "</span>";
	}
	
	recordNumbers += " &#183; <span " + fieldHighlight("005") + ">" + f005.substr(6,2) + "/" + f005.substr(4,2) + "/" + f005.substr(0,4) + "</span>";
	recordNumbers += "</td></tr></table>";

	var aacrOutput = description + tracing + recordNumbers;

	// Sustituciones finales
	aacrOutput = aacrOutput.replace(/\r\n/g,"<br>").replace(REGEX_INDENT,"&nbsp;&nbsp;&nbsp;&nbsp;");


	// -------------------------------------------------------------
	// ACCESO AL DOCUMENTO: signatura topogr�fica o URI
	// -------------------------------------------------------------
	
	var documentLocation = "";

	// Ejemplares
	
	if ( ejemplares.length > 0 ) {
		
		// Ordenamos la lista de ejemplares
		try {
			// ATENCION: Esta l�nea genera errores de manera espor�dica ("unexpected call to method or property access")
			ejemplares.sort(sortEjemplares);
		} catch(err) {
			var errorMsg = "Hubo un error al construir la ficha AACR2";
			errorMsg += "\n\nSi nota que este problema se repite, use CTRL F5 para\nvolver a cargar los archivos en su navegador.";
			if ( document.getElementById("f001").value != "" && modifiedRecord() ) {
				errorMsg += "\n\nPreviamente, grabe el registro (si desea conservar\nlos cambios realizados).";
			}
			alert(errorMsg);
		}
		
		// Signatura del primer ejemplar
		documentLocation += printCallNumber(ejemplares[0]);
		
		// Signaturas adicionales. S�lo mostramos m�s de una signatura si difieren en: prefijo, clase, o libr�stica.
		var prevKey = "";
		if ( ejemplares[0]["k"] ) prevKey += ejemplares[0]["k"];
		if ( ejemplares[0]["h"] ) prevKey += ejemplares[0]["h"];
		if ( ejemplares[0]["i"] ) prevKey += ejemplares[0]["i"];
		for ( var i=1; i < ejemplares.length; i++ ) {
			var currentKey = "";
			if ( ejemplares[i]["k"] ) currentKey += ejemplares[i]["k"];
			if ( ejemplares[i]["h"] ) currentKey += ejemplares[i]["h"];
			if ( ejemplares[i]["i"] ) currentKey += ejemplares[i]["i"];
			if ( currentKey != prevKey )  {
				documentLocation += printCallNumber(ejemplares[i]);
				prevKey = currentKey;
			}
		}
	}
	
	// Campo 856
	// ATENCION: �C�mo afectan los indicadores? Hay subcampos (muchos) que no est�n pensados
	// para ser visualizados.
	// TO-DO: el campo 856 es repetible; el subcampo $y tambi�n.
	if ( fields_byTag["856"] /*&& fields_byTag["856"][0].substr(0,1) == "4"*/ ) {
		
		for ( var i=0; i < fields_byTag["856"].length; i++ ) {
			
			// Aislamos el subcampo $u (URI)
			var theURI = extractSubfield(fields_byTag["856"][i],"u");
			
			// Por defecto, el texto del link es la misma URI
			var linkText = theURI;
			
			// Pero si hay un subcampo $y o un $3, usamos el primero de �stos como texto del link
			var subfield_y = extractSubfield(fields_byTag["856"][i],"y");
			if ( "" != subfield_y ) {
				linkText = subfield_y;
			} else {
				var subfield_3 = extractSubfield(fields_byTag["856"][i],"3");
				if ( "" != subfield_3 ) {
					linkText = subfield_3;
				}
			}
			
			// Construimos entonces el link
			var theLink = "<a target='_blank' href='" + theURI + "' title='" + theURI + "'>" + linkText + "</a>";
			
			// Y pegamos todo
			//documentLocation += fields_byTag["856"][i].substr(2).replace(linkText,theLink).replace("^u" + theURI,"").replace(/\^\w/g," ").replace(/Table of/,"Table&nbsp;of");
			documentLocation += theLink;
			documentLocation += "<br style='line-height: 0.7em;'><br style='line-height: 0.7em;'>";
		}
	}
	
	// Campo 050 (LC call number), como �ltima alternativa. Subcampos $a posteriores
	// al primero no se muestran.
	if ( 0 == ejemplares.length && !fields_byTag["856"] && fields_byTag["050"] ) {
		documentLocation = extractSubfield(fields_byTag["050"][0],"a");
		documentLocation += "<br>";
		documentLocation += extractSubfield(fields_byTag["050"][0],"b").replace(/ /g,"<br>");
		//fields_byTag["050"][0].substr(4).replace(/\^\w/g,"<br>").replace(/ /g,"<br>");
	}

	// Fin del DIV con font-size peque�o
	//aacrOutput += "</div>";


	if ( DISPLAY_CALL_NUMBER ) {
		var aacrTable = "";
		aacrTable += "<table id='aacrTable' cellspacing='0' border='0'>";
		aacrTable += "<tr>";
		aacrTable += "<td id='documentLocationCell'>" + documentLocation + "</td>";
		aacrTable += "<td id='aacrCell'>" + aacrOutput + "</td>";
		aacrTable += "</tr></table>";
		aacrOutput = aacrTable;
	}

	//alert(aacrOutput);
	return(aacrOutput);
}
