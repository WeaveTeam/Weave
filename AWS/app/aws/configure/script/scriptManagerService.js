angular.module('aws.configure.script').service("scriptManagerService", ['$q', '$rootScope', function($q, scope) {
     
	  var scriptServiceURL = "/WeaveAnalystServices/ScriptManagementServlet";
	  
	  this.getScript = function(scriptName) {
		  
		  var deferred = $q.defer();
		  
		  aws.queryService(scriptServiceURL, 'getScript', [scriptName], function(result) {
	          scope.$apply(function() {
	            deferred.resolve(result);
	          });
	      });
	      return deferred.promise;
		  
	  };
	  
	  this.deleteScript = function(scriptName) {
		  
		  var deferred = $q.defer();
		  
		  aws.queryService(scriptServiceURL, 'deleteScript', [scriptName], function(result) {
	          scope.$apply(function() {
	            deferred.resolve(result);
	          });
	      });
	      return deferred.promise;
		  
	  };
	  
	  this.getListOfScripts = function () {
		  
		  var deferred = $q.defer();
		  
		  aws.queryService(scriptServiceURL, 'getListOfScripts', null, function(result) {
	          scope.$apply(function() {
	            deferred.resolve(result);
	          });
	      });
	      return deferred.promise;
	      
	  };
	  
	  this.getListOfRScripts = function () {
		  
		  var deferred = $q.defer();
		  
		  aws.queryService(scriptServiceURL, 'getListOfRScripts', null, function(result) {
	          scope.$apply(function() {
	            deferred.resolve(result);
	          });
	      });
	      return deferred.promise;
	      
	  };
	  
	  this.getListOfStataScripts = function () {
		  
		  var deferred = $q.defer();
		  
		  aws.queryService(scriptServiceURL, 'getListOfStataScripts', null, function(result) {
	          scope.$apply(function() {
	            deferred.resolve(result);
	          });
	      });
	      return deferred.promise;
	      
	  };
	  
	  this.getScriptMetadata = function (scriptName) {
		  
		  var deferred = $q.defer();
		  
		  aws.queryService(scriptServiceURL, 'getScriptMetadata', [scriptName], function(result) {
	          scope.$apply(function() {
	            deferred.resolve(result);
	          });
	      });
	      return deferred.promise;	
	  };
	  
	  
	  this.saveScriptMetadata = function (scriptName, metadata) {
		  
		  var deferred = $q.defer();
		  aws.queryService(scriptServiceURL, 'saveScriptMetadata', [scriptName, metadata], function(result) {
	          scope.$apply(function() {
	            deferred.resolve(result);
	          });
	      });
	      return deferred.promise;	
		  
	  };
	  
	  this.saveScriptContent = function (scriptName, content) {
		  
		  var deferred = $q.defer();
		  aws.queryService(scriptServiceURL, 'saveScriptContent', [scriptName, content], function(result) {
	          scope.$apply(function() {
	            deferred.resolve(result);
	          });
	      });
	      return deferred.promise;	
	  };
	  
	  this.renameScript = function(oldScriptName, newScriptName, content, metadata) {
		  var deferred = $q.defer();
		  aws.queryService(scriptServiceURL, 'renameScript', [oldScriptName, newScriptName, content, metadata], function(result) {
	          scope.$apply(function() {
	            deferred.resolve(result);
	          });
	      });
	      return deferred.promise;
	  };
	  
	  this.uploadNewScript = function (script, metadata) {
		  
		  var deferred = $q.defer();
		  
		  aws.queryService(scriptServiceURL, 'uploadNewScript', [scriptName, metadata], function(result) {
	          scope.$apply(function() {
	            deferred.resolve(result);
	          });
	      });
	      return deferred.promise;	
		  
	  };
  }]);