/**
 * This Service is designed to receive a query object and interpret its content.
 * 
 **/
//var computationServiceURL = '/WeaveAnalystServices/ComputationalServlet';

var qh_module = angular.module('aws.QueryHandlerModule', []);

qh_module.service('QueryHandlerService', ['$q', '$rootScope','queryService','WeaveService','errorLogService','runQueryService','computationServiceURL', '$window', '$modal',
                                 function($q, scope, queryService, WeaveService, errorLogService,runQueryService,computationServiceURL, $window, $modal) {
	
	//this.WeaveService.weaveWindow;
	var scriptInputs = {};
	var filters = {};
	var scriptName = ""; 
	
	//boolean used for displaying the Visualization widget tool menu
	//only when results are returned and Weave pops up, should this menu be enabled
	this.displayVizMenu = false;
	
	//var queryObject = queryService.queryObject;
	var nestedFilterRequest = {and : []};
	
	var that = this; // point to this for async responses
	

	
	/**
     * This function wraps the async aws runScript function into an angular defer/promise
     * So that the UI asynchronously wait for the data to be available...
     */
    this.runScript = function(scriptName) {
        
    	var deferred = $q.defer();

    	runQueryService.queryRequest(computationServiceURL, 'runScript', [scriptName], function(result){	
    		scope.$safeApply(function() {
				deferred.resolve(result);
			});
		});
    	
        return deferred.promise;
    };
    
    this.getDataFromServer = function(inputs, reMaps) {
    	
    	var deferred = $q.defer();

    	runQueryService.queryRequest(computationServiceURL, 'getDataFromServer', [inputs, reMaps], function(result){	
    		scope.$safeApply(function() {
				deferred.resolve(result);
			});
		});
    	
        return deferred.promise;
    };
    
    /*
     * this function handles different types of script inputs and returns an object of this signature
     * {
				type : eg filtered rows, column matrix, single values, numbers, boolean
				names : parameter names to be used for assigning in R 
				value :  the actual data value
		}
     * */
    this.handleScriptOptions = function(scriptOptions)
    {	
    	var typedInputObjects= [];
    	//TODO create remaining beans
    	
    	//Filtered Rows bean(each column is assigned a name when it reaches the computation engine)
    	var filteredRowsObject = {
    			type: "FilteredRows",
    			names: [],
    			value: {
    				columnIds : [],
    				filters: null //will be {} once filters are completed
    				
    			}
    	};
    	
    	//DataMatrix bean (a single name is assigned to a data matrix [][])
    	var dataMatrix = {
    			type: "DataColumnMatrix",
    			name:"columnData",
    			value:{
    				
    				columnIds : []
    			}
    	};
    	
    	for(var key in scriptOptions) {
			var input = scriptOptions[key];
			
			
	    	if((typeof input) == 'object') {
	    		
	    		filteredRowsObject.value.columnIds.push(input.id);
	    		
	    		if($.inArray(filteredRowsObject,typedInputObjects) == -1)//if not present in array before
	    			typedInputObjects.push(filteredRowsObject);
	    	}
				
	    	else if ((typeof input) == 'array') // array of columns
			{
	    		//scriptInputs[key] = $.map(input, function(inputVal) {
	    			//				return { id : JSON.parse(inputVal).id };
	    			//			});
			}
	    	else if ((typeof input) == 'string'){
				//var inputVal = tryParseJSON(input);
	    		//			if(inputVal) {  // column input
	    		//				scriptInputs[key] = { id : inputVal.id };
	    		//			} else { // regular string
	    		//				scriptInputs[key] = input;
	    		//			}
	    	}
	    	else if ((typeof input) == 'number'){// regular number
	    		//scriptInputs[key] = input;
	    	} 
	    	else if ((typeof input) == 'boolean'){ // boolean 
	    		//scriptInputs[key] = input;
	    	}
	    	else{
				console.log("unknown script input type ", input);
			}
    	}
    	
    	//TODO confirm if this is the right way
    	if($.inArray(typedInputObjects, filteredRowsObject) != 0 && queryService.cache.scriptMetadata)//if it contains the filtered rows
    		{
	    		var scriptMetadata = queryService.cache.scriptMetadata;
	    		for(var x in scriptMetadata.inputs){
	    			var singleInput = scriptMetadata.inputs[x];
	    			filteredRowsObject.names.push(singleInput.param);
	    		}
    		}
    	
    	
    	return typedInputObjects;
    };
    
	/**
	 * this function processes the queryObject and makes the async call for running the script
	 */
	this.run = function() {
		if(queryService.queryObject.properties.isQueryValid) {
			var time1;
			var time2;
			var startTimer;
			var endTimer;
			
			//setting the query Object to be used for executing the query
			var queryObject = queryService.queryObject;
			var scriptInputObjects = [];//final collection of script input objects
			
			//handling script inputs
			scriptInputObjects = this.handleScriptOptions(queryObject.scriptOptions);

			//TODO handle filters before handling script options
				
			//FILTERS
	//			if(queryObject.GeographyFilter) {
	//				var geoQuery = {};
	//				var stateId = "";
	//				var countyId = "";
	//				
	//				if(queryObject.GeographyFilter.stateColumn.id) {
	//					stateId = queryObject.GeographyFilter.stateColumn.id;
	//				}
	//				if(queryObject.GeographyFilter.countyColumn.id) {
	//					countyId = queryObject.GeographyFilter.countyColumn.id;
	//				}
	//
	//				geoQuery.or = [];
	//				
	//				if(queryObject.GeographyFilter.hasOwnProperty("filters")) {
	//					if(Object.keys(queryObject.GeographyFilter.filters).length !== 0) {
	//						for(var key in queryObject.GeographyFilter.filters) {
	//							var index = geoQuery.or.push({ and : [
	//							                                      {cond : { 
	//							                                    	  f : stateId, 
	//							                                    	  v : [key] 
	//							                                      }
	//							                                      },
	//							                                      {cond: {
	//							                                    	  f : countyId, 
	//							                                    	  v : []
	//							                                      }
	//							                                      }
	//							                                      ]
	//							});
	//							for(var i in queryObject.GeographyFilter.filters[key].counties) {
	//								var countyFilterValue = "";
	//								for(var key2 in queryObject.GeographyFilter.filters[key].counties[i]) {
	//									countyFilterValue = key2;
	//								}
	//								geoQuery.or[index-1].and[1].cond.v.push(countyFilterValue);
	//							}
	//						}
	//						if(geoQuery.or.length) {
	//							nestedFilterRequest.and.push(geoQuery);
	//						}
	//					}
	//				}
	//			}
	//			
	//			if(queryObject.hasOwnProperty("TimePeriodFilter")) {
	//				var timePeriodQuery = {};
	//				var yearId = queryObject.TimePeriodFilter.yearColumn.id;
	//				var monthId = queryObject.TimePeriodFilter.monthColumn.id;
	//				
	//				timePeriodQuery.or = [];
	//				
	//				for(var key in queryObject.TimePeriodFilter.filters) {
	//					var index = timePeriodQuery.or.push({ and : [
	//					                                             {cond : { 
	//					                                            	 f : yearId, 
	//					                                            	 v : [key] 
	//					                                             }
	//					                                             },
	//					                                             {cond: {
	//					                                            	 f : monthId, 
	//					                                            	 v : []
	//					                                             }
	//					                                             }
	//					                                             ]
	//					});
	//					for(var i in queryObject.TimePeriodFilter.filters[key].months) {
	//						var monthFilterValue = "";
	//						for(var key2 in queryObject.TimePeriodFilter.filters[key].months[i]) {
	//							monthFilterValue = key2;
	//						}
	//						timePeriodQuery.or[index-1].and[1].cond.v.push(monthFilterValue);
	//					}
	//				}
	//				
	//				if(timePeriodQuery.or.length) {
	//					nestedFilterRequest.and.push(timePeriodQuery);
	//				}
	//			}
	//			
	//			if(queryObject.hasOwnProperty("ByVariableFilter")) {
	//				var byVarQuery = {and : []};
	//
	//				for(var i in queryObject.ByVariableFilter) {
	//					
	//					if(queryObject.ByVariableFilter[i].hasOwnProperty("column")) {
	//						var cond = {f : queryObject.ByVariableFilter[i].column.id };
	//						
	//						if(queryObject.ByVariableFilter[i].hasOwnProperty("filters")) {
	//							cond.v = [];
	//							for (var j in queryObject.ByVariableFilter[i].filters) {
	//								cond.v.push(queryObject.ByVariableFilter[i].filters[j].value);
	//							}
	//							byVarQuery.and.push({cond : cond});
	//						} else if (queryObject.ByVariableFilter[i].hasOwnProperty("ranges")) {
	//							cond.r = [];
	//							for (var j in queryObject.ByVariableFilter[i].filters) {
	//								cond.r.push(queryObject.ByVariableFilter[i].filters[j]);
	//							}
	//							byVarQuery.and.push({cond : cond});
	//						} 
	//					}
	//				}
	//
	//				if(byVarQuery.and.length) {
	//					nestedFilterRequest.and.push(byVarQuery);
	//				}
	//			}
	//			
	//			
	//			if(nestedFilterRequest.and.length) {
	//				filters = nestedFilterRequest;
	//			} else {
	//				filters = null;
	//			}
	//			
				scriptName = queryObject.scriptSelected;
				// var stringifiedQO = JSON.stringify(queryObject);
				// console.log("query", stringifiedQO);
				// console.log(JSON.parse(stringifiedQO));
				queryService.queryObject.properties.queryDone = false;
				queryService.queryObject.properties.queryStatus = "Loading data from database...";
				startTimer = new Date().getTime();
				
				console.log("indicatorRemap", queryService.queryObject.IndicatorRemap);
				
				//getting the data
				this.getDataFromServer(scriptInputObjects, queryService.queryObject.IndicatorRemap).then(function(success) {
					if(success) {
						time1 =  new Date().getTime() - startTimer;
						startTimer = new Date().getTime();
						queryService.queryObject.properties.queryStatus = "Running analysis...";
						
						//executing the script
						that.runScript(scriptName).then(function(resultData) {
							if(!angular.isUndefined(resultData))
							{
								time2 = new Date().getTime() - startTimer;
								queryService.queryObject.properties.queryDone = true;
								//queryService.queryObject.properties.resultData = resultData;
								queryService.queryObject.properties.queryStatus = "Data Load: "+(time1/1000).toPrecision(2)+"s" + ",   Analysis: "+(time2/1000).toPrecision(2)+"s";
								if(WeaveService.weave){
									WeaveService.addCSVData(resultData, queryService.queryObject.Indicator.title, queryService.queryObject);
									console.log(queryService.queryObject.resultSet);
								}
							} else {
								queryService.queryObject.properties.queryDone = false;
								queryService.queryObject.properties.queryStatus = "Error running script. See error log for details.";
							}
						});
					} else {
						queryService.queryObject.properties.queryDone = false;
						queryService.queryObject.properties.queryStatus = "Error Loading data. See error log for details.";
					}
				});
				
			}//validation check
		};
}]);

qh_module.controller('QueryHandlerCtrl', function($scope, queryService, QueryHandlerService) {
	
	$scope.service = queryService;
	$scope.runService = QueryHandlerService;
	
});