<?php
/**
 * Action Plugin opacmarc: Inserts JS and CSS links in the opac page.
 * 
 * @author     Fernando Gómez <fjgomez@gmail.com>
 */
 
if(!defined('DOKU_INC')) die();
if(!defined('DOKU_PLUGIN')) define('DOKU_PLUGIN',DOKU_INC.'lib/plugins/');
require_once(DOKU_PLUGIN.'action.php');
 
class action_plugin_opacmarc extends DokuWiki_Action_Plugin {
 
  /**
   * return some info
   */
  function getInfo(){
    return array(
		 'author' => 'Fernando Gómez',
		 'email'  => 'fjgomez@gmail.com',
		 'date'   => @file_get_contents(DOKU_PLUGIN . 'opacmarc/VERSION'),
		 'name'   => 'Opacmarc (action plugin component)',
		 'desc'   => 'Inserts CSS and JS links for embedding OpacMarc into DokuWiki.'
		 );
  }
 
  /**
   * Register its handlers with the DokuWiki's event controller
   */
  function register(&$controller) {
    $controller->register_hook('TPL_METAHEADER_OUTPUT', 'BEFORE',  $this, '_hookjscss');
  }
 
  /**
   * Hook js/css links into page head.
   */
  function _hookjscss(&$event, $param) {
    global $ID;
    if ($ID == 'biblio:catalogo') {    // FIXME -- no debe depender del nombre de la página, pero ¿cómo hacemos de otra forma?
        $opacBaseUrl = $this->getConf('opac_host') . ':' . $this->getConf('opac_port');
        
        // JavaScript
        $scripts = array('opac', 'marc2aacr', 'isbn-hyphen', 'getMaterialType', 'zebra-table');
    	foreach ($scripts as $script) {
        	$event->data['script'][] = array ('type' => 'text/javascript',
        	                                  'charset' => 'iso-8859-1',
        	                                  '_data' => '',  /* The contents of the <script> tag -- REQUIRED */
        					                  'src' => $opacBaseUrl.'/js/'.$script.'.js'
        				                     );
        }
        
        // CSS
        $stylesheets = array('opac', 'aacr', 'wh', 'complete', 'etiquetado', 'novedades');
    	foreach ($stylesheets as $stylesheet) {
        	$event->data['link'][] = array ('rel' => 'stylesheet',  
        	                                'type' => 'text/css',
        					                'href' => $opacBaseUrl.'/css/'.$stylesheet.'.css'
        				                   );
        }
    }
  }
}
