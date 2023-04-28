xquery version "3.1";

(:
    get-manifest.json.xql

    This xQuery retrieves a jsonld file with the given name
:)

(: import shared ressources, mainly path to data folder :)
import module namespace config="https://edirom.de/ns/config" at "../../xqm/config.xqm";
import module namespace iiif="https://edirom.de/iiif" at "../../xqm/iiif.xqm";

declare namespace xhtml="http://www.w3.org/1999/xhtml";
declare namespace mei="http://www.music-encoding.org/ns/mei";
declare namespace svg="http://www.w3.org/2000/svg";
declare namespace request="http://exist-db.org/xquery/request";
declare namespace util="http://exist-db.org/xquery/util";
declare namespace transform="http://exist-db.org/xquery/transform";
declare namespace response="http://exist-db.org/xquery/response";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace f = "http://local.link";
declare namespace map="http://www.w3.org/2005/xpath-functions/map";
declare namespace xi = "http://www.w3.org/2001/XInclude";

(: set output to JSON:)
declare option output:method "json";
declare option output:media-type "application/json";

(: allow Cross Origin Ressource Sharing / CORS :)
let $header-addition := response:set-header("Access-Control-Allow-Origin","*")

(: get database from configuration :)
let $path := $config:data-root || 'ld/'

(: get the ID of the requested document, as passed by the controller :)
let $document.name := request:get-parameter('document.name','')
let $available := util:binary-doc-available($path || $document.name)
let $file := json-doc($path || $document.name)

return $file