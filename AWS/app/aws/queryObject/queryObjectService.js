'use strict';
/**
 * Query Object Service provides access to the main "singleton" query object.
 *
 * Don't worry, it will be possible to manage more than one query object in the
 * future.
 */

var dataServiceURL = '/WeaveServices/DataService';

var adminServiceURL = '/WeaveServices/AdminService';

var scriptManagementURL = '/WeaveAnalystServices/ScriptManagementServlet';

var projectManagementURL = '/WeaveAnalystServices/ProjectManagementServlet';
//angular.module("aws.queryObject", [])
QueryObject.service("queryService", ['$q', '$rootScope', function($q, scope) {
    
	var that = this;
	this.queryObject = {
			title : "Beta Query Object",
			date : new Date(),
    		author : "",
			ComputationEngine : "R",
			Indicator : {},
			GeographyFilter : {},
			TimePeriodFilter : {},
			ByVariableFilter : [],
			BarChartTool : {},
			MapTool : {},
			ScatterPlotTool : {},
			DataTableTool : {}
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

    		aws.queryService(scriptManagementURL, 'getListOfScripts', null, function(result){
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
    
    this.getListOfProjectsfromDatabase = function() {
		var deferred = $q.defer();

		aws.queryService(projectManagementURL, 'getProjectListFromDatabase', null, function(result){
    	that.dataObject.listOfProjectsFromDatabase = result;
    	
    	scope.$safeApply(function() {
            deferred.resolve(result);
        });
    	
    });
        
        return deferred.promise;
        
    };
    
    
    this.insertQueryObjectToProject = function(userName, projectName,projectDescription, queryObjectTitle, queryObjectContent) {
      	
    	var deferred = $q.defer();
    	var params = {};
    	params.userName = userName;
    	params.projectName = projectName;
    	params.projectDescription = projectDescription;
    	params.queryObjectTitle = queryObjectTitle;
    	params.queryObjectContent = queryObjectContent;

    	aws.queryService(projectManagementURL, 'insertMultipleQueryObjectInProjectFromDatabase', [params], function(result){
        	console.log("insertQueryObjectStatus", result);
        	that.dataObject.insertQueryObjectStatus = result;//returns an integer telling us the number of row(s) added
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
    	var params = {};
    	params.projectName = projectName;

    	aws.queryService(projectManagementURL, 'deleteProjectFromDatabase', [params], function(result){
        	console.log("deleteProjectStatus", result);
            
        	that.dataObject.deleteProjectStatus = result;//returns an integer telling us the number of row(s) deleted
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
    this.deleteQueryObject = function(projectName, queryObjectTitle) {
          	
    	var deferred = $q.defer();
    	var params = {};
    	params.projectName = projectName;
    	params.queryObjectTitle = queryObjectTitle;

    	aws.queryService(projectManagementURL, 'deleteQueryObjectFromProjectFromDatabase', [params], function(result){
        	that.dataObject.deleteQueryObjectStatus = result;//returns a boolean which states if the query has been deleted(true)
        	console.log("in the service",that.dataObject.deleteQueryObjectStatus );
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
    	var deferred = $q.defer();

    	var params = {};
    	params.projectName = projectName;
    	aws.queryService(projectManagementURL, 'getQueryObjectsFromDatabase', [params], function(AWSQueryObjectCollectionObject){
    		var returnedQueryObjects = [];
    		if(!(angular.isUndefined(AWSQueryObjectCollectionObject)))
    			{
    			
	    			var countOfJsons = AWSQueryObjectCollectionObject.finalQueryObjects.length;
	    			for(var i = 0; i < countOfJsons; i++)
	    			{
	    				returnedQueryObjects[i] = JSON.parse(AWSQueryObjectCollectionObject.finalQueryObjects[i]);
	    			}
	    			
	    			that.dataObject.listofQueryObjectsInProject = returnedQueryObjects;
	    			that.dataObject.queryNames = AWSQueryObjectCollectionObject.queryObjectNames;
	    			that.dataObject.projectDescription = AWSQueryObjectCollectionObject.projectDescription;
	    			
    			}
        	scope.$safeApply(function() {
                deferred.resolve(AWSQueryObjectCollectionObject);
            });
        	
        });
        
        return deferred.promise;
        
    };
    
    /**
     * This function returns the visualizations belonging to query(ies)
     */
    
    this.getListOfQueryObjectVisualizations = function(projectName){
    	 var deferred = $q.defer();
    	var params = {};
    	params.projectName = projectName;
    	
    	aws.queryService(projectManagementURL, 'getListOfQueryObjectVisualizations', [params], function(result){
    		that.dataObject.listofVisualizations = result;
    		console.log("images", result);
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
        
        	aws.queryService(scriptManagementURL, 'getScriptMetadata', [scriptName], function(result){
        	that.dataObject.scriptMetadata = result;
        	// since this function executes async in a future turn of the event loop, we need to wrap
            // our code into an $apply call so that the model changes are properly observed.
            scope.$safeApply(function() {
                deferred.resolve(result);
            });
        });
      
        return deferred.promise;
    };

		/**
    	  * This function makes nested async calls to the aws function getEntityChildIds and
    	  * getDataColumnEntities in order to get an array of dataColumnEntities children of the given id.
    	  * We use angular deferred/promises so that the UI asynchronously wait for the data to be available...
    	  */
    	this.getDataColumnsEntitiesFromId = function(id, forceUpdate) {

    		var deferred = $q.defer();
    		
    		aws.queryService(dataServiceURL, "getEntityChildIds", [id], function(idsArray) {
                scope.$safeApply(function() {
                    deferred.resolve(idsArray);
                });
            });
            
            var deferred2 = $q.defer();
            
            deferred.promise.then(function(idsArray) {
            	
            	aws.queryService(dataServiceURL, "getEntitiesById", [idsArray], function (dataEntityArray){
            		
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
 	
    		var deferred = $q.defer();
    		
    		aws.queryService(dataServiceURL, 'getEntityIdsByMetadata', [{"dataType" :"geometry"}, 1], function(idsArray){
                scope.$safeApply(function() {
                    deferred.resolve(idsArray);
                });
            });
            
            var deferred2 = $q.defer();
            
            deferred.promise.then(function(idsArray) {
            	
        	aws.queryService(dataServiceURL, 'getEntitiesById', [idsArray], function(dataEntityArray){
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
        	var deferred = $q.defer();
            
                aws.queryService(dataServiceURL, 'getDataTableList', null, function(EntityHierarchyInfoArray){
            	that.dataObject.dataTableList = EntityHierarchyInfoArray;
            	
            	scope.$safeApply(function(){
                    deferred.resolve(EntityHierarchyInfoArray);
                });
            });
                
            return deferred.promise;

        };
        
        this.getDataMapping = function(varValues)
        {
	        	var deferred = $q.defer();
	            
	        	callback = function(result)
	        	{
	         		scope.$safeApply(function(){
	                   deferred.resolve(result);
	     			});
	        		         	
	         	if (Array.isArray(varValues))
	         	{
	         		setTimeout(function(){ callback(varValues); }, 0);
	         		return;
	         	}
	         	
	         	if (typeof varValues == 'string')
	         		varValues = {"aws_id": varValues};
	         		aws.queryService(dataServiceURL, 'getColumn', [varValues, NaN, NaN, null],
	             		function(columnData) {
	             			var result = [];
	             			for (var i in columnData.keys)
	             				result[i] = {"value": columnData.keys[i], "label": columnData.data[i]};
	             			callback(result);
	             		}
	             	);
	        };
	        
	        return deferred.promise;
        };
        
      
      
        this.getDataSetFromTableId = function(id,forceUpdate){
          	var deferred = $q.defer();
          	
          	if(!forceUpdate && this.dataObject.hasOwnProperty("geographyMetadata")) {
          		return this.dataObject.geographyMetadata;
          	} else 
         	{
         		aws.queryService(dataServiceURL, "getEntityChildIds", [id], function(ids){
         			
         			aws.queryService(dataServiceURL, "getDataSet", [ids], function(result){
         				that.dataObject.geographyMetadata = result;
             			scope.$safeApply(function(){
             				deferred.resolve();
             			});
          			});
          		});
         	
          		return deferred.promise;
         		
         	}
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
        
        this.authenticate = function(user, password) {

        	var deferred = $q.defer();
            
            aws.AdminClient.authenticate(user, password, function(result){
                
            	scope.$apply(function(){
                    deferred.resolve(result);
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
