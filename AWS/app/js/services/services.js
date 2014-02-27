'use strict';
/**
 * Query Object Service provides access to the main "singleton" query object.
 *
 * Don't worry, it will be possible to manage more than one query object in the
 * future.
 */
angular.module("aws.services", []).service("queryService", ['$q', '$rootScope', function($q, scope) {
    
	var that = this;
	this.queryObject = {
			title : "Beta Query Object",
			date : new Date(),
    		author : "",
			ComputationEngine : "R"
	};    		
    
	this.dataObject = {};
	/**
     * This function wraps the async aws getListOfScripts function into an angular defer/promise
     * So that the UI asynchronously wait for the data to be available...
     */
    this.getListOfScripts = function() {
        
    	if(this.dataObject.listOfScripts) {
    		return this.dataObject.listOfScripts;
    	}
    	
    	
    	var deferred = $q.defer();

        aws.RClient.getListOfScripts(function(result) {
            
        	that.dataObject.listOfScripts = result;
        	
        	// since this function executes async in a future turn of the event loop, we need to wrap
            // our code into an $apply call so that the model changes are properly observed.
        	scope.$safeApply(function() {
                deferred.resolve(result);
            });
        	
        });
        
        // regardless of when the promise was or will be resolved or rejected,
        // then calls one of the success or error callbacks asynchronously as soon as the result
        // is available. The callbacks are called with a single argument: the result or rejection reason.
        return deferred.promise;
        
    };
    /**
     * This function wraps the async aws getListOfProjects function into an angular defer/promise
     * So that the UI asynchronously wait for the data to be available...
     */
    this.getListOfProjects = function() {
        
    	if(this.dataObject.listOfProjects) {
    		return this.dataObject.listOfProjects;
    	}
    	
    	
    	var deferred = $q.defer();

        aws.DataClient.getListOfProjects(function(result) {
            
        	that.dataObject.listOfProjects = result;
        	
        	scope.$safeApply(function() {
                deferred.resolve(result);
            });
        	
        });
        
        return deferred.promise;
        
    };
    
    
    /**
     * This function wraps the async aws deleteproject function into an angular defer/promise
     * So that the UI asynchronously wait for the data to be available...
     */
    this.deleteProject = function() {
          	
    	var deferred = $q.defer();

        aws.DataClient.deleteProject(projectName, function(result) {
            
        	that.dataObject.deleteStatus = result;//returns a boolean which states if the project has been deleted(true)
        	
        	scope.$safeApply(function() {
                deferred.resolve(result);
            });
        	
        });
        
        return deferred.promise;
        
    };
    
    
    /**
     * This function wraps the async aws getQueryObjectsInProject function into an angular defer/promise
     * So that the UI asynchronously wait for the data to be available...
     */
    this.getListOfQueryObjectsInProject = function(projectName) {
    	
//    	if(this.dataObject.listofQueryObjectsInProject) {
//    		return this.dataObject.listofQueryObjectsInProject;
//    	}
	
    	
    	var deferred = $q.defer();

        aws.DataClient.getListOfQueryObjects(projectName, function(result) {
            
        	that.dataObject.listofQueryObjectsInProject = result;
        	
        	scope.$safeApply(function() {
                deferred.resolve(result);
            });
        	
        });
        
        return deferred.promise;
        
    };
    
    
    
    /**
     * This function wraps the async aws getListOfScripts function into an angular defer/promise
     * So that the UI asynchronously wait for the data to be available...
     */
    this.getScriptMetadata = function(scriptName, forceUpdate) {
        var deferred = $q.defer();
        if (!forceUpdate) {
        	if (this.dataObject.scriptMetadata) {
        		return this.dataObject.scriptMetadata;
        	}
        }
        
        aws.RClient.getScriptMetadata(scriptName, function(result) {
        	
        	that.dataObject.scriptMetadata = result;
        	// since this function executes async in a future turn of the event loop, we need to wrap
            // our code into an $apply call so that the model changes are properly observed.
            scope.$safeApply(function() {
                deferred.resolve(result);
            });
        });
      
        // regardless of when the promise was or will be resolved or rejected,
 	    // then calls one of the success or error callbacks asynchronously as soon as the result
     	// is available. The callbacks are called with a single argument: the result or rejection reason.
        return deferred.promise;
    };

		/**
    	  * This function makes nested async calls to the aws function getEntityChildIds and
    	  * getDataColumnEntities in order to get an array of dataColumnEntities children of the given id.
    	  * We use angular deferred/promises so that the UI asynchronously wait for the data to be available...
    	  */
    	this.getDataColumnsEntitiesFromId = function(id, forceUpdate) {
            
    		if(!forceUpdate) {
	    		if (this.dataObject.columns) {
	    			return this.dataObject.columns;
	    		}
    		}

    		var deferred = $q.defer();
    		
            aws.DataClient.getEntityChildIds(id, function(idsArray) {
                scope.$safeApply(function() {
                    deferred.resolve(idsArray);
                });
            });
            
            var deferred2 = $q.defer();
            
            deferred.promise.then(function(idsArray) {
            	
            	aws.DataClient.getDataColumnEntities(idsArray, function(dataEntityArray) {
            		
            		that.dataObject.columns = dataEntityArray;
            		
            		scope.$safeApply(function() {
                    	deferred2.resolve(dataEntityArray);
                    });
                });
            });
            
            return deferred2.promise;

        };
        
        /**
    	  * This function makes nested async calls to the aws function getEntityIdsByMetadata and
    	  * getDataColumnEntities in order to get an array of dataColumnEntities children that have metadata of type geometry.
    	  * We use angular deferred/promises so that the UI asynchronously wait for the data to be available...
    	  */
    	this.getGeometryDataColumnsEntities = function(resultHandler) {
            
    		if (this.dataObject.geometryColumns) {
    			return this.dataObject.geometryColumns;
    		}
    		
    		var deferred = $q.defer();
    		
            aws.DataClient.getEntityIdsByMetadata({"dataType":"geometry"}, function(idsArray) {
                scope.$safeApply(function() {
                    deferred.resolve(idsArray);
                });
            });
            
            var deferred2 = $q.defer();
            
            deferred.promise.then(function(idsArray) {
            	
            	aws.DataClient.getDataColumnEntities(idsArray, function(dataEntityArray) {
                    that.dataObject.geometryColumns = dataEntityArray;
                    
            		scope.$safeApply(function() {
                    	deferred2.resolve(dataEntityArray);
                    });
                });
            	
            });
            
            return deferred2.promise;
        };
        
        /**
         * This function wraps the async aws getDataTableList to get the list of all data tables
         * again angular defer/promise so that the UI asynchronously wait for the data to be available...
         */
        this.getDataTableList = function(){
            
        	if (this.dataObject.dataTableList) {
        		return this.dataObject.dataTableList;
        	}
        	
        	var deferred = $q.defer();
            
            aws.DataClient.getDataTableList(function(EntityHierarchyInfoArray){
                
            	that.dataObject.dataTableList = EntityHierarchyInfoArray;
            	
            	scope.$safeApply(function(){
                    deferred.resolve(EntityHierarchyInfoArray);
                });
            });
                
            return deferred.promise;

        };
        
        this.getDataMapping = function(varValues){
        	var deferred = $q.defer();
            
            aws.DataClient.getDataMapping(varValues, function(result){
                
            	scope.$safeApply(function(){
                    deferred.resolve(result);
                });
            });
            return deferred.promise;
        };
        
        this.updateEntity = function(user, password, entityId, diff) {

        	var deferred = $q.defer();
            
            aws.AdminClient.updateEntity(user, password, entityId, diff, function(){
                
            	scope.$safeApply(function(){
                    deferred.resolve();
                });
            });
            return deferred.promise;
        };
}]);
