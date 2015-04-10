angular.module('aws.configure.script').service("scriptManagerService", ['$q', '$rootScope','runQueryService', function($q, scope, runQueryService) {
     
	  var scriptServiceURL = "/WeaveAnalystServices/ScriptManagementServlet";
	  
	  this.getScript = function(scriptName) {
		  
		  var deferred = $q.defer();
		  
		  runQueryService.queryRequest(scriptServiceURL, 'getScript', [scriptName], function(result) {
	          scope.$apply(function() {
	            deferred.resolve(result);
	          });
	      });
	      return deferred.promise;
		  
	  };
	  
	  this.deleteScript = function(scriptName) {
		  
		  var deferred = $q.defer();
		  
		  runQueryService.queryRequest(scriptServiceURL, 'deleteScript', [scriptName], function(result) {
	          scope.$apply(function() {
	            deferred.resolve(result);
	          });
	      });
	      return deferred.promise;
		  
	  };
	  
	  this.getListOfScripts = function () {
		  
		  var deferred = $q.defer();
		  
		  runQueryService.queryRequest(scriptServiceURL, 'getListOfScripts', null, function(result) {
	          scope.$apply(function() {
	            deferred.resolve(result);
	          });
	      });
	      return deferred.promise;
	      
	  };
	  
	  this.getListOfRScripts = function () {
		  
		  var deferred = $q.defer();
		  
		  runQueryService.queryRequest(scriptServiceURL, 'getListOfRScripts', null, function(result) {
	          scope.$apply(function() {
	            deferred.resolve(result);
	          });
	      });
	      return deferred.promise;
	      
	  };
	  
	  this.getListOfStataScripts = function () {
		  
		  var deferred = $q.defer();
		  
		  runQueryService.queryRequest(scriptServiceURL, 'getListOfStataScripts', null, function(result) {
	          scope.$apply(function() {
	            deferred.resolve(result);
	          });
	      });
	      return deferred.promise;
	      
	  };
	  
	  this.getScriptMetadata = function (scriptName) {
		  
		  var deferred = $q.defer();
		  
		  runQueryService.queryRequest(scriptServiceURL, 'getScriptMetadata', [scriptName], function(result) {
	          scope.$apply(function() {
	            deferred.resolve(result);
	          });
	      }, function(error) {
				scope.$safeApply(function() {
					deferred.reject(error);
				});
		  });
	      return deferred.promise;	
	  };
	  
	  
	  this.saveScriptMetadata = function (scriptName, metadata) {
		  
		  var deferred = $q.defer();
		  runQueryService.queryRequest(scriptServiceURL, 'saveScriptMetadata', [scriptName, metadata], function(result) {
	          scope.$apply(function() {
	            deferred.resolve(result);
	          });
	      });
	      return deferred.promise;	
		  
	  };
	  
	  this.scriptExists = function (scriptName) {
		  var deferred = $q.defer();
		  runQueryService.queryRequest(scriptServiceURL, 'scriptExists', [scriptName], function(result) {
			  scope.$apply(function() {
		            deferred.resolve(result);
		          });
		  });
		  return deferred.promise;
	  };
	  
	  this.saveScriptContent = function (scriptName, content) {
		  
		  var deferred = $q.defer();
		  runQueryService.queryRequest(scriptServiceURL, 'saveScriptContent', [scriptName, content], function(result) {
	          scope.$apply(function() {
	            deferred.resolve(result);
	          });
	      });
	      return deferred.promise;	
	  };
	  
	  this.renameScript = function(oldScriptName, newScriptName, content, metadata) {
		  var deferred = $q.defer();
		  runQueryService.queryRequest(scriptServiceURL, 'renameScript', [oldScriptName, newScriptName, content, metadata], function(result) {
	          scope.$apply(function() {
	            deferred.resolve(result);
	          });
	      });
	      return deferred.promise;
	  };
	  
	  this.uploadNewScript = function (scriptName, content, metadata) {
		  
		  var deferred = $q.defer();
		  
		  runQueryService.queryRequest(scriptServiceURL, 'uploadNewScript', [scriptName, content, metadata], function(result) {
	          scope.$apply(function() {
	            deferred.resolve(result);
	          });
	      });
	      return deferred.promise;	
		  
	  };
  }]);