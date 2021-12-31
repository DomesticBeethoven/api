xquery version "3.1";

module namespace config="https://edirom.de/ns/config";

declare namespace repo="http://exist-db.org/xquery/repo";
declare namespace expath="http://expath.org/ns/pkg";
declare namespace request="http://exist-db.org/xquery/request";
declare namespace system="http://exist-db.org/xquery/system";
declare namespace tei="http://www.tei-c.org/ns/1.0";

(:
    Determine the application root collection from the current module load path.
:)
declare variable $config:app-root :=
    let $rawPath := system:get-module-load-path()
    let $modulePath :=
        (: strip the xmldb: part :)
        if (starts-with($rawPath, 'xmldb:exist://')) then
            if (starts-with($rawPath, 'xmldb:exist://embedded-eXist-server')) then
                substring($rawPath, 36)
            else
                substring($rawPath, 15)
        else
            $rawPath
    return
        substring-before($modulePath, '/resources/')
;


declare variable $config:baseuri := "https://api.domestic-beethoven.eu/"; 

(: declare variable $config:baseuri := "http://localhost:8080/exist/apps/bith-api/"; :)

(: declare variable $config:data-root := $config:baseuri || 'data/'; :)


declare variable $config:data-root := $config:app-root || '/content/';

declare variable $config:iiif-basepath := $config:baseuri || 'iiif/';

declare variable $config:file-basepath := $config:baseuri || 'file/';

declare variable $config:ema-basepath := $config:baseuri || 'ema/';

declare variable $config:xslt-basepath := $config:baseuri || '/resources/xslt/';

declare variable $config:repo-descriptor := doc(concat($config:baseuri, '/repo.xml'))/repo:meta;

declare variable $config:expath-descriptor := doc(concat($config:baseuri, '/expath-pkg.xml'))/expath:package;

(: declare variable $config:module3-root := $config:baseuri || 'module3/'; :)

(: declare variable $config:module3-basepath := 'https://api.beethovens-werkstatt.de/module3/'; :)


