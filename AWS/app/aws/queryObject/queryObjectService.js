'use strict';
/**
 * Query Object Service provides access to the main "singleton" query object.
 *
 * Don't worry, it will be possible to manage more than one query object in the
 * future.
 */
//angular.module("aws.queryObject", [])
QueryObject.service("queryService", ['$q', '$rootScope', function($q, scope) {
    
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
        	scope.$apply(function() {
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
    this.deleteProject = function(projectName) {
          	
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
     * This function wraps the async aws deleteQueryObject function into an angular defer/promise
     * So that the UI asynchronously wait for the data to be available...
     */
    this.deleteQueryObject = function(projectName, queryObjectName) {
          	
    	var deferred = $q.defer();

        aws.DataClient.deleteQueryObject(projectName,queryObjectName, function(result) {
            
        	that.dataObject.deleteQueryStatus = result;//returns a boolean which states if the query has been deleted(true)
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
            
        	//testing
        	that.dataObject.listofQueryObjectsInProject = result[0];
        	that.dataObject.queryNames = result[1];
        	
        	
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
            
//    		if(!forceUpdate) {
//	    		if (this.dataObject.columns) {
//	    			return this.dataObject.columns;
//	    		}
//    		}

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
            
//    		if (this.dataObject.geometryColumns) {
//    			return this.dataObject.geometryColumns;
//    		}
    		
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
            
//        	if (this.dataObject.dataTableList) {
//        		return this.dataObject.dataTableList;
//        	}
        	
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
        
        this.getDataSetFromTableId = function(id, forceUpdate){
        	var deferred = $q.defer();
        	
        	if(!forceUpdate && this.dataObject.hasOwnProperty("geographyMetadata")) {
        		return this.dataObject.geographyMetadata;
        	} else {
        		aws.DataClient.getDataSetFromTableId(id, function(result) {
        			that.dataObject.geographyMetadata = result;
        			scope.$safeApply(function(){
        				deferred.resolve();
        			});
        		});
        		return deferred.promise;
        	}
        };
        
        this.updateEntity = function(user, password, entityId, diff) {

        	var deferred = $q.defer();
            
            aws.AdminClient.updateEntity(user, password, entityId, diff, function(){
                
            	scope.$apply(function(){
                    deferred.resolve();
                });
            });
            return deferred.promise;
        };
        
        
         // Source: http://www.bennadel.com/blog/1504-Ask-Ben-Parsing-CSV-Strings-With-Javascript-Exec-Regular-Expression-Command.htm
         // This will parse a delimited string into an array of
         // arrays. The default delimiter is the comma, but this
         // can be overriden in the second argument.
     
     
        this.CSVToArray = function(strData, strDelimiter) {
            // Check to see if the delimiter is defined. If not,
            // then default to comma.
            strDelimiter = (strDelimiter || ",");
            // Create a regular expression to parse the CSV values.
            var objPattern = new RegExp((
            // Delimiters.
            "(\\" + strDelimiter + "|\\r?\\n|\\r|^)" +
            // Quoted fields.
            "(?:\"([^\"]*(?:\"\"[^\"]*)*)\"|" +
            // Standard fields.
            "([^\"\\" + strDelimiter + "\\r\\n]*))"), "gi");
            // Create an array to hold our data. Give the array
            // a default empty first row.
            var arrData = [[]];
            // Create an array to hold our individual pattern
            // matching groups.
            var arrMatches = null;
            // Keep looping over the regular expression matches
            // until we can no longer find a match.
            while (arrMatches = objPattern.exec(strData)) {
                // Get the delimiter that was found.
                var strMatchedDelimiter = arrMatches[1];
                // Check to see if the given delimiter has a length
                // (is not the start of string) and if it matches
                // field delimiter. If id does not, then we know
                // that this delimiter is a row delimiter.
                if (strMatchedDelimiter.length && (strMatchedDelimiter != strDelimiter)) {
                    // Since we have reached a new row of data,
                    // add an empty row to our data array.
                    arrData.push([]);
                }
                // Now that we have our delimiter out of the way,
                // let's check to see which kind of value we
                // captured (quoted or unquoted).
                if (arrMatches[2]) {
                    // We found a quoted value. When we capture
                    // this value, unescape any double quotes.
                    var strMatchedValue = arrMatches[2].replace(
                    new RegExp("\"\"", "g"), "\"");
                } else {
                    // We found a non-quoted value.
                    var strMatchedValue = arrMatches[3];
                }
                // Now that we have our value string, let's add
                // it to the data array.
                arrData[arrData.length - 1].push(strMatchedValue);
            }
            // Return the parsed data.
            return (arrData);
        };
}]);
