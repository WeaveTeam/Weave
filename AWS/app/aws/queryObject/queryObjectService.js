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

	this.content_tools = [{
		id : 'Indicator',
		title : 'Indicator',
		template_url : 'aws/analysis/indicator/indicator.tpl.html',
		description : 'Choose an Indicator for the Analysis',
		category : 'indicatorfilter'
	},
	{
		id : 'GeographyFilter',
		title : 'Geography Filter',
		template_url : 'aws/analysis/data_filters/geography.tpl.html',
		description : 'Filter data by States and Counties',
		category : 'datafilter'

	},
	{
		id : 'TimePeriodFilter',
		title : 'Time Period Filter',
		template_url : 'aws/analysis/data_filters/time_period.tpl.html',
		description : 'Filter data by Time Period',
		category : 'datafilter'
	},
	{
		id : 'ByVariableFilter',
		title : 'By Variable Filter',
		template_url : 'aws/analysis/data_filters/by_variable.tpl.html',
		description : 'Filter data by Variables',
		category : 'datafilter'
	}];
	
	
	this.tool_list = [
	{
		id : 'BarChartTool',
		title : 'Bar Chart Tool',
		template_url : 'aws/visualization/tools/barChart/bar_chart.tpl.html',
		description : 'Display Bar Chart in Weave',
		category : 'visualization',
		enabled : false

	}, {
		id : 'MapTool',
		title : 'Map Tool',
		template_url : 'aws/visualization/tools/mapChart/map_chart.tpl.html',
		description : 'Display Map in Weave',
		category : 'visualization',
		enabled : false
	}, {
		id : 'DataTableTool',
		title : 'Data Table Tool',
		template_url : 'aws/visualization/tools/dataTable/data_table.tpl.html',
		description : 'Display a Data Table in Weave',
		category : 'visualization',
		enabled : false
	}, {
		id : 'ScatterPlotTool',
		title : 'Scatter Plot Tool',
		template_url : 'aws/visualization/tools/scatterPlot/scatter_plot.tpl.html',
		description : 'Display a Scatter Plot in Weave',
		category : 'visualization',
		enabled : false
	}];
	
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

    
    this.getSessionState = function(){
    	if(!(newWeaveWindow.closed)){
    		var base64SessionState = newWeaveWindow.getSessionState();
    		this.writeSessionState(base64SessionState);
    	}
    };
   
    this.writeSessionState = function(base64String){
    	var userName = "Awesome User";
    	var projectName = "Other";
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
    	console.log("got it", queryObjectJsons);
    	var projectDescription = "These query objects do not belong to any project";
    	var queryObjectTitles = this.queryObject.title;
    	var resultVisualizations = base64String;

    	
    	aws.queryService(projectManagementURL, 'writeSessionState', [userName, projectDescription, queryObjectTitles, queryObjectJsons, resultVisualizations, projectName], function(result){
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
