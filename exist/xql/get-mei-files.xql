xquery version "3.1";

(:
    get-mei-files.xql

    This xQuery retrieves a list of all MEI files in the database
:)

import module namespace config="http://api.domestic-beethoven.eu/xql/config" at "config.xqm";

declare namespace xhtml="http://www.w3.org/1999/xhtml";
declare namespace mei="http://www.music-encoding.org/ns/mei";
declare namespace svg="http://www.w3.org/2000/svg";
declare namespace request="http://exist-db.org/xquery/request";
declare namespace util="http://exist-db.org/xquery/util";
declare namespace transform="http://exist-db.org/xquery/transform";
declare namespace response="http://exist-db.org/xquery/response";

declare option exist:serialize "method=json media-type=application/json";

let $header-addition := response:set-header("Access-Control-Allow-Origin","*")

let $data.basePath := $config:data-root

let $files :=
  for $file in collection($data.basePath)//mei:mei
  let $id := $file/string(@xml:id)
  let $title := $file//mei:title/text()
  return
    map {
      'id': $id,
      'title': $title
    }

return array { $files }
