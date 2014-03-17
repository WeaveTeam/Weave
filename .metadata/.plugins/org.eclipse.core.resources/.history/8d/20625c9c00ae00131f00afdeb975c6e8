var COMPILED = !0, goog = goog || {};
goog.global = this;
goog.exportPath_ = function $goog$exportPath_$($name$$, $opt_object$$, $cur_opt_objectToExportTo$$) {
  $name$$ = $name$$.split(".");
  $cur_opt_objectToExportTo$$ = $cur_opt_objectToExportTo$$ || goog.global;
  $name$$[0] in $cur_opt_objectToExportTo$$ || !$cur_opt_objectToExportTo$$.execScript || $cur_opt_objectToExportTo$$.execScript("var " + $name$$[0]);
  for(var $part$$;$name$$.length && ($part$$ = $name$$.shift());) {
    $name$$.length || void 0 === $opt_object$$ ? $cur_opt_objectToExportTo$$ = $cur_opt_objectToExportTo$$[$part$$] ? $cur_opt_objectToExportTo$$[$part$$] : $cur_opt_objectToExportTo$$[$part$$] = {} : $cur_opt_objectToExportTo$$[$part$$] = $opt_object$$
  }
};
goog.define = function $goog$define$($name$$, $defaultValue$$) {
  var $value$$ = $defaultValue$$;
  COMPILED || goog.global.CLOSURE_DEFINES && Object.prototype.hasOwnProperty.call(goog.global.CLOSURE_DEFINES, $name$$) && ($value$$ = goog.global.CLOSURE_DEFINES[$name$$]);
  goog.exportPath_($name$$, $value$$)
};
goog.DEBUG = !0;
goog.LOCALE = "en";
goog.TRUSTED_SITE = !0;
goog.provide = function $goog$provide$($name$$) {
  if(!COMPILED) {
    if(goog.isProvided_($name$$)) {
      throw Error('Namespace "' + $name$$ + '" already declared.');
    }
    delete goog.implicitNamespaces_[$name$$];
    for(var $namespace$$ = $name$$;($namespace$$ = $namespace$$.substring(0, $namespace$$.lastIndexOf("."))) && !goog.getObjectByName($namespace$$);) {
      goog.implicitNamespaces_[$namespace$$] = !0
    }
  }
  goog.exportPath_($name$$)
};
goog.setTestOnly = function $goog$setTestOnly$($opt_message$$) {
  if(COMPILED && !goog.DEBUG) {
    throw $opt_message$$ = $opt_message$$ || "", Error("Importing test-only code into non-debug environment" + $opt_message$$ ? ": " + $opt_message$$ : ".");
  }
};
COMPILED || (goog.isProvided_ = function $goog$isProvided_$($name$$) {
  return!goog.implicitNamespaces_[$name$$] && !!goog.getObjectByName($name$$)
}, goog.implicitNamespaces_ = {});
goog.getObjectByName = function $goog$getObjectByName$($name$$, $opt_obj$$) {
  for(var $parts$$ = $name$$.split("."), $cur$$ = $opt_obj$$ || goog.global, $part$$;$part$$ = $parts$$.shift();) {
    if(goog.isDefAndNotNull($cur$$[$part$$])) {
      $cur$$ = $cur$$[$part$$]
    }else {
      return null
    }
  }
  return $cur$$
};
goog.globalize = function $goog$globalize$($obj$$, $opt_global$$) {
  var $global$$ = $opt_global$$ || goog.global, $x$$;
  for($x$$ in $obj$$) {
    $global$$[$x$$] = $obj$$[$x$$]
  }
};
goog.addDependency = function $goog$addDependency$($path$$, $provides_require$$, $requires$$) {
  if(goog.DEPENDENCIES_ENABLED) {
    var $j_provide$$;
    $path$$ = $path$$.replace(/\\/g, "/");
    for(var $deps$$ = goog.dependencies_, $i$$ = 0;$j_provide$$ = $provides_require$$[$i$$];$i$$++) {
      $deps$$.nameToPath[$j_provide$$] = $path$$, $path$$ in $deps$$.pathToNames || ($deps$$.pathToNames[$path$$] = {}), $deps$$.pathToNames[$path$$][$j_provide$$] = !0
    }
    for($j_provide$$ = 0;$provides_require$$ = $requires$$[$j_provide$$];$j_provide$$++) {
      $path$$ in $deps$$.requires || ($deps$$.requires[$path$$] = {}), $deps$$.requires[$path$$][$provides_require$$] = !0
    }
  }
};
goog.ENABLE_DEBUG_LOADER = !0;
goog.require = function $goog$require$($errorMessage_name$$) {
  if(!COMPILED && !goog.isProvided_($errorMessage_name$$)) {
    if(goog.ENABLE_DEBUG_LOADER) {
      var $path$$ = goog.getPathFromDeps_($errorMessage_name$$);
      if($path$$) {
        goog.included_[$path$$] = !0;
        goog.writeScripts_();
        return
      }
    }
    $errorMessage_name$$ = "goog.require could not find: " + $errorMessage_name$$;
    goog.global.console && goog.global.console.error($errorMessage_name$$);
    throw Error($errorMessage_name$$);
  }
};
goog.basePath = "";
goog.nullFunction = function $goog$nullFunction$() {
};
goog.identityFunction = function $goog$identityFunction$($opt_returnValue$$, $var_args$$) {
  return $opt_returnValue$$
};
goog.abstractMethod = function $goog$abstractMethod$() {
  throw Error("unimplemented abstract method");
};
goog.addSingletonGetter = function $goog$addSingletonGetter$($ctor$$) {
  $ctor$$.getInstance = function $$ctor$$$getInstance$() {
    if($ctor$$.instance_) {
      return $ctor$$.instance_
    }
    goog.DEBUG && (goog.instantiatedSingletons_[goog.instantiatedSingletons_.length] = $ctor$$);
    return $ctor$$.instance_ = new $ctor$$
  }
};
goog.instantiatedSingletons_ = [];
goog.DEPENDENCIES_ENABLED = !COMPILED && goog.ENABLE_DEBUG_LOADER;
goog.DEPENDENCIES_ENABLED && (goog.included_ = {}, goog.dependencies_ = {pathToNames:{}, nameToPath:{}, requires:{}, visited:{}, written:{}}, goog.inHtmlDocument_ = function $goog$inHtmlDocument_$() {
  var $doc$$ = goog.global.document;
  return"undefined" != typeof $doc$$ && "write" in $doc$$
}, goog.findBasePath_ = function $goog$findBasePath_$() {
  if(goog.global.CLOSURE_BASE_PATH) {
    goog.basePath = goog.global.CLOSURE_BASE_PATH
  }else {
    if(goog.inHtmlDocument_()) {
      for(var $scripts$$ = goog.global.document.getElementsByTagName("script"), $i$$ = $scripts$$.length - 1;0 <= $i$$;--$i$$) {
        var $src$$ = $scripts$$[$i$$].src, $l_qmark$$ = $src$$.lastIndexOf("?"), $l_qmark$$ = -1 == $l_qmark$$ ? $src$$.length : $l_qmark$$;
        if("base.js" == $src$$.substr($l_qmark$$ - 7, 7)) {
          goog.basePath = $src$$.substr(0, $l_qmark$$ - 7);
          break
        }
      }
    }
  }
}, goog.importScript_ = function $goog$importScript_$($src$$) {
  var $importScript$$ = goog.global.CLOSURE_IMPORT_SCRIPT || goog.writeScriptTag_;
  !goog.dependencies_.written[$src$$] && $importScript$$($src$$) && (goog.dependencies_.written[$src$$] = !0)
}, goog.writeScriptTag_ = function $goog$writeScriptTag_$($src$$) {
  if(goog.inHtmlDocument_()) {
    var $doc$$ = goog.global.document;
    if("complete" == $doc$$.readyState) {
      if(/\bdeps.js$/.test($src$$)) {
        return!1
      }
      throw Error('Cannot write "' + $src$$ + '" after document load');
    }
    $doc$$.write('\x3cscript type\x3d"text/javascript" src\x3d"' + $src$$ + '"\x3e\x3c/script\x3e');
    return!0
  }
  return!1
}, goog.writeScripts_ = function $goog$writeScripts_$() {
  function $visitNode$$($path$$) {
    if(!($path$$ in $deps$$.written)) {
      if(!($path$$ in $deps$$.visited) && ($deps$$.visited[$path$$] = !0, $path$$ in $deps$$.requires)) {
        for(var $requireName$$ in $deps$$.requires[$path$$]) {
          if(!goog.isProvided_($requireName$$)) {
            if($requireName$$ in $deps$$.nameToPath) {
              $visitNode$$($deps$$.nameToPath[$requireName$$])
            }else {
              throw Error("Undefined nameToPath for " + $requireName$$);
            }
          }
        }
      }
      $path$$ in $seenScript$$ || ($seenScript$$[$path$$] = !0, $scripts$$.push($path$$))
    }
  }
  var $scripts$$ = [], $seenScript$$ = {}, $deps$$ = goog.dependencies_, $i$$3_path$$;
  for($i$$3_path$$ in goog.included_) {
    $deps$$.written[$i$$3_path$$] || $visitNode$$($i$$3_path$$)
  }
  for($i$$3_path$$ = 0;$i$$3_path$$ < $scripts$$.length;$i$$3_path$$++) {
    if($scripts$$[$i$$3_path$$]) {
      goog.importScript_(goog.basePath + $scripts$$[$i$$3_path$$])
    }else {
      throw Error("Undefined script input");
    }
  }
}, goog.getPathFromDeps_ = function $goog$getPathFromDeps_$($rule$$) {
  return $rule$$ in goog.dependencies_.nameToPath ? goog.dependencies_.nameToPath[$rule$$] : null
}, goog.findBasePath_(), goog.global.CLOSURE_NO_DEPS || goog.importScript_(goog.basePath + "deps.js"));
goog.typeOf = function $goog$typeOf$($value$$) {
  var $s$$ = typeof $value$$;
  if("object" == $s$$) {
    if($value$$) {
      if($value$$ instanceof Array) {
        return"array"
      }
      if($value$$ instanceof Object) {
        return $s$$
      }
      var $className$$ = Object.prototype.toString.call($value$$);
      if("[object Window]" == $className$$) {
        return"object"
      }
      if("[object Array]" == $className$$ || "number" == typeof $value$$.length && "undefined" != typeof $value$$.splice && "undefined" != typeof $value$$.propertyIsEnumerable && !$value$$.propertyIsEnumerable("splice")) {
        return"array"
      }
      if("[object Function]" == $className$$ || "undefined" != typeof $value$$.call && "undefined" != typeof $value$$.propertyIsEnumerable && !$value$$.propertyIsEnumerable("call")) {
        return"function"
      }
    }else {
      return"null"
    }
  }else {
    if("function" == $s$$ && "undefined" == typeof $value$$.call) {
      return"object"
    }
  }
  return $s$$
};
goog.isDef = function $goog$isDef$($val$$) {
  return void 0 !== $val$$
};
goog.isNull = function $goog$isNull$($val$$) {
  return null === $val$$
};
goog.isDefAndNotNull = function $goog$isDefAndNotNull$($val$$) {
  return null != $val$$
};
goog.isArray = function $goog$isArray$($val$$) {
  return"array" == goog.typeOf($val$$)
};
goog.isArrayLike = function $goog$isArrayLike$($val$$) {
  var $type$$ = goog.typeOf($val$$);
  return"array" == $type$$ || "object" == $type$$ && "number" == typeof $val$$.length
};
goog.isDateLike = function $goog$isDateLike$($val$$) {
  return goog.isObject($val$$) && "function" == typeof $val$$.getFullYear
};
goog.isString = function $goog$isString$($val$$) {
  return"string" == typeof $val$$
};
goog.isBoolean = function $goog$isBoolean$($val$$) {
  return"boolean" == typeof $val$$
};
goog.isNumber = function $goog$isNumber$($val$$) {
  return"number" == typeof $val$$
};
goog.isFunction = function $goog$isFunction$($val$$) {
  return"function" == goog.typeOf($val$$)
};
goog.isObject = function $goog$isObject$($val$$) {
  var $type$$ = typeof $val$$;
  return"object" == $type$$ && null != $val$$ || "function" == $type$$
};
goog.getUid = function $goog$getUid$($obj$$) {
  return $obj$$[goog.UID_PROPERTY_] || ($obj$$[goog.UID_PROPERTY_] = ++goog.uidCounter_)
};
goog.removeUid = function $goog$removeUid$($obj$$) {
  "removeAttribute" in $obj$$ && $obj$$.removeAttribute(goog.UID_PROPERTY_);
  try {
    delete $obj$$[goog.UID_PROPERTY_]
  }catch($ex$$) {
  }
};
goog.UID_PROPERTY_ = "closure_uid_" + (1E9 * Math.random() >>> 0);
goog.uidCounter_ = 0;
goog.getHashCode = goog.getUid;
goog.removeHashCode = goog.removeUid;
goog.cloneObject = function $goog$cloneObject$($obj$$) {
  var $clone_type$$ = goog.typeOf($obj$$);
  if("object" == $clone_type$$ || "array" == $clone_type$$) {
    if($obj$$.clone) {
      return $obj$$.clone()
    }
    var $clone_type$$ = "array" == $clone_type$$ ? [] : {}, $key$$;
    for($key$$ in $obj$$) {
      $clone_type$$[$key$$] = goog.cloneObject($obj$$[$key$$])
    }
    return $clone_type$$
  }
  return $obj$$
};
goog.bindNative_ = function $goog$bindNative_$($fn$$, $selfObj$$, $var_args$$) {
  return $fn$$.call.apply($fn$$.bind, arguments)
};
goog.bindJs_ = function $goog$bindJs_$($fn$$, $selfObj$$, $var_args$$) {
  if(!$fn$$) {
    throw Error();
  }
  if(2 < arguments.length) {
    var $boundArgs$$ = Array.prototype.slice.call(arguments, 2);
    return function() {
      var $newArgs$$ = Array.prototype.slice.call(arguments);
      Array.prototype.unshift.apply($newArgs$$, $boundArgs$$);
      return $fn$$.apply($selfObj$$, $newArgs$$)
    }
  }
  return function() {
    return $fn$$.apply($selfObj$$, arguments)
  }
};
goog.bind = function $goog$bind$($fn$$, $selfObj$$, $var_args$$) {
  Function.prototype.bind && -1 != Function.prototype.bind.toString().indexOf("native code") ? goog.bind = goog.bindNative_ : goog.bind = goog.bindJs_;
  return goog.bind.apply(null, arguments)
};
goog.partial = function $goog$partial$($fn$$, $var_args$$) {
  var $args$$ = Array.prototype.slice.call(arguments, 1);
  return function() {
    var $newArgs$$ = Array.prototype.slice.call(arguments);
    $newArgs$$.unshift.apply($newArgs$$, $args$$);
    return $fn$$.apply(this, $newArgs$$)
  }
};
goog.mixin = function $goog$mixin$($target$$, $source$$) {
  for(var $x$$ in $source$$) {
    $target$$[$x$$] = $source$$[$x$$]
  }
};
goog.now = goog.TRUSTED_SITE && Date.now || function() {
  return+new Date
};
goog.globalEval = function $goog$globalEval$($script$$) {
  if(goog.global.execScript) {
    goog.global.execScript($script$$, "JavaScript")
  }else {
    if(goog.global.eval) {
      if(null == goog.evalWorksForGlobals_ && (goog.global.eval("var _et_ \x3d 1;"), "undefined" != typeof goog.global._et_ ? (delete goog.global._et_, goog.evalWorksForGlobals_ = !0) : goog.evalWorksForGlobals_ = !1), goog.evalWorksForGlobals_) {
        goog.global.eval($script$$)
      }else {
        var $doc$$ = goog.global.document, $scriptElt$$ = $doc$$.createElement("script");
        $scriptElt$$.type = "text/javascript";
        $scriptElt$$.defer = !1;
        $scriptElt$$.appendChild($doc$$.createTextNode($script$$));
        $doc$$.body.appendChild($scriptElt$$);
        $doc$$.body.removeChild($scriptElt$$)
      }
    }else {
      throw Error("goog.globalEval not available");
    }
  }
};
goog.evalWorksForGlobals_ = null;
goog.getCssName = function $goog$getCssName$($className$$, $opt_modifier$$) {
  var $getMapping$$ = function $$getMapping$$$($cssName$$) {
    return goog.cssNameMapping_[$cssName$$] || $cssName$$
  }, $rename_renameByParts$$ = function $$rename_renameByParts$$$($cssName$$1_parts$$) {
    $cssName$$1_parts$$ = $cssName$$1_parts$$.split("-");
    for(var $mapped$$ = [], $i$$ = 0;$i$$ < $cssName$$1_parts$$.length;$i$$++) {
      $mapped$$.push($getMapping$$($cssName$$1_parts$$[$i$$]))
    }
    return $mapped$$.join("-")
  }, $rename_renameByParts$$ = goog.cssNameMapping_ ? "BY_WHOLE" == goog.cssNameMappingStyle_ ? $getMapping$$ : $rename_renameByParts$$ : function($a$$) {
    return $a$$
  };
  return $opt_modifier$$ ? $className$$ + "-" + $rename_renameByParts$$($opt_modifier$$) : $rename_renameByParts$$($className$$)
};
goog.setCssNameMapping = function $goog$setCssNameMapping$($mapping$$, $opt_style$$) {
  goog.cssNameMapping_ = $mapping$$;
  goog.cssNameMappingStyle_ = $opt_style$$
};
!COMPILED && goog.global.CLOSURE_CSS_NAME_MAPPING && (goog.cssNameMapping_ = goog.global.CLOSURE_CSS_NAME_MAPPING);
goog.getMsg = function $goog$getMsg$($str$$, $opt_values$$) {
  var $values$$ = $opt_values$$ || {}, $key$$;
  for($key$$ in $values$$) {
    var $value$$ = ("" + $values$$[$key$$]).replace(/\$/g, "$$$$");
    $str$$ = $str$$.replace(RegExp("\\{\\$" + $key$$ + "\\}", "gi"), $value$$)
  }
  return $str$$
};
goog.getMsgWithFallback = function $goog$getMsgWithFallback$($a$$, $b$$) {
  return $a$$
};
goog.exportSymbol = function $goog$exportSymbol$($publicPath$$, $object$$, $opt_objectToExportTo$$) {
  goog.exportPath_($publicPath$$, $object$$, $opt_objectToExportTo$$)
};
goog.exportProperty = function $goog$exportProperty$($object$$, $publicName$$, $symbol$$) {
  $object$$[$publicName$$] = $symbol$$
};
goog.inherits = function $goog$inherits$($childCtor$$, $parentCtor$$) {
  function $tempCtor$$() {
  }
  $tempCtor$$.prototype = $parentCtor$$.prototype;
  $childCtor$$.superClass_ = $parentCtor$$.prototype;
  $childCtor$$.prototype = new $tempCtor$$;
  $childCtor$$.prototype.constructor = $childCtor$$
};
goog.base = function $goog$base$($me$$, $opt_methodName$$, $var_args$$) {
  var $caller$$ = arguments.callee.caller;
  if(goog.DEBUG && !$caller$$) {
    throw Error("arguments.caller not defined.  goog.base() expects not to be running in strict mode. See http://www.ecma-international.org/ecma-262/5.1/#sec-C");
  }
  if($caller$$.superClass_) {
    return $caller$$.superClass_.constructor.apply($me$$, Array.prototype.slice.call(arguments, 1))
  }
  for(var $args$$ = Array.prototype.slice.call(arguments, 2), $foundCaller$$ = !1, $ctor$$ = $me$$.constructor;$ctor$$;$ctor$$ = $ctor$$.superClass_ && $ctor$$.superClass_.constructor) {
    if($ctor$$.prototype[$opt_methodName$$] === $caller$$) {
      $foundCaller$$ = !0
    }else {
      if($foundCaller$$) {
        return $ctor$$.prototype[$opt_methodName$$].apply($me$$, $args$$)
      }
    }
  }
  if($me$$[$opt_methodName$$] === $caller$$) {
    return $me$$.constructor.prototype[$opt_methodName$$].apply($me$$, $args$$)
  }
  throw Error("goog.base called from a method of one name to a method of a different name");
};
goog.scope = function $goog$scope$($fn$$) {
  $fn$$.call(goog.global)
};
var aws = {StataClient:{}};
goog.exportSymbol("aws", aws);
aws.timeLogString = "";
aws.window = window;
aws.queryService = function $aws$queryService$($url$$, $method$$, $params$$, $resultHandler$$, $queryId$$) {
  $method$$ = {jsonrpc:"2.0", id:$queryId$$ || "no_id", method:$method$$, params:$params$$};
  var $targetWindow$$ = aws.window;
  aws.window = window;
  aws.activeQueryCount++;
  aws.broadcastBusyStatus();
  $.post($url$$, JSON.stringify($method$$), function handleResponse($response$$) {
    aws.activeQueryCount--;
    aws.broadcastBusyStatus();
    $response$$ = $targetWindow$$.JSON.parse($response$$);
    if($response$$.error) {
      console.log(JSON.stringify($response$$, null, 3))
    }else {
      if($resultHandler$$) {
        return $resultHandler$$($response$$.result, $queryId$$)
      }
    }
  }, "text")
};
aws.bulkQueryService = function $aws$bulkQueryService$($url$$, $method$$, $queryIdToParams$$, $resultsHandler$$) {
  var $batch$$ = [], $queryId$$;
  for($queryId$$ in $queryIdToParams$$) {
    $batch$$.push({jsonrpc:"2.0", id:$queryId$$, method:$method$$, params:$queryIdToParams$$[$queryId$$]})
  }
  $.post($url$$, JSON.stringify($batch$$), function handleBatch($batchResponse$$) {
    var $results$$ = Array.isArray($queryIdToParams$$) ? [] : {}, $i$$;
    for($i$$ in $batchResponse$$) {
      var $response$$ = $batchResponse$$[$i$$];
      $response$$.error ? console.log(JSON.stringify($response$$, null, 3)) : $results$$[$response$$.id] = $response$$.result
    }
    $resultsHandler$$ && $resultsHandler$$($results$$)
  }, "json")
};
aws.activeQueryCount = 0;
aws.rpcBusyListeners = [];
aws.broadcastBusyStatus = function $aws$broadcastBusyStatus$() {
  aws.rpcBusyListeners.forEach(function($listener$$) {
    $listener$$(aws.activeQueryCount)
  })
};
aws.addBusyListener = function $aws$addBusyListener$($callback$$) {
  aws.rpcBusyListeners.push($callback$$)
};
aws.AdminClient = {};
var adminServiceURL = "/WeaveServices/AdminService";
aws.AdminClient.updateEntity = function $aws$AdminClient$updateEntity$($user$$, $password$$, $entityId$$, $diff$$, $handleResult$$) {
  aws.queryService(adminServiceURL, "updateEntity", [$user$$, $password$$, $entityId$$, $diff$$], $handleResult$$)
};
aws.DataClient = {};
var dataServiceURL = "/WeaveServices/DataService";
aws.DataClient.getDataTableList = function $aws$DataClient$getDataTableList$($handleResult$$) {
  aws.queryService(dataServiceURL, "getDataTableList", null, $handleResult$$)
};
aws.DataClient.getEntityChildIds = function $aws$DataClient$getEntityChildIds$($id$$, $handleResult$$) {
  aws.queryService(dataServiceURL, "getEntityChildIds", [$id$$], $handleResult$$)
};
aws.DataClient.getListOfProjects = function $aws$DataClient$getListOfProjects$($callback$$) {
  aws.queryService(rServiceURL, "getListOfProjects", null, $callback$$)
};
aws.DataClient.getListOfQueryObjects = function $aws$DataClient$getListOfQueryObjects$($projectName$$, $callback$$) {
  aws.queryService(rServiceURL, "getQueryObjectsInProject", [$projectName$$], $callback$$)
};
aws.DataClient.deleteProject = function $aws$DataClient$deleteProject$($projectName$$, $callback$$) {
  aws.queryService(rServiceURL, "deleteProject", [$projectName$$], $callback$$)
};
aws.DataClient.deleteQueryObject = function $aws$DataClient$deleteQueryObject$($projectName$$, $queryObjectName$$, $callback$$) {
  aws.queryService(rServiceURL, "deleteQueryObject", [$projectName$$, $queryObjectName$$], $callback$$)
};
aws.DataClient.getDataColumnEntities = function $aws$DataClient$getDataColumnEntities$($ids$$, $handleResult$$) {
  aws.queryService(dataServiceURL, "getEntitiesById", [$ids$$], $handleResult$$)
};
aws.DataClient.getColumn = function $aws$DataClient$getColumn$($columnId$$, $minParam$$, $maxParam$$, $sqlParams$$, $handleResult$$) {
  aws.queryService(dataServiceURL, "getColumn", [$columnId$$, $minParam$$, $maxParam$$, $sqlParams$$], $handleResult$$)
};
aws.DataClient.getEntityIdsByMetadata = function $aws$DataClient$getEntityIdsByMetadata$($meta$$, $handleResult$$) {
  aws.queryService(dataServiceURL, "getEntityIdsByMetadata", [$meta$$, 1], $handleResult$$)
};
aws.DataClient.getDataMapping = function $aws$DataClient$getDataMapping$($varValues$$, $callback$$) {
  Array.isArray($varValues$$) ? setTimeout(function() {
    $callback$$($varValues$$)
  }, 0) : ("string" == typeof $varValues$$ && ($varValues$$ = {aws_id:$varValues$$}), aws.queryService(dataServiceURL, "getColumn", [$varValues$$, NaN, NaN, null], function($columnData$$) {
    var $result$$ = [], $i$$;
    for($i$$ in $columnData$$.keys) {
      $result$$[$i$$] = {value:$columnData$$.keys[$i$$], label:$columnData$$.data[$i$$]}
    }
    $callback$$($result$$)
  }))
};
aws.DataClient.getColumn = function $aws$DataClient$getColumn$($columnId$$, $minParam$$, $maxParam$$, $sqlParams$$, $handleResult$$) {
  aws.queryService(dataServiceURL, "getColumn", [$columnId$$, $minParam$$, $maxParam$$, $sqlParams$$], $handleResult$$)
};
aws.DataClient.getColumnsFromIds = function $aws$DataClient$getColumnsFromIds$($ids$$, $handleResult$$) {
  aws.bulkQueryService(dataServiceURL, "getColumn", $ids$$.map(function($id$$) {
    return[$id$$, null, null, null]
  }), $handleResult$$)
};
aws.DataClient.getColumnsFromTableId = function $aws$DataClient$getColumnsFromTableId$($id$$, $handleResult$$) {
  aws.DataClient.getEntityChildIds($id$$, function($ids$$) {
    aws.DataClient.getColumnsFromIds($ids$$, $handleResult$$)
  })
};
aws.DataClient.getEntityIdsByMetadata = function $aws$DataClient$getEntityIdsByMetadata$($meta$$, $handleResult$$) {
  aws.queryService(dataServiceURL, "getEntityIdsByMetadata", [$meta$$, 1], $handleResult$$)
};
aws.DataClient.getDataSet = function $aws$DataClient$getDataSet$($ids$$, $callback$$) {
  aws.queryService(dataServiceURL, "getDataSet", [$ids$$], $callback$$)
};
aws.DataClient.getDataSetFromTableId = function $aws$DataClient$getDataSetFromTableId$($id$$, $callback$$) {
  aws.DataClient.getEntityChildIds($id$$, function($ids$$) {
    aws.DataClient.getDataSet($ids$$, $callback$$)
  })
};
aws.LiveQuery = function $aws$LiveQuery$($url$$, $method$$, $params$$) {
  this.busy = !1;
  this.listeners = [];
  this.waiters = [];
  this.result = null;
  this.url = $url$$;
  this.method = $method$$;
  this.params = null;
  this.last_id = 0;
  this.setParams($params$$)
};
aws.LiveQuery.prototype.setParams = function $aws$LiveQuery$$setParams$($newParams$$) {
  if(aws.LiveQuery.detectParamChange(this.params, $newParams$$)) {
    if(this.params) {
      for(var $k$$ in $newParams$$) {
        this.params[$k$$] = $newParams$$[$k$$]
      }
    }else {
      this.params = $newParams$$
    }
    this.busy = !0;
    var $self$$ = this;
    aws.queryService(this.url, this.method, this.params, function($result$$, $queryId$$) {
      if($queryId$$ == $self$$.last_id) {
        $self$$.busy = !1;
        $self$$.result = $result$$;
        for(var $i$$ in $self$$.listeners) {
          $self$$.listeners[$i$$].call($self$$, $self$$.result)
        }
        for(var $w$$ in $self$$.waiters) {
          $self$$.waiters[$w$$].call($self$$, $self$$.busy)
        }
      }
    }, ++this.last_id);
    for(var $w$$0$$ in this.waiters) {
      this.waiters[$w$$0$$].call(this, this.busy)
    }
  }
};
aws.LiveQuery.prototype.listen = function $aws$LiveQuery$$listen$($listener$$, $callNow$$) {
  this.listeners.push($listener$$);
  !1 !== $callNow$$ && (this.busy || $listener$$.call(this, this.result))
};
aws.LiveQuery.prototype.wait = function $aws$LiveQuery$$wait$($waiter$$, $callNow$$) {
  this.waiters.push($waiter$$);
  !1 !== $callNow$$ && $waiter$$.call(this, this.busy)
};
aws.LiveQuery.prototype.unlisten = function $aws$LiveQuery$$unlisten$($listener$$) {
  delete this.listeners[this.listeners.indexOf($listener$$)]
};
aws.LiveQuery.prototype.unwait = function $aws$LiveQuery$$unwait$($waiter$$) {
  delete this.waiters[this.waiters.indexOf($waiter$$)]
};
aws.LiveQuery.detectParamChange = function $aws$LiveQuery$detectParamChange$($oldParams$$, $newParams$$) {
  void 0 === $oldParams$$ && ($oldParams$$ = null);
  void 0 === $newParams$$ && ($newParams$$ = null);
  var $type$$ = typeof $oldParams$$;
  if($type$$ != typeof $newParams$$) {
    return!0
  }
  if("object" != $type$$) {
    return String($oldParams$$) != String($newParams$$)
  }
  if(!$oldParams$$ != !$newParams$$) {
    return!0
  }
  for(var $k$$ in $newParams$$) {
    if(aws.LiveQuery.detectParamChange($oldParams$$[$k$$], $newParams$$[$k$$])) {
      return!0
    }
  }
  return!1
};
aws.LiveQuery.test = function $aws$LiveQuery$test$() {
  var $listener1$$ = function $$listener1$$$($result$$) {
    this.setParams({publicMetadata:{keyType:"test1"}});
    this.unlisten($listener1$$)
  }, $query1$$ = new aws.LiveQuery("/WeaveServices/DataService", "getEntityIdsByMetadata", {entityType:1, publicMetadata:{keyType:"test"}});
  $query1$$.wait(function($busy$$) {
    console.log("RPC busy: ", $busy$$, "; params: ", JSON.stringify(this.params))
  });
  $query1$$.listen(function($result$$) {
    console.log("result: ", JSON.stringify($result$$))
  });
  $query1$$.listen($listener1$$)
};
var rServiceURL = "/WeaveServices/AWSRService";
aws.RClient = function $aws$RClient$($rRequestObject$$) {
  this.rRequestObject = $rRequestObject$$
};
var resultString = "notReplacedYet";
aws.RClient.prototype.run = function $aws$RClient$$run$($type$$, $callback$$) {
  "SQLData" == $type$$ ? this.runScriptOnSQLdata($callback$$) : "JavaSQLData" == $type$$ && this.runScriptWithFilteredColumns($callback$$);
  "runScriptWithFilteredColumns" == $type$$ && this.runScriptWithFilteredColumns($callback$$)
};
aws.RClient.clearCache = function $aws$RClient$clearCache$() {
  aws.queryService(rServiceURL, "clearCache", null, null)
};
aws.RClient.getListOfScripts = function $aws$RClient$getListOfScripts$($callback$$) {
  aws.queryService(rServiceURL, "getListOfScripts", null, $callback$$)
};
aws.RClient.prototype.runScriptOnSQLdata = function $aws$RClient$$runScriptOnSQLdata$($callback$$) {
  aws.queryService(rServiceURL, "runScriptwithScriptMetadata", [this.connectionObject, this.rRequestObject], $callback$$)
};
aws.RClient.getScriptMetadata = function $aws$RClient$getScriptMetadata$($scriptName$$, $callback$$) {
  aws.queryService(rServiceURL, "getScriptMetadata", [$scriptName$$], $callback$$)
};
aws.RClient.prototype.storeConnection = function $aws$RClient$$storeConnection$($result$$, $queryId$$) {
  this.connectionObject = $result$$
};
aws.RClient.prototype.writeResultsToDatabase = function $aws$RClient$$writeResultsToDatabase$($requestObject$$, $displayWritingStatus$$) {
  aws.queryService(rServiceURL, "writeResultsToDatabase", $requestObject$$, $displayWritingStatus$$)
};
aws.RClient.prototype.displayWritingStatus = function $aws$RClient$$displayWritingStatus$($result$$, $queryId$$) {
};
aws.RClient.prototype.retriveResultsFromDatabase = function $aws$RClient$$retriveResultsFromDatabase$($requestObject$$) {
};
aws.RClient.prototype.runScriptWithFilteredColumns = function $aws$RClient$$runScriptWithFilteredColumns$($callback$$) {
  aws.queryService(rServiceURL, "runScriptWithFilteredColumns", this.rRequestObject, $callback$$)
};
aws.WeaveClient = function $aws$WeaveClient$($weave$$) {
  this.weave = $weave$$
};
aws.WeaveClient.prototype.newVisualization = function $aws$WeaveClient$$newVisualization$($visualization$$, $dataSourceName$$) {
  var $parameters_toolName$$ = $visualization$$.parameters;
  switch($visualization$$.type) {
    case "MapTool":
      return $parameters_toolName$$ = this.newMap($parameters_toolName$$.id, $parameters_toolName$$.title, $parameters_toolName$$.keyType), this.setPosition($parameters_toolName$$, "0%", "0%"), $parameters_toolName$$;
    case "ScatterPlotTool":
      return $parameters_toolName$$ = this.newScatterPlot($parameters_toolName$$.X, $parameters_toolName$$.Y, $dataSourceName$$), this.setPosition($parameters_toolName$$, "50%", "50%"), $parameters_toolName$$;
    case "DataTable":
      return $parameters_toolName$$ = this.newDatatable($parameters_toolName$$, $dataSourceName$$), this.setPosition($parameters_toolName$$, "50%", "0%"), $parameters_toolName$$;
    case "BarChartTool":
      return $parameters_toolName$$ = this.newBarChart($parameters_toolName$$.sort, $parameters_toolName$$.label, $parameters_toolName$$.heights, $dataSourceName$$), this.setPosition($parameters_toolName$$, "0%", "50%"), $parameters_toolName$$
  }
};
aws.WeaveClient.prototype.updateVisualization = function $aws$WeaveClient$$updateVisualization$($visualization$$, $dataSourceName$$) {
  var $parameters$$1_toolName$$ = $visualization$$.parameters;
  switch($visualization$$.type) {
    case "MapTool":
      return $parameters$$1_toolName$$ = this.updateMap($visualization$$.toolName, $parameters$$1_toolName$$.id, $parameters$$1_toolName$$.title, $parameters$$1_toolName$$.keyType), this.setPosition($parameters$$1_toolName$$, "0%", "0%"), $parameters$$1_toolName$$;
    case "ScatterPlotTool":
      return $parameters$$1_toolName$$ = this.updateScatterPlot($visualization$$.toolName, $parameters$$1_toolName$$.X, $parameters$$1_toolName$$.Y, $dataSourceName$$), this.setPosition($parameters$$1_toolName$$, "50%", "50%"), $parameters$$1_toolName$$;
    case "DataTable":
      return $parameters$$1_toolName$$ = this.updateDatatable($visualization$$.toolName, $parameters$$1_toolName$$, $dataSourceName$$), this.setPosition($parameters$$1_toolName$$, "50%", "0%"), $parameters$$1_toolName$$;
    case "BarChartTool":
      return $parameters$$1_toolName$$ = this.updateBarChart($visualization$$.toolName, $parameters$$1_toolName$$.sort, $parameters$$1_toolName$$.label, $parameters$$1_toolName$$.heights, $dataSourceName$$), this.setPosition($parameters$$1_toolName$$, "0%", "50%"), $parameters$$1_toolName$$
  }
};
aws.WeaveClient.prototype.newMap = function $aws$WeaveClient$$newMap$($entityId$$, $title$$, $keyType$$) {
  var $toolName$$ = this.weave.path().getValue('generateUniqueName("MapTool")');
  this.weave.path($toolName$$).request("MapTool");
  this.weave.path().push($toolName$$, "children", "visualization", "plotManager", "plotters", "Geometries").request("weave.visualization.plotters::GeometryPlotter").push("geometryColumn", "internalDynamicColumn", null).request("ReferencedColumn").push("dynamicColumnReference", null).request("HierarchyColumnReference").state({dataSourceName:"WeaveDataSource", hierarchyPath:'\x3cattribute keyType\x3d"' + $keyType$$ + '" weaveEntityId\x3d"' + $entityId$$ + '" title\x3d "' + $title$$ + '" projection\x3d"EPSG:2964" dataType\x3d"geometry"/\x3e'});
  return $toolName$$
};
aws.WeaveClient.prototype.updateMap = function $aws$WeaveClient$$updateMap$($toolName$$, $entityId$$, $title$$, $keyType$$) {
  void 0 == $toolName$$ && ($toolName$$ = this.weave.path().getValue('generateUniqueName("MapTool")'));
  this.weave.path($toolName$$).request("MapTool");
  this.weave.path().push($toolName$$, "children", "visualization", "plotManager", "plotters", "Geometries").request("weave.visualization.plotters::GeometryPlotter").push("geometryColumn", "internalDynamicColumn", null).request("ReferencedColumn").push("dynamicColumnReference", null).request("HierarchyColumnReference").state({dataSourceName:"WeaveDataSource", hierarchyPath:'\x3cattribute keyType\x3d"' + $keyType$$ + '" weaveEntityId\x3d"' + $entityId$$ + '" title\x3d "' + $title$$ + '" projection\x3d"EPSG:2964" dataType\x3d"geometry"/\x3e'});
  return $toolName$$
};
aws.WeaveClient.prototype.newScatterPlot = function $aws$WeaveClient$$newScatterPlot$($xColumnName$$, $yColumnName$$, $dataSourceName$$) {
  var $toolName$$ = this.weave.path().getValue('generateUniqueName("ScatterPlotTool")');
  this.weave.path($toolName$$).request("ScatterPlotTool");
  var $columnPathX$$ = this.weave.path($toolName$$, "children", "visualization", "plotManager", "plotters", "plot", "dataX").getPath(), $columnPathY$$ = this.weave.path($toolName$$, "children", "visualization", "plotManager", "plotters", "plot", "dataY").getPath();
  this.setCSVColumn($dataSourceName$$, $columnPathX$$, $xColumnName$$);
  this.setCSVColumn($dataSourceName$$, $columnPathY$$, $yColumnName$$);
  return $toolName$$
};
aws.WeaveClient.prototype.updateScatterPlot = function $aws$WeaveClient$$updateScatterPlot$($toolName$$, $xColumnName$$, $yColumnName$$, $dataSourceName$$) {
  void 0 == $toolName$$ && ($toolName$$ = this.weave.path().getValue('generateUniqueName("ScatterPlotTool")'));
  this.weave.path($toolName$$).request("ScatterPlotTool");
  var $columnPathX$$ = this.weave.path($toolName$$, "children", "visualization", "plotManager", "plotters", "plot", "dataX").getPath(), $columnPathY$$ = this.weave.path($toolName$$, "children", "visualization", "plotManager", "plotters", "plot", "dataY").getPath();
  this.setCSVColumn($dataSourceName$$, $columnPathX$$, $xColumnName$$);
  this.setCSVColumn($dataSourceName$$, $columnPathY$$, $yColumnName$$);
  return $toolName$$
};
aws.WeaveClient.prototype.newDatatable = function $aws$WeaveClient$$newDatatable$($columnNames$$, $dataSourceName$$) {
  var $toolName$$ = this.weave.path().getValue('generateUniqueName("DataTableTool")');
  this.weave.path($toolName$$).request("DataTableTool");
  for(var $i$$ in $columnNames$$) {
    var $columnPath$$ = this.weave.path($toolName$$, "columns", $columnNames$$[$i$$]).getPath();
    this.setCSVColumn($dataSourceName$$, $columnPath$$, $columnNames$$[$i$$])
  }
  return $toolName$$
};
aws.WeaveClient.prototype.updateDatatable = function $aws$WeaveClient$$updateDatatable$($toolName$$, $columnNames$$, $dataSourceName$$) {
  void 0 == $toolName$$ && ($toolName$$ = this.weave.path().getValue('generateUniqueName("DataTableTool")'));
  this.weave.path($toolName$$).request("DataTableTool");
  this.weave.path($toolName$$, "columns").state(null);
  for(var $i$$ in $columnNames$$) {
    var $columnPath$$ = this.weave.path($toolName$$, "columns", $columnNames$$[$i$$]).getPath();
    this.setCSVColumn($dataSourceName$$, $columnPath$$, $columnNames$$[$i$$])
  }
  return $toolName$$
};
aws.WeaveClient.prototype.newRadviz = function $aws$WeaveClient$$newRadviz$($columnNames$$, $dataSourceName$$) {
  var $toolName$$ = this.weave.path().getValue('generateUniqueName("RadVizTool")');
  this.weave.path($toolName$$).request("RadVizTool");
  for(var $i$$ in $columnNames$$) {
    var $columnPath$$ = this.weave.path($toolName$$, $toolName$$, "children", "visualization", "plotManager", "plotters", "plot", "columns", $columnNames$$[$i$$]).getPath();
    this.setCSVColumn($dataSourceName$$, $columnPath$$, $columnNames$$[$i$$])
  }
};
aws.WeaveClient.prototype.updateRadviz = function $aws$WeaveClient$$updateRadviz$($toolName$$, $columnNames$$, $dataSourceName$$) {
  void 0 == $toolName$$ && ($toolName$$ = this.weave.path().getValue('generateUniqueName("RadVizTool")'));
  this.weave.path($toolName$$).request("RadVizTool");
  for(var $i$$ in $columnNames$$) {
    var $columnPath$$ = this.weave.path($toolName$$, $toolName$$, "children", "visualization", "plotManager", "plotters", "plot", "columns", $columnNames$$[$i$$]).getPath();
    this.setCSVColumn($dataSourceName$$, $columnPath$$, $columnNames$$[$i$$])
  }
};
aws.WeaveClient.prototype.newBarChart = function $aws$WeaveClient$$newBarChart$($heightColumnPath_sort$$, $label$$, $heights$$, $dataSourceName$$) {
  var $toolName$$ = this.weave.path().getValue('generateUniqueName("CompoundBarChartTool")');
  this.weave.path($toolName$$).request("CompoundBarChartTool");
  var $labelPath$$ = this.weave.path($toolName$$, "children", "visualization", "plotManager", "plotters", "plot", "labelColumn").getPath(), $sortColumnPath$$ = this.weave.path($toolName$$, "children", "visualization", "plotManager", "plotters", "plot", "sortColumn").getPath();
  this.setCSVColumn($dataSourceName$$, $labelPath$$, $label$$);
  this.setCSVColumn($dataSourceName$$, $sortColumnPath$$, $heightColumnPath_sort$$);
  this.weave.path($toolName$$, "children", "visualization", "plotManager", "plotters", "plot", "heightColumns").state(null);
  for(var $i$$ in $heights$$) {
    $heightColumnPath_sort$$ = this.weave.path($toolName$$, "children", "visualization", "plotManager", "plotters", "plot", "heightColumns", $heights$$[$i$$]).getPath(), this.setCSVColumn($dataSourceName$$, $heightColumnPath_sort$$, $heights$$[$i$$])
  }
  return $toolName$$
};
aws.WeaveClient.prototype.updateBarChart = function $aws$WeaveClient$$updateBarChart$($toolName$$, $heightColumnPath$$1_sort$$, $label$$, $heights$$, $dataSourceName$$) {
  void 0 == $toolName$$ && ($toolName$$ = this.weave.path().getValue('generateUniqueName("CompoundBarChartTool")'));
  this.weave.path($toolName$$).request("CompoundBarChartTool");
  var $labelPath$$ = this.weave.path($toolName$$, "children", "visualization", "plotManager", "plotters", "plot", "labelColumn").getPath(), $sortColumnPath$$ = this.weave.path($toolName$$, "children", "visualization", "plotManager", "plotters", "plot", "sortColumn").getPath();
  this.setCSVColumn($dataSourceName$$, $labelPath$$, $label$$);
  this.setCSVColumn($dataSourceName$$, $sortColumnPath$$, $heightColumnPath$$1_sort$$);
  this.weave.path($toolName$$, "children", "visualization", "plotManager", "plotters", "plot", "heightColumns").state(null);
  for(var $i$$ in $heights$$) {
    $heightColumnPath$$1_sort$$ = this.weave.path($toolName$$, "children", "visualization", "plotManager", "plotters", "plot", "heightColumns", $heights$$[$i$$]).getPath(), this.setCSVColumn($dataSourceName$$, $heightColumnPath$$1_sort$$, $heights$$[$i$$])
  }
  return $toolName$$
};
aws.WeaveClient.prototype.setPosition = function $aws$WeaveClient$$setPosition$($toolName$$, $posX$$, $posY$$) {
  this.weave.path($toolName$$).push("panelX").state($posX$$).pop().push("panelY").state($posY$$)
};
aws.WeaveClient.prototype.addCSVDataSourceFromString = function $aws$WeaveClient$$addCSVDataSourceFromString$($csvDataString$$, $dataSourceName$$, $keyType$$, $keyColName$$) {
  "" == $dataSourceName$$ && ($dataSourceName$$ = this.weave.path().getValue('generateUniqueName("CSVDataSource")'));
  this.weave.path($dataSourceName$$).request("CSVDataSource").vars({data:$csvDataString$$}).exec("setCSVDataString(data)");
  this.weave.path($dataSourceName$$).state({keyType:$keyType$$, keyColName:$keyColName$$});
  return $dataSourceName$$
};
aws.WeaveClient.prototype.addCSVDataSource = function $aws$WeaveClient$$addCSVDataSource$($csvDataMatrix$$, $dataSourceName$$, $keyType$$, $keyColName$$) {
  "" == $dataSourceName$$ && ($dataSourceName$$ = this.weave.path().getValue('generateUniqueName("CSVDataSource")'));
  this.weave.path($dataSourceName$$).request("CSVDataSource").vars({rows:$csvDataMatrix$$}).exec("setCSVData(rows)");
  this.weave.path($dataSourceName$$).state({keyType:$keyType$$, keyColName:$keyColName$$});
  return $dataSourceName$$
};
aws.WeaveClient.prototype.setCSVColumn = function $aws$WeaveClient$$setCSVColumn$($csvDataSourceName$$, $columnPath$$, $columnName$$) {
  this.weave.path($csvDataSourceName$$).vars({i:$columnName$$, p:$columnPath$$}).exec("putColumn(i,p)")
};
aws.WeaveClient.prototype.setColorAttribute = function $aws$WeaveClient$$setColorAttribute$($colorColumnName$$, $csvDataSource$$) {
  var $colorPath$$ = this.weave.path("defaultColorDataColumn", "internalDynamicColumn").getPath();
  this.setCSVColumn($csvDataSource$$, $colorPath$$, $colorColumnName$$)
};
aws.WeaveClient.prototype.setVisualizationTitle = function $aws$WeaveClient$$setVisualizationTitle$($toolName$$, $enableTitle$$, $title$$) {
  this.weave.path($toolName$$, "enableTitle").state($enableTitle$$);
  this.weave.path($toolName$$, "panelTitle").state($title$$)
};
aws.WeaveClient.prototype.clearWeave = function $aws$WeaveClient$$clearWeave$() {
  this.weave.path().state(["WeaveDataSource"])
};
aws.WeaveClient.prototype.reportToolInteractionTime = function $aws$WeaveClient$$reportToolInteractionTime$($message$$) {
  var $time$$ = aws.reportTime();
  this.weave.evaluateExpression([], "WeaveAPI.ProgressIndictor.getNormalizedProgress()", {}, ["weave.api.WeaveAPI"]);
  console.log($time$$);
  try {
    $("#LogBox").append($time$$ + $message$$ + "\n")
  }catch($e$$) {
  }
};
aws.QueryHandler = function $aws$QueryHandler$($queryObject$$) {
  this.title = $queryObject$$.title;
  this.dateGenerated = $queryObject$$.date;
  this.author = $queryObject$$.author;
  this.rRequestObject = {};
  this.rRequestObject.scriptName = "";
  this.rRequestObject.FilteredColumnRequest = [];
  $queryObject$$.hasOwnProperty("scriptSelected") && ("" != $queryObject$$.scriptSelected ? this.rRequestObject.scriptName = $queryObject$$.scriptSelected : console.log("no script selected"));
  $queryObject$$.hasOwnProperty("projectSelected") && ("" != $queryObject$$.projectSelected ? this.rRequestObject.projectName = $queryObject$$.projectSelected : console.log("no project selected"));
  if($queryObject$$.hasOwnProperty("FilteredColumnRequest")) {
    for(var $i$$ = 0;$i$$ < $queryObject$$.FilteredColumnRequest.length;$i$$++) {
      if(this.rRequestObject.FilteredColumnRequest[$i$$] = {id:-1, filters:[]}, $queryObject$$.FilteredColumnRequest[$i$$].hasOwnProperty("column") && (this.rRequestObject.FilteredColumnRequest[$i$$].id = $queryObject$$.FilteredColumnRequest[$i$$].column.id), $queryObject$$.FilteredColumnRequest[$i$$].hasOwnProperty("filters") && $queryObject$$.FilteredColumnRequest[$i$$].filters.hasOwnProperty("enabled")) {
        if(!0 == $queryObject$$.FilteredColumnRequest[$i$$].filters.enabled) {
          var $temp$$ = [];
          $queryObject$$.FilteredColumnRequest[$i$$].filters.hasOwnProperty("filterValues") && $queryObject$$.FilteredColumnRequest[$i$$].filters.filterValues[0].constructor == Object && ($temp$$ = $.map($queryObject$$.FilteredColumnRequest[$i$$].filters.filterValues, function($item$$) {
            return $item$$.value
          }));
          this.rRequestObject.FilteredColumnRequest[$i$$].filters = $temp$$
        }else {
          $queryObject$$.FilteredColumnRequest[$i$$].filters.filterValues[0].constructor == Array && ($temp$$ = [], $queryObject$$.FilteredColumnRequest[$i$$].filters.hasOwnProperty("filterValues") && $queryObject$$.FilteredColumnRequest[$i$$].filters.filterValues[0].constructor == Object && ($temp$$ = $.map($queryObject$$.FilteredColumnRequest[$i$$].filters.filterValues, function($item$$) {
            return $item$$
          })), this.rRequestObject.FilteredColumnRequest[$i$$].filters = $temp$$)
        }
      }
    }
  }
  this.keyType = "";
  $queryObject$$.hasOwnProperty("ColorColumn") && !0 == $queryObject$$.ColorColumn.enabled && (this.ColorColumn = $queryObject$$.ColorColumn.selected);
  this.visualizations = [];
  $queryObject$$.hasOwnProperty("MapTool") && !0 == $queryObject$$.MapTool.enabled && (this.keyType = $queryObject$$.MapTool.selected.keyType, this.visualizations.push({type:"MapTool", parameters:$queryObject$$.MapTool.selected, title:$queryObject$$.MapTool.title, enableTitle:$queryObject$$.MapTool.enableTitle}));
  $queryObject$$.hasOwnProperty("ScatterPlotTool") && !0 == $queryObject$$.ScatterPlotTool.enabled && this.visualizations.push({type:"ScatterPlotTool", parameters:{X:$queryObject$$.ScatterPlotTool.X, Y:$queryObject$$.ScatterPlotTool.Y}, title:$queryObject$$.ScatterPlotTool.title, enableTitle:$queryObject$$.ScatterPlotTool.enableTitle});
  $queryObject$$.hasOwnProperty("BarChartTool") && !0 == $queryObject$$.BarChartTool.enabled && this.visualizations.push({type:"BarChartTool", parameters:{heights:$queryObject$$.BarChartTool.heights, sort:$queryObject$$.BarChartTool.sort, label:$queryObject$$.BarChartTool.label}, title:$queryObject$$.BarChartTool.title, enableTitle:$queryObject$$.ScatterPlotTool.enableTitle});
  $queryObject$$.hasOwnProperty("DataTableTool") && !0 == $queryObject$$.DataTableTool.enabled && this.visualizations.push({type:"DataTable", parameters:$queryObject$$.DataTableTool.selected});
  this.currentVisualizations = {};
  this.ComputationEngine = null;
  if("r" == $queryObject$$.ComputationEngine || "R" == $queryObject$$.ComputationEngine) {
    this.ComputationEngine = new aws.RClient(this.rRequestObject)
  }
  this.resultDataSet = ""
};
var newWeaveWindow;
aws.QueryHandler.prototype.runQuery = function $aws$QueryHandler$$runQuery$() {
  var $that$$ = this;
  $("#LogBox").html("");
  if(!newWeaveWindow || newWeaveWindow.closed) {
    newWeaveWindow = window.open("aws/visualization/weave/weave.html", "abc", "toolbar\x3dno, fullscreen \x3d no, scrollbars\x3dyes, addressbar\x3dno, resizable\x3dyes")
  }
  newWeaveWindow.log && newWeaveWindow.log("Running Query in R...");
  this.ComputationEngine.run("runScriptWithFilteredColumns", function($result$$) {
    aws.timeLogString = "";
    $that$$.resultDataSet = $result$$.data[0].value;
    $("#LogBox").append("\x3cp\x3eData Load Time: " + $result$$.times[0] / 1E3 + " seconds.\n\x3c/p\x3e");
    $("#LogBox").append("R Script Computation Time: " + $result$$.times[1] / 1E3 + " seconds.\x3c/p\x3e");
    newWeaveWindow.workOnData($that$$, $result$$.data[0].value)
  })
};
aws.QueryHandler.prototype.clearWeave = function $aws$QueryHandler$$clearWeave$() {
  newWeaveWindow && newWeaveWindow.clearWeave(this)
};
aws.QueryHandler.prototype.updateVisualizations = function $aws$QueryHandler$$updateVisualizations$($queryObject$$) {
  this.visualizations = [];
  $queryObject$$.hasOwnProperty("ColorColumn") && !0 == $queryObject$$.ColorColumn.enabled && (this.ColorColumn = $queryObject$$.ColorColumn.selected);
  this.visualizations = [];
  $queryObject$$.hasOwnProperty("MapTool") && !0 == $queryObject$$.MapTool.enabled && (this.keyType = $queryObject$$.MapTool.keyType, this.visualizations.push({type:"MapTool", parameters:$queryObject$$.MapTool.selected, title:$queryObject$$.MapTool.title, enableTitle:$queryObject$$.MapTool.enableTitle}));
  $queryObject$$.hasOwnProperty("ScatterPlotTool") && !0 == $queryObject$$.ScatterPlotTool.enabled && this.visualizations.push({type:"ScatterPlotTool", parameters:{X:$queryObject$$.ScatterPlotTool.X, Y:$queryObject$$.ScatterPlotTool.Y}, title:$queryObject$$.ScatterPlotTool.title, enableTitle:$queryObject$$.ScatterPlotTool.enableTitle});
  $queryObject$$.hasOwnProperty("BarChartTool") && !0 == $queryObject$$.BarChartTool.enabled && this.visualizations.push({type:"BarChartTool", parameters:{heights:$queryObject$$.BarChartTool.heights, sort:$queryObject$$.BarChartTool.sort, label:$queryObject$$.BarChartTool.label}, title:$queryObject$$.BarChartTool.title, enableTitle:$queryObject$$.ScatterPlotTool.enableTitle});
  $queryObject$$.hasOwnProperty("DataTableTool") && !0 == $queryObject$$.DataTableTool.enabled && this.visualizations.push({type:"DataTable", parameters:$queryObject$$.DataTableTool.selected});
  newWeaveWindow.updateVisualizations(this)
};

//@ sourceMappingURL=aws-source-map.json