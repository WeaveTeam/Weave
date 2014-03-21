angular.module('aws.configure.script')
  .service("scriptManagerService", ['$q', '$rootScope', function($q, scope) {
      this.dataObject = {
        scriptName: ""
      };
      var that = this;
      var refreshNeeded = true;
      this.getListOfScripts = function() {
        if(!refreshNeeded && this.dataObject.listOfScripts){
          return this.dataObject.listOfScripts;
        }
        var deferred = $q.defer();
        aws.RClient.getListOfScripts(function(result) {
          that.dataObject.listOfScripts = result;
          scope.$apply(function() {
            deferred.resolve(result);
          });
        });
        refreshNeeded = false;
        return deferred.promise;
      };
      
      this.refreshScriptInfo = function(scriptName){
        if(scriptName == this.dataObject.scriptName){
          return;
        }
        this.dataObject.scriptName = scriptName;
        this.getScriptMetadata();
        this.getScript();
      };
      
      this.uploadNewScript = function(file){
        var deferred = $q.defer();
        aws.RClient.uploadNewScript(file.filename, file.contents, function(result){
          console.log(result); // currently just string returned from servlet
          scope.$safeApply(function() { deferred.resolve(result); });
        });
        refreshNeeded = true;
        return deferred.promise;
      };
      
      
      /**
       * This function wraps the async aws getListOfScripts function into
       * an angular defer/promise So that the UI asynchronously wait for
       * the data to be available...
       */
       this.getScriptMetadata = function(){
        var deferred = $q.defer();
        aws.RClient.getScriptMetadata(this.dataObject.scriptName, function(result) {
          that.dataObject.scriptMetadata = result;
          scope.$safeApply(function() { deferred.resolve(result); });
        });
        return deferred.promise;
      };
      
      this.getScript = function(){
        var deferred = $q.defer();
        aws.RClient.getScript(this.dataObject.scriptName, function(result){
          that.dataObject.scriptContent = result;
          scope.$safeApply(function(){deferred.resolve(result);});
        });
        return deferred.promise;
      };
      this.saveChangedMetadata = function(metadata){
        var deferred = $q.defer();
        this.dataObject.scriptMetadata = metadata;
        aws.RClient.saveMetadata(this.dataObject.scriptName ,this.dataObject.scriptMetadata, function(){
          scope.$safeApply(function(result){
            if(result.error){
              deferred.reject();
            } else{
              deferred.resolve(true);
            }
          });
        });
        return deferred.promise;
      };
    }
  ]);