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
			Indicator : {},
			GeographyFilter : {},
			scriptOptions : {},
			TimePeriodFilter : {},
			ByVariableFilters : [],
			ByVariableColumns : [],
			BarChartTool : { enabled : false },
			MapTool : { enabled : false },
			ScatterPlotTool : { enabled : false },
			DataTableTool : { enabled : false }
	};    		
    
	this.dataObject = {
			dataTableList : [],
			scriptList : []
	};

	
	/**
     * This function wraps the async aws getListOfScripts function into an angular defer/promise
     * So that the UI asynchronously wait for the data to be available...
     */
    this.getListOfScripts = function(forceUpdate) {
    	if(!forceUpdate) {
			return this.dataObject.scriptList;
    	} else {
    		aws.queryService(scriptManagementURL, 'getListOfScripts', null, function(result){
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
    
    
    this.getSessionState = function(){
    	if(!(newWeaveWindow.closed)){
    		var base64SessionState = newWeaveWindow.getSessionState();
    		this.writeSessionState(base64SessionState);
    	}
    };
   
    this.writeSessionState = function(base64String){
    	
    	var params = {};
    	params.queryObjectJsons = angular.toJson(this.queryObject);
    	params.projectName = "Other";
    	params.userName = "Awesome User";
    	params.projectDescription = "These query objects do not belong to any project";
    	params.resultVisualizations = base64String;
    	params.queryObjectTitles = this.queryObject.title;
    	
    	
    	console.log("got it", base64String);
    	aws.queryService(projectManagementURL, 'writeSessionState', params, function(result){
    		console.log("adding status", result);
    		alert(params.queryObjectTitles + " has been added");
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
    		aws.queryService(scriptManagementURL, 'getScriptMetadata', [scriptName], function(result){
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
				aws.queryService(dataServiceURL, "getEntityChildIds", [id], function(idsArray) {
					aws.queryService(dataServiceURL, "getEntitiesById", [idsArray], function (dataEntityArray){
						
						
						that.dataObject.columns = $.map(dataEntityArray, function(entity) {
							if(entity.publicMetadata.hasOwnProperty("aws_metadata")) {
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
				aws.queryService(dataServiceURL, "getEntitiesById", [idsArray], function (dataEntityArray){
					
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
		
		aws.queryService(dataServiceURL, 'getEntityIdsByMetadata', [{"dataType" :"geometry"}, 1], function(idsArray){
			aws.queryService(dataServiceURL, 'getEntitiesById', [idsArray], function(dataEntityArray){
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
    		aws.queryService(dataServiceURL, 'getDataTableList', null, function(EntityHierarchyInfoArray){
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
        	
        	if(!forceUpdate) {
      			return this.dataObject.geographyMetadata;
        	} else {
        		aws.queryService(dataServiceURL, "getEntityChildIds", [id], function(ids){
        			aws.queryService(dataServiceURL, "getDataSet", [ids], function(result){
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
     
}]);
