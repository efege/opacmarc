/**
 * Usamos JS para ocultar/mostrar bloques de campos en el formulario.
 *
 * Por ahora la opción elegida es DOMAssistant, algo bien liviano.
 * Ver docs: http://www.domassistant.com/documentation/
 * Para producción usar DOMAssistantCompressed.js
 *
 * No me satisface DOMAssistant, pues encontré unos problemas y no vi una rápida solución.
 * No funciona
 *     $("#pub_date").setAttributes({value: ""})
 * y en su lugar uso:
 *     $("#pub_date")[0].value = "";
 * Algo similar sucede con setAttributes({checked: "checked"})
 *
 * TO-DO. Usar jQuery o MooTools, para poder agregar fácilmente algún efecto de animación.
 * Podríamos usar Ext, y así mantener una uniformidad con el nuevo Catalis, pero (hasta donde probé)
 * el mínimo de Ext necesario pesa por arriba de 110 KB (sin gzip), vs. 52.8 KB de jQuery 1.2.3 completo.
 */

function hide() {
    $("#otras_caract").removeClass("show");
    $("#otras_caract_header").removeClass("collapse");
    $("#otras_caract_header").setAttributes({title : "Click para abrir"});
    otras_caract_hidden = true;
}
function show() {
    $("#otras_caract").addClass("show");
    $("#otras_caract_header").addClass("collapse");
    $("#otras_caract_header").setAttributes({title : "Click para cerrar"});
    otras_caract_hidden = false;
}
function toggle(){
    if (otras_caract_hidden) {
        show();
    } else {
        hide();
    }
}
function initOtrasCaracteristicas() {
    $("#otras_caract").addClass("hide");
    $("#otras_caract_header").addClass("toggler");
    $("#otras_caract_header").addClass("expand");
    $("#otras_caract_header").addEvent("click", toggle);
    hide();
}

// Funciones para la búsqueda por fechas
function cleanFields(f) {
    switch(f) {
        case "single":
            $("#pub_date")[0].value = "";   // NOTE: por qué no anda  $("#pub_date").setAttributes({value: ""}) ?
            break;
        case "multi":
            $("#pub_date_from")[0].value = "";
            $("#pub_date_to")[0].value = "";
            break;
    }
}
function initBusqFechas() {
    // Check en un radio button => limpia los valores asociados a los otros
    $("#date_search_type_all").addEvent("click", function(){
        cleanFields("single");
        cleanFields("multi");
    });
    $("#date_search_type_single").addEvent("click", function(){
        cleanFields("multi");
    });
    $("#date_search_type_multi").addEvent("click", function(){
        cleanFields("single");
    });
    
    // Click en un textbox => check en su radio button, limpia los valores asociados a los otros
    $("#pub_date").addEvent("click", function(){
        $("#date_search_type_single")[0].checked = true;
        cleanFields("multi");
    });
    $("#pub_date_from").addEvent("click", function(){
        $("#date_search_type_multi")[0].checked = true;
        cleanFields("single");
    });
    $("#pub_date_to").addEvent("click", function(){
        $("#date_search_type_multi")[0].checked = true;
        cleanFields("single");
    });
    // Keypress en un textbox => check en su radio button, limpia los valores asociados a los otros
    // FIXME - La tecla TAB no debe disparar el evento
    $("#pub_date").addEvent("keypress", function(){
        $("#date_search_type_single")[0].checked = true;
        cleanFields("multi");
    });
    $("#pub_date_from").addEvent("keypress", function(){
        $("#date_search_type_multi")[0].checked = true;
        cleanFields("single");
    });
    $("#pub_date_to").addEvent("keypress", function(){
        $("#date_search_type_multi")[0].checked = true;
        cleanFields("single");
    });
}

// Init
DOMAssistant.DOMReady(function(){
    initOtrasCaracteristicas();
    initBusqFechas();
});

