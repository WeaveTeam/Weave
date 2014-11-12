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
	//booleans used for validation of a query object
	this.isValidated = true;
	this.validationUpdate = "Ready for validation";
	
	//boolean used for displaying the Visualization widget tool menu
	//only when results are returned and Weave pops up, should this menu be enabled
	this.displayVizMenu = false;
	
	//var queryObject = queryService.queryObject;
	var nestedFilterRequest = {and : []};
	
	var that = this; // point to this for async responses
	

	this.waitForWeave = function(popup, callback)
	{
		function checkWeaveReady() {
			var weave;
			if(popup) {
				weave = popup.document.getElementById('weave');
			} else {
				weave = document.getElementById('weave');
			}
	        if (weave && weave.WeavePath) {
	    		weave.loadFile('minimal.xml', callback.bind(this, weave));
	        }
	        else
	            setTimeout(checkWeaveReady, 50);
	    }
	    
		checkWeaveReady();
	};

	
	
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
    
    this.getDataFromServer = function(inputs, filters, reMaps) {
    	
    	var deferred = $q.defer();

    	runQueryService.queryRequest(computationServiceURL, 'getDataFromServer', [inputs, filters, reMaps], function(result){	
    		scope.$safeApply(function() {
				deferred.resolve(result);
			});
		});
    	
        return deferred.promise;
    };
    
  
	/**
	 * this function processes the queryObject and makes the async call for running the script
	 * @param runInRealTime this parameter serves as a flag which determines if the Weave JS Api should be run
	 * automatically or for user to interact
	 * true : user interaction required
	 * false: no user interaction required, run automatically
	 */
	this.run = function(runInRealTime) {
		
		if(queryService.dataObject.isQueryValid) {
			
				//setting the query Object to be used for executing the query
				var queryObject = queryService.queryObject;
				//running an initial validation
				
				var scriptInputs = {};
				var time1;
				var time2;
				var startTimer;
				var endTimer;
				
				if(this.isValidated)
				{
					for(var key in queryObject.scriptOptions) {
						var input = queryObject.scriptOptions[key];
						switch(typeof input) {
						case 'object' :
							scriptInputs[key] = input;
							break;
						case 'array': // array of columns
							scriptInputs[key] = $.map(input, function(inputVal) {
								return { id : JSON.parse(inputVal).id };
							});
							break;
						case 'string' :
							var inputVal = tryParseJSON(input);
							if(inputVal) {  // column input
								scriptInputs[key] = { id : inputVal.id };
							} else { // regular string
								scriptInputs[key] = input;
							}
							break;
						case 'number' : // regular number
							scriptInputs[key] = input;
							break;
						case 'boolean' : // boolean 
							scriptInputs[key] = input;
							break;
						default:
							console.log("unknown script input type ", input);
						}
					}
					
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
					queryService.dataObject.queryDone = false;
					queryService.dataObject.queryStatus = "Loading data from database...";
					startTimer = new Date().getTime();
					console.log("indicatorRemap", queryService.queryObject.IndicatorRemap);
					this.getDataFromServer(scriptInputs, null, queryService.queryObject.IndicatorRemap).then(function(success) {
						if(success) {
							time1 =  new Date().getTime() - startTimer;
							startTimer = new Date().getTime();
							queryService.dataObject.queryStatus = "Running analysis...";
							that.runScript(scriptName).then(function(resultData) {
								if(!angular.isUndefined(resultData))//only if something is returned open weave
								{
									time2 = new Date().getTime() - startTimer;
									queryService.dataObject.queryDone = true;
									queryService.dataObject.resultData = resultData;
									queryService.dataObject.queryStatus = "Data Load: "+(time1/1000).toPrecision(2)+"s" + ",   Analysis: "+(time2/1000).toPrecision(2)+"s";
									if(queryService.dataObject.openInNewWindow) {
										if(!WeaveService.weaveWindow || WeaveService.weaveWindow.closed) {
											WeaveService.weaveWindow = $window.open("/weave.html?",
													"abc","toolbar=no, fullscreen = no, scrollbars=yes, addressbar=no, resizable=yes");
										}
										that.waitForWeave(WeaveService.weaveWindow , function(weave) {
											WeaveService.weave = weave;
											WeaveService.addCSVData(resultData);
											WeaveService.columnNames = resultData[0];
											
											//updates required for updating query object validation and to enable visualization widget controls
											that.displayVizMenu = true;
											that.isValidated = false;
											that.validationUpdate = "Ready for validation";
											
											scope.$apply();//re-fires the digest cycle and updates the view
										});
									} else {
										that.waitForWeave(null , function(weave) {
											WeaveService.weave = weave;
											WeaveService.addCSVData(resultData);
											WeaveService.columnNames = resultData[0];
											
											//updates required for updating query object validation and to enable visualization widget controls
											that.isValidated = false;
											that.validationUpdate = "Ready for validation";
											scope.$apply();//re-fires the digest cycle and updates the view
										});
									}
								} else {
									queryService.dataObject.queryDone = false;
									queryService.dataObject.queryStatus = "Error running script. See error log for details.";
								}
							});
							
						} else {
							queryService.dataObject.queryDone = false;
							queryService.dataObject.queryStatus = "Error Loading data. See error log for details.";
						}
					});
				}
				
			}
		};
}]);

qh_module.controller('QueryHandlerCtrl', function($scope, queryService, QueryHandlerService) {
	
	$scope.service = queryService;
	$scope.runService = QueryHandlerService;
	
});