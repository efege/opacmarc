// Funciones para presentar ejemplos de búsquedas
// Fuente: http://www.lib.ncsu.edu/catalog/

// ATENCION: alternativamente, podemos crear divs ocultos, y cambiar su estado
// con CSS.
// ¿Cómo evitamos que la altura del box se altere según el texto que contiene
// cada ejemplo? Necesitamos fijar una altura máxima adecuada.

// Organizar en 3 partes: texto sobre el textbox, descripción e indicaciones
// para el tipo de búsqueda, y lista de ejemplos

// TO-DO: asociar los ejemplos a la base de datos consultada

	var beginsExample = new Array();
	// Ejemplos de index browsing
	beginsExample[0] = "old man and the sea<br />war and peace";
	beginsExample[1] = "journal of the american chemical society<br />";
	beginsExample[2] = "bradbury ray<br />american chemical society";
	beginsExample[3] = "united states history civil war<br />biomedical engineering";
	beginsExample[4] = "botanical monographs<br />current controversies";
	beginsExample[5] = "Z685.P48";
	beginsExample[6] = "A 1.1/3<br />";
	
	var keywordExample = new Array();
	// Ejemplos de búsqueda por palabras
	keywordExample[0] = "conway<br>paul erdos";
	keywordExample[1] = "complex variable*<br>calculus analytic geometry";
	keywordExample[2] = "fourier series<br>laplace";
	keywordExample[3] = "Identificadores numéricos: ISBN, ISSN, inventario, nro. de registro:<br>0471853011<br>0-471-85301-1";
	keywordExample[4] = "0375406492<br />0022-2844";
	
	function getExamples(searchType,n) {
		try {
			if (searchType == "browseType") {
				//var n = document.authoritySearch.button_clicked.selectedIndex;
				if (window.navigator.userAgent.indexOf("Opera") != -1) {
    				x = window.beginsExampleDiv;
	    			x.innerHTML = beginsExample[n];
				}
	  			else if (window.navigator.userAgent.indexOf("MSIE") != -1 ||
					window.navigator.userAgent.indexOf("Mozilla") != -1 ||
					window.navigator.userAgent.indexOf("Netscape6") != -1) {
    				x = document.getElementById("browseExamples");
		    		x.innerHTML = beginsExample[n];
		  		}
		  		else {
    				window.beginsExampleDiv.innerHTML = beginsExample[n];
		  		}
			}
			else if (searchType == "searchType") {
				//var n = document.keywordSearch.Ntk.selectedIndex;
				if (window.navigator.userAgent.indexOf("Opera") != -1) {
    				x = window.keywordExampleDiv;
	    			x.innerHTML = keywordExample[n];
				}
	  			else if (window.navigator.userAgent.indexOf("MSIE") != -1 ||
						window.navigator.userAgent.indexOf("Mozilla") != -1 ||
						window.navigator.userAgent.indexOf("Netscape6") != -1) {
	    			x = document.getElementById("keywordExamples");
	    			//alert(x.innerHTML);
		    		x.innerHTML = keywordExample[n];
		  		}
		  		else {
    				window.keywordExampleDiv.innerHTML = keywordExample[n];
		  		}
			}
			else {
				alert("Invalid search type sent as parameter");
			}
		} catch (e) {
			alert("Javascript Error on getting examples");
		}
	}


// -------------------------------------------------------------------


	// ----------------------------------------------------------
	function init() {
	// ----------------------------------------------------------
		//[pft]if v2011 = 'simple' then[/pft]
		// TO-DO: tocar el foco sólo cuando la página presenta el formulario (sin resultados)
		if ( document.getElementById && document.getElementById("kwQuery") ) {
			document.getElementById("kwQuery").focus();
		}
		//[pft]else[/pft]
			// do nothing
		//[pft]fi[/pft]
		
		if ( document.getElementById && document.getElementById("searchType") ) {
			document.getElementById("searchType").onclick = function() {
				getExamples(this.id,this.selectedIndex);
			}
		}
		if ( document.getElementById && document.getElementById("browseType") ) {
			document.getElementById("browseType").onclick = function() {
				getExamples(this.id,this.selectedIndex);
			}
		}
	}
	
	// ----------------------------------------------------------
	function helpPopup(elementId) {
	// ----------------------------------------------------------
		switch ( elementId ) {
			case "helpTruncate" :
				alert("Usar palabras como raíces\n----------------------------------------------\nSi esta opción está activada, entonces al buscar BIOLOG encontrará BIOLOGY, BIOLOGICAL, BIOLOGIA, etc.");
				break;
		}
	}
	
	// ----------------------------------------------------------
	function auxWin(url) {
	// ----------------------------------------------------------
		var auxWin = window.open(url,"","width=600, height=300, location=yes, menubar=yes, resizable=yes, toolbar=yes, scrollbars=yes, status=yes, top=50, left=50");
	}
	
	// ----------------------------------------------------------
	function checkMail()
	// ----------------------------------------------------------
	{
		var x = document.forms["emailForm"].mail_to.value;
		var filter  = /^([a-zA-Z0-9_\.\-])+\@(([a-zA-Z0-9\-])+\.)+([a-zA-Z0-9]{2,4})+$/;
		if ( filter.test(x) ) {
			document.forms["emailForm"].submit();
		}
		else {
			if (x == "")
				alert ("No ha escrito una dirección de correo.")
			else
				alert("Lo que ha escrito no es una dirección de correo válida."); 
			return false;
		}
	}
	
	// ----------------------------------------------------------
	function checkQuery(theForm)
	// ----------------------------------------------------------
	{
		var x = theForm.query.value;
		if ( x != "" ) {
			theForm.submit();
		}
		else {
			alert ("No ha ingresado ninguna expresión para buscar.")
			theForm.query.focus();
			return false;
		}
	}
	
	//var MAIN_ENTRY_TOP = [pft]v6001^1[/pft];  // (boolean)
	
	//window.onload = init;




/*
	function handleLoad() {
		[pft]if v2011 = 'simple' then[/pft]
		if ( document.getElementById && document.getElementById("BrowseIndexForm") ) {
			document.getElementById("BrowseIndexForm").browseTerm.focus();
		}
		[pft]else[/pft]
			// do nothing
		[pft]fi[/pft]
		alert("g");
	}
	
	function helpPopup(elementId) {
		switch ( elementId ) {
			case "helpTruncate" :
				alert("Usar palabras como raíces\n----------------------------------------------\nSi esta opción está activada, entonces al buscar BIOLOG encontrará BIOLOGY, BIOLOGICAL, BIOLOGIA, etc.");
				break;
		}
	}
	
	function auxWin(url) {
		var auxWin = window.open(url,"","width=600, height=300, location=yes, menubar=yes, resizable=yes, toolbar=yes, scrollbars=yes, status=yes, top=50, left=50");
	}
	
	function checkMail()
	{
		var x = document.forms["emailForm"].mail_to.value;
		var filter  = /^([a-zA-Z0-9_\.\-])+\@(([a-zA-Z0-9\-])+\.)+([a-zA-Z0-9]{2,4})+$/;
		if ( filter.test(x) ) {
			document.forms["emailForm"].submit();
		}
		else {
			if (x == "")
				alert ("No ha escrito una dirección de correo.")
			else
				alert("Lo que ha escrito no es una dirección de correo válida."); 
			return false;
		}
	}
	
	function checkQuery(theForm)
	{
		var x = theForm.query.value;
		if ( x != "" ) {
			theForm.submit();
		}
		else {
			alert ("No ha ingresado ninguna expresión para buscar.")
			theForm.query.focus();
			return false;
		}
	}
	
	var MAIN_ENTRY_TOP = [pft]v6001^1[/pft];  // (boolean)
	
	window.onload = handleLoad;
*/