'use strict';
/**
 * Query Object Service provides access to the main "singleton" query object.
 *
 * Don't worry, it will be possible to manage more than one query object in the
 * future.
 */

//var dataServiceURL = '/WeaveServices/DataService';

//var adminServiceURL = '/WeaveServices/AdminService';

var scriptManagementURL = '/WeaveAnalystServices/ScriptManagementServlet';

var projectManagementURL = '/WeaveAnalystServices/ProjectManagementServlet';

var aws = {};

QueryObject.service('runQueryService', ['errorLogService','$modal', function(errorLogService, $modal){

	/**
	 * This function is a wrapper for making a request to a JSON RPC servlet
	 * 
	 * @param {string} url
	 * @param {string} method The method name to be passed to the servlet
	 * @param {?Array|Object} params An array of object to be passed as parameters to the method 
	 * @param {Function} resultHandler A callback function that handles the servlet result
	 * @param {string|number=}queryId
	 * @see aws.addBusyListener
	 */
	this.queryRequest = function(url, method, params, resultHandler, queryId)
	{
	    var request = {
	        jsonrpc: "2.0",
	        id: queryId || "no_id",
	        method: method,
	        params: params
	    };
	    
	    $.post(url, JSON.stringify(request), handleResponse, "text");

	    function handleResponse(response)
	    {
	    	// parse result for target window to use correct Array implementation
	    	response = JSON.parse(response);
	    	
	        if (response.error)
	        {	
	        	console.log(JSON.stringify(response, null, 3));
	        	//log the error
	        	errorLogService.logInErrorLog(response.error.message);
	        	//open the error log
	        	$modal.open(errorLogService.errorLogModalOptions);
	        }
	        else if (resultHandler){
	            return resultHandler(response.result, queryId);
	        }
	    }
	};
	
	
	/**
	 * Makes a batch request to a JSON RPC 2.0 service. This function requires jQuery for the $.post() functionality.
	 * @param {string} url The URL of the service.
	 * @param {string} method Name of the method to call on the server for each entry in the queryIdToParams mapping.
	 * @param {Array|Object} queryIdToParams A mapping from queryId to RPC parameters.
	 * @param {function(Array|Object)} resultsHandler Receives a mapping from queryId to RPC result.
	 */
	this.bulkQueryRequest = function(url, method, queryIdToParams, resultsHandler)
	{
		var batch = [];
		for (var queryId in queryIdToParams)
			batch.push({jsonrpc: "2.0", id: queryId, method: method, params: queryIdToParams[queryId]});
		$.post(url, JSON.stringify(batch), handleBatch, "json");
		function handleBatch(batchResponse)
		{
			var results = Array.isArray(queryIdToParams) ? [] : {};
			for (var i in batchResponse)
			{
				var response = batchResponse[i];
				if (response.error)
					console.log(JSON.stringify(response, null, 3));
				else
					results[response.id] = response.result;
			}
			if (resultsHandler)
				resultsHandler(results);
		}
	};
}]);


QueryObject.service("queryService", ['$q', '$rootScope', 'WeaveService', 'runQueryService','dataServiceURL', 'adminServiceURL',
                         function($q, scope, WeaveService, runQueryService, dataServiceURL, adminServiceURL) {
    
	var SaveState =  function () {
        sessionStorage.queryObject = angular.toJson(queryObject);
    };

    var RestoreState = function () {
    	this.queryObject = angular.fromJson(sessionStorage.queryObject);
    };

	var that = this; // point to this for async responses

	this.queryObject = {
			title : "Beta Query Object",
			date : new Date(),
    		author : "",
			ComputationEngine : "R",
			Indicator : "",
			filters : {
				or : []
			},
			GeographyFilter : {
				stateColumn:"{\"id\":2695,\"title\":\"X_STATE\",\"columnType\":\"geography\",\"description\":\"\"}",
				countyColumn:"{\"id\":2696,\"title\":\"X_CTYCODE\",\"columnType\":\"geography\",\"description\":\"\"}",
				metadataTable:"{\"id\":2834,\"title\":\"US FIPS Codes\",\"numChildren\":4}"
			},
			scriptOptions : {},
			TimePeriodFilter : {},
			ByVariableFilters : [],
			ByVariableColumns : [],
			BarChartTool : { enabled : false },
			MapTool : { enabled : false },
			ScatterPlotTool : { enabled : false },
			DataTableTool : { enabled : false },
			ColorColumn : {column : ""},
			keyColumn : {name : ""}
	};    		
    
	this.dataObject = {
			dataTableList : [],
			scriptList : [],
			filters : []
	};

	
	/**
     * This function wraps the async aws getListOfScripts function into an angular defer/promise
     * So that the UI asynchronously wait for the data to be available...
     */
    this.getListOfScripts = function(forceUpdate) {
    	if(!forceUpdate) {
			return this.dataObject.scriptList;
    	} else {
    		runQueryService.queryRequest(scriptManagementURL, 'getListOfScripts', null, function(result){
    			that.dataObject.scriptList = result;
    		});
    	}
    };

    /**
     * This function wraps the async aws getListOfProjects function into an angular defer/promise
     * So that the UI asynchronously wait for the data to be available...
     */
    this.getListOfProjectsfromDatabase = function() {
		var deferred = $q.defer();

		runQueryService.queryRequest(projectManagementURL, 'getProjectListFromDatabase', null, function(result){
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

    	runQueryService.queryRequest(projectManagementURL, 'insertMultipleQueryObjectInProjectFromDatabase', [params], function(result){
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

    	runQueryService.queryRequest(projectManagementURL, 'deleteProjectFromDatabase', [params], function(result){
        	console.log("deleteProjectStatus", result);
            
        	that.dataObject.deleteProjectStatus = result;//returns an integer telling us the number of row(s) deleted
        	scope.$safeApply(function() {
                deferred.resolve(result);
            });
        	
        });
        
        return deferred.promise;
        
    };
    
    
    this.getSessionState = function(params){
    	if(!(weaveWindow.closed)){
    		var base64SessionState = WeaveService.getSessionState();
    		this.writeSessionState(base64SessionState, params);
    	}
    };
   
    this.writeSessionState = function(base64String, params){
    	var projectName;
    	var userName = "Awesome User";
    	var queryObjectTitles;
    	var projectDescription;
    	//params.queryObjectJsons = angular.toJson(this.queryObject);
    	
    	if(angular.isDefined(params.projectEntered))
    		{
	    		projectName = params.projectEntered;
	    		projectDescription = "This project belongs to " + projectName;
    		}
    	else
    		{
	    		projectName = "Other";
	    		projectDescription = "These query objects do not belong to any project"; 
    		}
    	if(angular.isDefined(params.queryTitleEntered)){
    		queryObjectTitles = params.queryTitleEntered;
    		this.queryObject.title = queryObjectTitles;
    	}
    	else
    		 queryObjectTitles = this.queryObject.title;
    	
    	
    	var qo =this.queryObject;
    	   	for(var key in qo.scriptOptions) {
    	    		var input = qo.scriptOptions[key];
    	    		//console.log(typeof input);
    	    		switch(typeof input) {
    	    			
    	    			case 'string' :
    	    				var inputVal = tryParseJSON(input);
    	    				if(inputVal) {  // column input
    	    					qo.scriptOptions[key] = inputVal;
    	    				} else { // regular string
    	    					qo.scriptOptions[key] = input;
    	    				}
    	    				break;
    	    			
    	    			default:
    	    				console.log("unknown script input type");
    	    		}
    	    	}
    	    	if (typeof(qo.Indicator) == 'string'){
    	    		var inputVal = tryParseJSON(qo.Indicator);
    				if(inputVal) {  // column input
    					qo.Indicator = inputVal;
    				} else { // regular string
    					qo.Indicator = input;
    				}
    	    	}
    	var queryObjectJsons = angular.toJson(qo);
    	var resultVisualizations = base64String;
    	
    	
    	runQueryService.queryRequest(projectManagementURL, 'writeSessionState', [userName, projectDescription, queryObjectTitles, queryObjectJsons, resultVisualizations, projectName], function(result){
    		console.log("adding status", result);
    		alert(queryObjectTitles + " has been added");
    	});
    };
    
    /**
     * This function wraps the async aws getListOfScripts function into an angular defer/promise
     * So that the UI asynchronously wait for the data to be available...
     */
    this.getScriptMetadata = function(scriptName, forceUpdate) {
        
    	var deferred = $q.defer();

    	if (!forceUpdate) {
    		return this.dataObject.scriptMetadata;
    	}
    	if(scriptName) {
    		runQueryService.queryRequest(scriptManagementURL, 'getScriptMetadata', [scriptName], function(result){
    			that.dataObject.scriptMetadata = result;
    			scope.$safeApply(function() {
    				deferred.resolve(that.dataObject.scriptMetadata);
    			});
    		});
    	}
        return deferred.promise;
    };

	/**
	  * This function makes nested async calls to the aws function getEntityChildIds and
	  * getDataColumnEntities in order to get an array of dataColumnEntities children of the given id.
	  * We use angular deferred/promises so that the UI asynchronously wait for the data to be available...
	  */
	this.getDataColumnsEntitiesFromId = function(id, forceUpdate) {

		var deferred = $q.defer();

		if(!forceUpdate) {
			return that.dataObject.columns;
		} else {
			if(id) {
				runQueryService.queryRequest(dataServiceURL, "getEntityChildIds", [id], function(idsArray) {
					//console.log("idsArray", idsArray);
					runQueryService.queryRequest(dataServiceURL, "getEntitiesById", [idsArray], function (dataEntityArray){
						//console.log("dataEntirtyArray", dataEntityArray);
						//console.log("columns", that.dataObject.columnsb);
						
						that.dataObject.columns = $.map(dataEntityArray, function(entity) {
							if(entity.publicMetadata.hasOwnProperty("aws_metadata")) {//will work if the column already has the aws_metadata as part of its public metadata
								var metadata = angular.fromJson(entity.publicMetadata.aws_metadata);
								if(metadata.hasOwnProperty("columnType")) {
									return {
										id : entity.id,
										title : entity.publicMetadata.title,
										columnType : metadata.columnType,
										description : metadata.description || ""
									};
								}
							}
							else{//if its doesnt have aws_metadata as part of its public metadata, create a partial aws_metadata object
									return {
										id : entity.id,
										title : entity.publicMetadata.title,
										columnType : "",
										description : ""
									};
								
							}
						});
						scope.$safeApply(function() {
							deferred.resolve(that.dataObject.columns);
						});
					});
				});
			}
		}
        return deferred.promise;
    };
    
    this.getEntitiesById = function(idsArray, forceUpdate) {
    	
    	var deferred = $q.defer();

		if(!forceUpdate) {
			return that.dataObject.dataColumnEntities;
		} else {
			if(idsArray) {
				runQueryService.queryRequest(dataServiceURL, "getEntitiesById", [idsArray], function (dataEntityArray){
					
					that.dataObject.dataColumnEntities = dataEntityArray;
					
					scope.$safeApply(function() {
						deferred.resolve(that.dataObject.dataColumnEntities);
					});
				});
			}
		}
		
        return deferred.promise;
    	
    };
        
        
    /**
	  * This function makes nested async calls to the aws function getEntityIdsByMetadata and
	  * getDataColumnEntities in order to get an array of dataColumnEntities children that have metadata of type geometry.
	  * We use angular deferred/promises so that the UI asynchronously wait for the data to be available...
	  */
	this.getGeometryDataColumnsEntities = function(forceUpdate) {

		var deferred = $q.defer();

		if(!forceUpdate) {
			return that.dataObject.geometryColumns;
		}
		
		runQueryService.queryRequest(dataServiceURL, 'getEntityIdsByMetadata', [{"dataType" :"geometry"}, 1], function(idsArray){
			runQueryService.queryRequest(dataServiceURL, 'getEntitiesById', [idsArray], function(dataEntityArray){
				that.dataObject.geometryColumns = $.map(dataEntityArray, function(entity) {
					return {
						id : entity.id,
						title : entity.publicMetadata.title,
						keyType : entity.publicMetadata.keyType
					};
				});
				
				scope.$safeApply(function() {
					deferred.resolve(that.dataObject.geometryColumns);
				});
			});
		});

		return deferred.promise;
    };
    
    /**
     * This function wraps the async aws getDataTableList to get the list of all data tables
     * again angular defer/promise so that the UI asynchronously wait for the data to be available...
     */
    this.getDataTableList = function(forceUpdate){
    	var deferred = $q.defer();

    	if(!forceUpdate) {
			return that.dataObject.dataTableList;
    	} else {
    		runQueryService.queryRequest(dataServiceURL, 'getDataTableList', null, function(EntityHierarchyInfoArray){
    			that.dataObject.dataTableList = EntityHierarchyInfoArray;
    			scope.$safeApply(function() {
    				deferred.resolve(that.dataObject.dataTableList);
    			});
    		 });
    	}
        return deferred.promise;
    };
        
    this.getDataMapping = function(varValues)
    {
        	var deferred = $q.defer();

        	var callback = function(result)
        	{
         		scope.$safeApply(function(){
                   deferred.resolve(result);
         		});
        	};

         	if (Array.isArray(varValues))
         	{
         		setTimeout(function(){ callback(varValues); }, 0);
         		return deferred.promise;
         	}

         	//if (typeof varValues == 'string')
         	//	varValues = {"aws_id": varValues};
         		
         	runQueryService.queryRequest(dataServiceURL, 'getColumn', [varValues, NaN, NaN, null],
         		function(columnData) {
         			var result = [];
         			for (var i in columnData.keys) 
         				result[i] = {"value": columnData.keys[i], "label": columnData.data[i]};
         			callback(result);
     			}
     		);
	        return deferred.promise;
    };
        
      
      
        this.getDataSetFromTableId = function(id,forceUpdate){
          	
        	var deferred = $q.defer();
        	
        	if(!forceUpdate) {
      			return this.dataObject.geographyMetadata;
        	} else {
        		runQueryService.queryRequest(dataServiceURL, "getEntityChildIds", [id], function(ids){
        			runQueryService.queryRequest(dataServiceURL, "getDataSet", [ids], function(result){
        				that.dataObject.geographyMetadata = result;
        				scope.$safeApply(function() {
            				deferred.resolve(that.dataObject.geographyMetadata);
            			});
        			});
        		});
        	}
        	
            return deferred.promise;
        };
        
        this.updateEntity = function(user, password, entityId, diff) {

        	var deferred = $q.defer();
            
        	runQueryService.queryRequest(adminServiceURL, 'updateEntity', [user, password, entityId, diff], function(){
                
            	scope.$safeApply(function(){
                    deferred.resolve();
                });
            });
            return deferred.promise;
        };
        
//        this.authenticate = function(user, password) {
//
//        	aws.queryService(adminServiceURL, 'authenticate', [user, password], function(result){
//                this.authenticated = result;
//                scope.$apply();
//            }.bind(this));
//        };
        
        
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
