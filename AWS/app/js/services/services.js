'use strict';

/* Services */


/**
 * Query Object Service provides access to the main "singleton" query object.
 *
 * Don't worry, it will be possible to manage more than one query object in the
 * future.
 */
angular.module("aws.services", []).service("queryService", ['$q', '$rootScope', function($q, scope) {
    
	this.queryObject = {
			title : "AlphaQueryObject",
			date : new Date(),
    		author : "",
			scriptType : "r",
			dataTable : ""//"this.getDataTableList().then(function(result){
				// return result[0];}
			//)
	};    		
    
	/**
     * This function wraps the async aws getListOfScripts function into an angular defer/promise
     * So that the UI asynchronously wait for the data to be available...
     */
    this.getListOfScripts = function() {
        
    	var deferred = $q.defer();

        aws.RClient.getListOfScripts(function(result) {
            
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
     * This function wraps the async aws getListOfScripts function into an angular defer/promise
     * So that the UI asynchronously wait for the data to be available...
     */
    this.getScriptMetadata = function() {
        var deferred = $q.defer();

        aws.RClient.getScriptMetadata(queryService.queryObject.scriptSelected, function(result) {
        	
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
    	this.getDataColumnsEntitiesFromId = function(id) {
            
    		var deferred = $q.defer();
    		
            aws.DataClient.getEntityChildIds(id, function(idsArray) {
                scope.$safeApply(function() {
                    deferred.resolve(idsArray);
                });
            });
            
            var deferred2 = $q.defer();
            
            deferred.promise.then(function(idsArray) {

            	aws.DataClient.getDataColumnEntities(idsArray, function(dataEntityArray) {
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
            
    		var deferred = $q.defer();
    		
            aws.DataClient.getEntityIdsByMetadata({"dataType":"geometry"}, function(idsArray) {
                scope.$safeApply(function() {
                    deferred.resolve(idsArray);
                });
            });

            return deferred.promise.then(function(idsArray) {
            	
            	aws.DataClient.getDataColumnEntities(idsArray, function(dataEntityArray) {
                    scope.$safeApply(function() {
                    	deferred.resolve(dataEntityArray);
                    });
                });
            	
            	return deferred.promise;
            });

        };
        
        /**
         * This function wraps the async aws getDataTableList to get the list of all data tables
         * again angular defer/promise so that the UI asynchronously wait for the data to be available...
         */
        this.getDataTableList = function(){
            
        	var deferred = $q.defer();
            
            aws.DataClient.getDataTableList(function(EntityHierarchyInfoArray){
                scope.$safeApply(function(){
                    deferred.resolve(EntityHierarchyInfoArray);
                });
            });
                
            return deferred.promise;
        };        
}]);
