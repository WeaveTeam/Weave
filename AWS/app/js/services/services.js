'use strict';

/* Services */


/**
 * Query Object Service provides access to the main "singleton" query object.
 *
 * Don't worry, it will be possible to manage more than one query object in the
 * future.
 */
angular.module("aws.services", []).service("queryobj", function() {
    this.title = "AlphaQueryObject";
    this.date = new Date();
    this.author = "UML IVPR AWS Team";
    this.scriptType = "r";
    this.dataTable = {id:1,title:"default"};
    this.conn = {
        serverType: 'MySQL',
        connectionType: 'RMySQL',
        sqlip: 'localhost',
        sqlport: '3306',
        sqldbname: 'sdoh2010q',
        sqluser: 'root',
        sqlpass: 'pass',
        schema: 'data',
        dsn: 'brfss'
    };
    this.slideFilter = {values: [10, 25]}
    this.setQueryObject = function(jsonObj) {
        if (!jsonObj) {
            return undefined;
        }
        this.title = jsonObj.title;
        this.date = jsonObj.data;
        this.author = jsonObj.author;
        this.scriptType = jsonObj.scriptType;
        this.dataTable = jsonObj.dataTable;
        this.conn = jsonObj.conn;
        this.selectedVisualization = jsonObj.selectedVisualization;
        this.barchart = jsonObj.barchart;
        this.datatable = jsonObj.datatable;
        this.colorColumn = jsonObj.colorColumn;
        this.byvars = jsonObj.byvars;
        this.indicators = jsonObj.indicators;
        this.geography = jsonObj.geography;
        this.timeperiods = jsonObj.timeperiods;
        this.analytics = jsonObj.analytics;
        this.scriptOptions = jsonObj.scriptOptions;
        this.scriptSelected = jsonObj.scriptSelected;
        this.maptool = jsonObj.maptool;
    };
    return {
        //getSlideFilter: this.slideFilterI,
        //setSlideFilter: function(dat){ this.slideFilterI = dat; return this.slideFilterI;},
        //q: this,
        title: this.title,
        date: this.date,
        author: this.author,
        dataTable: function() {
            return this.dataTable;
        },
        conn: this.conn,
        scriptType: this.scriptType,
        slideFilter: this.slideFilter,
        getSelectedColumns: function() {
            //TODO hackity hack hack
            var col = ["geography", "indicators", "byvars", "timeperiods", "analytics"];
            var columns = [];
            var temp;
            for (var i = 0; i < col.length; i++) {
                if (this[col[i]]){
                	angular.forEach(this[col[i]], function(item){
                		if(item.hasOwnProperty('publicMetadata')) {
                			var obj = {
                       			title:item.publicMetadata.title,
	            				id:item.id,
	            				range:item.publicMetadata.var_range
                			};
                			columns.push(obj);
                		}
                	});
                }
            }
            return columns;
        }

    }
})

angular.module("aws.services").service("scriptobj", ['queryobj', '$rootScope', '$q', function(queryobj, scope, $q) {
   
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
        return deferred.promise.then(function(result){
        	return result;
        });
    };
    
    /**
     * This function wraps the async aws getListOfScripts function into an angular defer/promise
     * So that the UI asynchronously wait for the data to be available...
     */
    this.getScriptMetadata = function() {
        var deferred = $q.defer();

        aws.RClient.getScriptMetadata(queryobj.scriptSelected, function(result) {
        	
        	// since this function executes async in a future turn of the event loop, we need to wrap
            // our code into an $apply call so that the model changes are properly observed.
            scope.$safeApply(function() {
                deferred.resolve(result);
            });
        });
      
        // regardless of when the promise was or will be resolved or rejected,
 	    // then calls one of the success or error callbacks asynchronously as soon as the result
     	// is available. The callbacks are called with a single argument: the result or rejection reason.
        return deferred.promise.then(function(result){
        	return result;
        });
    };
    
}]);

angular.module("aws.services").service("dataService", ['$q', '$rootScope', 'queryobj', function($q, scope, queryobj) {
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

            return deferred.promise.then(function(idsArray) {

            	aws.DataClient.getDataColumnEntities(idsArray, function(dataEntityArray) {
                    scope.$safeApply(function() {
                    	deferred.resolve(dataEntityArray);
                    });
                });
            	
            	return deferred.promise.then(function(dataEntityArray) {
            		return dataEntityArray;
            	});
            });

        };

        
        /**
    	  * This function makes nested async calls to the aws function getEntityIdsByMetadata and
    	  * getDataColumnEntities in order to get an array of dataColumnEntities children that have metadata of type geometry.
    	  * We use angular deferred/promises so that the UI asynchronously wait for the data to be available...
    	  */
    	this.getGeometryDataColumnsEntities = function() {
            
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
            	
            	return deferred.promise.then(function(dataEntityArray) {
            		return dataEntityArray;
            	});
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
                
            return deferred.promise.then(function(EntityHierarchyInfoArray){
            	return EntityHierarchyInfoArray;
            });

        };

}]);
