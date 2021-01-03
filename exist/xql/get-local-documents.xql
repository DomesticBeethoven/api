xquery version "3.1";

(:
    get-local-documents.xql
    ...<foldername>/filelist.json

ENDPOINT: .../<range>/<directory>/filelist.json

returns @xml:id of <mei> element for each XML file in folder

:)

(: import shared ressources, mainly path to data folder :)
import module namespace config="http://api.domestic-beethoven.eu/xql/config" at "config.xqm";

declare namespace xhtml="http://www.w3.org/1999/xhtml";
declare namespace mei="http://www.music-encoding.org/ns/mei";
declare namespace svg="http://www.w3.org/2000/svg";
declare namespace request="http://exist-db.org/xquery/request";
declare namespace util="http://exist-db.org/xquery/util";
declare namespace transform="http://exist-db.org/xquery/transform";
declare namespace response="http://exist-db.org/xquery/response";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";

(: set output to JSON:)
declare option output:method "json";
declare option output:media-type "application/json";

(: allow Cross Origin Ressource Sharing / CORS :)
let $header-addition := response:set-header("Access-Control-Allow-Origin","*")

(: get database from configuration :)

let $database := collection($config:data-root)

(: get the requested DIRECTORY, as passed by the controller :)
let $folder := request:get-parameter('folder','')

(: SUBDIRECTORY :)
let $data.basePath := $config:data-root||$folder || '/'

(: get all files that have both an ID and some operable graphic elements :)
(:  for $file in $database//mei:mei[@xml:id][.//mei:facsimile[.//mei:graphic]]:)
let $files :=
    for $file in collection($data.basePath)//mei:mei
      let $id := $file/string(@xml:id)
  
  return map {
    'id': $id             (: the ID of the file :)
  }

return array { $files }
