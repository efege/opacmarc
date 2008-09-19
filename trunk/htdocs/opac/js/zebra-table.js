// Based on: http://www.alistapart.com/articles/zebratables
// TO-DO: use addClass() instead of touching style.backgroundColor

 // this function is needed to work around 
  // a bug in IE related to element attributes
function hasClass(obj) {
    var result = false;
    if (obj.getAttributeNode("class") != null) {
        result = obj.getAttributeNode("class").value;
    }
    return result;
}

function stripe(id) {

    // the flag we'll use to keep track of whether the current row is odd or even
    var even = false;
  
    // if arguments are provided to specify the colours
    // of the even & odd rows, then use the them;
    // otherwise use the following defaults:
    // Colors from http://mkaz.com/ref/xterm_colors.html:
    // floral: FFFAF0
    // linen: FAF0E6
    var oddLabelColor = arguments[2] ? arguments[2] :  "#E7E2D8";
    var evenLabelColor = arguments[1] ? arguments[1] : "#EFEAE0";
    var oddDataColor = arguments[2] ? arguments[2] :   "#F7F2E8";
    var evenDataColor = arguments[1] ? arguments[1] :  "#FFFAF0";
  
    // obtain a reference to the desired table
    // if no such table exists, abort
    var table = document.getElementById(id);
    if (! table) { return; }
    
    // by definition, tables can have more than one tbody
    // element, so we'll have to get the list of child
    // &lt;tbody&gt;s 
    var tbodies = table.getElementsByTagName("tbody");

    // and iterate through them...
    for (var h = 0; h < tbodies.length; h++) {
        
        // find all the &lt;tr&gt; elements... 
        var trs = tbodies[h].getElementsByTagName("tr");
      
        // ... and iterate through them
        for (var i = 0; i < trs.length; i++) {
            
            // avoid rows that have a class attribute or backgroundColor style
            /*if (! hasClass(trs[i]) &&
                ! trs[i].style.backgroundColor) {
            */
                
                // get all the cells in this row...
                var tds = trs[i].getElementsByTagName("td");
                
                // and iterate through them...
                for (var j = 0; j < tds.length; j++) {
                    
                    var mytd = tds[j];
                    
                    // avoid cells that have a class attribute or backgroundColor style
                    if ( hasClass(mytd).search('label') != -1) {
                        mytd.style.backgroundColor = even ? evenLabelColor : oddLabelColor;
                    } else {
                        mytd.style.backgroundColor = even ? evenDataColor : oddDataColor;
                    }
                }
            /*}*/
            // flip from odd to even, or vice-versa
            even =  ! even;
        }
    }
}