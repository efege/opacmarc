<?php
/**
 * Plugin OpacMarc: Embeds OpacMarc into a DokuWiki page
 *
 * Syntax: {{OPAC>dbname}}
 * 
 * @license    GPL 2 (http://www.gnu.org/licenses/gpl.html)
 * @author     Fernando Gómez <fjgomez@gmail.com>
 */

if(!defined('DOKU_INC')) define('DOKU_INC',realpath(dirname(__FILE__).'/../../').'/');
if(!defined('DOKU_PLUGIN')) define('DOKU_PLUGIN',DOKU_INC.'lib/plugins/');
require_once(DOKU_PLUGIN.'syntax.php');

// Code to load data from an URL (needed in case file_get_contents() does not work)
//require_once(dirname(__FILE__).'/load.php');


/**
 * Function http_build_query for PHP < PHP5
 * From http://php.net/manual/en/function.http-build-query.php#72911
 */
if(!function_exists('http_build_query')) {
    function http_build_query($data,$prefix=null,$sep='',$key='') {
        $ret = array();
            foreach((array)$data as $k => $v) {
                $k = urlencode($k);
                if(is_int($k) && $prefix != null) {
                    $k = $prefix.$k;
                }
                if(!empty($key)) {
                    $k = $key."[".$k."]";
                }

                if(is_array($v) || is_object($v)) {
                    array_push($ret,http_build_query($v,"",$sep,$k));
                }
                else {
                    array_push($ret,$k."=".urlencode($v));
                }
            }

        if(empty($sep)) {
            $sep = ini_get("arg_separator.output");
        }

        return implode($sep, $ret);
    }
}
 
/**
 * All DokuWiki plugins to extend the parser/rendering mechanism
 * need to inherit from this class
 */
class syntax_plugin_opacmarc extends DokuWiki_Syntax_Plugin {
 
   /**
    * Get an associative array with plugin info.
    */
    function getInfo(){
        return array(
            'author' => 'Fernando Gómez',
            'email'  => 'fjgomez@gmail.com',
            'date'   => @file_get_contents(DOKU_PLUGIN . 'opacmarc/VERSION'),
            'name'   => 'OpacMarc Plugin',
            'desc'   => 'Embeds OpacMarc into DokuWiki'
        );
    }
 
   /**
    * Get the type of syntax this plugin defines.
    */
    function getType(){
        return 'substition';
    }
 
 
   /**
    * Define how this plugin is handled regarding paragraphs.
    */
    function getPType(){
        return 'block';
    }
 
   /**
    * Where to sort in? See http://www.dokuwiki.org/devel:parser:getsort_list
    */
    function getSort(){
        return 311;  // before media (320) 
    }
 
 
   /**
    * Connect lookup pattern to lexer.
    */
    function connectTo($mode) {
      // {{OPAC>dbname}}
      $this->Lexer->addSpecialPattern('{{OPAC>.*}}',$mode,'plugin_opacmarc');
    }

 
   /**
    * Handler to prepare matched data for the rendering process.
    *
    * IMPORTANT: The output of handle is cached. This means that the page must be
    * modified in order to run this function again.
    */
    function handle($match, $state, $pos, &$handler) {
        
        // match the database name
        $db = substr($match, 7, -2);
        
        // Parameters for letting the opac know this is a special client
        global $conf;
        global $ID;
        switch ($conf['userewrite']) {
            case 0:
                $opac_page = 'doku.php?id='.$ID;
                break;
            case 1:
                $opac_page = $ID;
                break;
            case 2:
                $opac_page = 'doku.php/'.$ID;
                break;
            default:
                $opac_page = '';
        }
        $client_params = '';
        $client_params .= 'script_url=' . urlencode(DOKU_BASE.$opac_page);
        $client_params .= '&path_htdocs=' . urlencode($this->getConf('opac_host') . ':' . $this->getConf('opac_port') . '/');
        $client_params .= '&output=embed';

        // common url components
        $opac_url = $this->getConf('opac_host') . ':' . $this->getConf('opac_port') . $this->getConf('opac_path');
        $opac_url .= '?' . $client_params;
        
        return array($db, $opac_url);
    }
 
   /**
    * Handle the actual output creation.
    */
    function render($mode, &$renderer, $data) {

        // ------ debug: how many times is this function running? 7 (FIXME) ------
        /*
        $fp = fopen('/tmp/dokuwiki-plugin-opacmarc.log', 'a');
        fwrite($fp, date("H:i:s") . " -- syntax-render; mode: $mode\n");
        $logmsg = "Called @ ".
            xdebug_call_file().
            ":".
            xdebug_call_line().
            " from ".
            xdebug_call_function().
            "\n";
        //fwrite($fp, $logmsg);
        fclose($fp);
        */
        // ------ debug -------


        list($db, $opac_url) = $data;

        if($mode == 'xhtml') {

            // These parameters are needed only for the catalog's first page
            if (!isset($_REQUEST['IsisScript'])) {
                $opac_url .= '&IsisScript=' . urlencode($this->getConf('isisscript'));
            }
            if (!isset($_REQUEST['db'])) {
                $opac_url .= '&db=' . urlencode($db);
            }
            
            // Parameters for the opac are received via the URL's query string
            // FIXME - DokuWiki specific parameters (id, do, and others) should not be passed to the opac
            //print '<br/><br/>$_SERVER["QUERY_STRING"]: '.$_SERVER["QUERY_STRING"];
            $qs = $_SERVER['QUERY_STRING'];
            
            // El decode es necesario para términos procedentes de un form (i.e. ingresados por un usuario),
            // pero no para aquellos procedentes de un link (i.e. generados por el OPAC).
            // FIXME -- otros forms: advanced search, etc. Re-sort?
            if (isset($_REQUEST['form'])) { 
                parse_str($qs, $qs_array);
                //print '<br><br>$qs_array: '; print_r($qs_array);
                if ($_REQUEST['form'] == 's') {  // s: search
                    $qs_array['query'] = utf8_decode($qs_array['query']);
                } elseif ($_REQUEST['form'] == 'b') {  // b: browse
                    $qs_array['browseTerm'] = utf8_decode($qs_array['browseTerm']);
                }
                //print '<br/><br/>$qs_array (query utf8 decoded): '; print_r($qs_array);
                $qs = http_build_query($qs_array, null, '&');
                //print '<br/><br/>$qs (via http_build_query): '.$qs;
            }
            
            if ($qs != '') {            
                $opac_url .= '&' . $qs;
            }
            //print '<br/><br/>$opac_url: '.$opac_url;
            
            // fetch opac content
            $opac_data = file_get_contents($opac_url);
            $opac_data = utf8_encode($opac_data);

            $renderer->doc .= $opac_data;     // ptype = 'block'
            return true;
        }
        return false;
    }
}