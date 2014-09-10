/**
 * This Service is designed to receive a query object and interpret its content.
 * 
 **/
var computationServiceURL = '/WeaveAnalystServices/ComputationalServlet';

var qh_module = angular.module('aws.QueryHandlerModule', []);
var weaveWindow;

qh_module.service('QueryHandlerService', 
		['$q', '$rootScope','queryService','WeaveService', '$window', function($q, scope, queryService, WeaveService, $window) {
	
	
	//this.weaveWindow;
	var scriptInputs = {};
	var filters = {};
	var scriptName = ""; 
	this.isValidated = false;
	//var queryObject = queryService.queryObject;
	var nestedFilterRequest = {and : []};
	
	var that = this; // point to this for async responses
	

	this.waitForWeave = function(popup, callback)
	{
	    function checkWeaveReady() {
	        var weave = popup.document.getElementById('weave');
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
    this.runScript = function(scriptName, inputs, filters) {
        
    	var deferred = $q.defer();
    	//setTimeout(function(){this.isValidated = false;console.log("reached here",this.isValidated );}, 3000);
//    	aws.queryService(computationServiceURL, 'runScript', [scriptName, inputs, filters], function(result){	
//    		scope.$safeApply(function() {
//				deferred.resolve(result);
//			});
//		});
    	
        return deferred.promise;
    };
    
    /**
     * this function will validate minimal requirements for a script to run
     * @param queryObjectToValidate the queryObject whose parameters will be checked before query execution
     */
    this.validateScriptExecution = function(queryObjectToValidate){
    	//check for a dataset
    	//check for a script
    	//check for script inputs
    	if(queryObjectToValidate.dataTable && queryObjectToValidate.scriptSelected )
    		{
	    		console.log("datatable check",queryObjectToValidate.dataTable, queryObjectToValidate.scriptSelected);
	    		this.isValidated = true;
    		}
    	else
    		console.log("Please select a datatable and select a script");
    	
    };
    
	/**
	 * this function processes the queryObject and makes the async call for running the script
	 * @param runInRealTime this parameter serves as a flag which determines if the Weave JS Api should be run
	 * automatically or for user to interact
	 * true : user interaction required
	 * false: no user interaction required, run automatically
	 */
	this.run = function(runInRealTime) {
		//setting the query Object to be used for executing the query
		var queryObject = queryService.queryObject;
		//running an initial validation
		this.validateScriptExecution(queryObject);
		console.log("validattion",this.isValidated );
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
						console.log("unknown script input type");
				}
			}
			
			if(queryObject.GeographyFilter) {
				var geoQuery = {};
				var stateId = "";
				var countyId = "";
				
				if(queryObject.GeographyFilter.stateColumn.id) {
					stateId = queryObject.GeographyFilter.stateColumn.id;
				}
				if(queryObject.GeographyFilter.countyColumn.id) {
					countyId = queryObject.GeographyFilter.countyColumn.id;
				}

				geoQuery.or = [];
				
				if(queryObject.GeographyFilter.hasOwnProperty("filters")) {
					if(Object.keys(queryObject.GeographyFilter.filters).length !== 0) {
						for(var key in queryObject.GeographyFilter.filters) {
							var index = geoQuery.or.push({ and : [
							                                      {cond : { 
							                                    	  f : stateId, 
							                                    	  v : [key] 
							                                      }
							                                      },
							                                      {cond: {
							                                    	  f : countyId, 
							                                    	  v : []
							                                      }
							                                      }
							                                      ]
							});
							for(var i in queryObject.GeographyFilter.filters[key].counties) {
								var countyFilterValue = "";
								for(var key2 in queryObject.GeographyFilter.filters[key].counties[i]) {
									countyFilterValue = key2;
								}
								geoQuery.or[index-1].and[1].cond.v.push(countyFilterValue);
							}
						}
						if(geoQuery.or.length) {
							nestedFilterRequest.and.push(geoQuery);
						}
					}
				}
			}
			
			if(queryObject.hasOwnProperty("TimePeriodFilter")) {
				var timePeriodQuery = {};
				var yearId = queryObject.TimePeriodFilter.yearColumn.id;
				var monthId = queryObject.TimePeriodFilter.monthColumn.id;
				
				timePeriodQuery.or = [];
				
				for(var key in queryObject.TimePeriodFilter.filters) {
					var index = timePeriodQuery.or.push({ and : [
					                                             {cond : { 
					                                            	 f : yearId, 
					                                            	 v : [key] 
					                                             }
					                                             },
					                                             {cond: {
					                                            	 f : monthId, 
					                                            	 v : []
					                                             }
					                                             }
					                                             ]
					});
					for(var i in queryObject.TimePeriodFilter.filters[key].months) {
						var monthFilterValue = "";
						for(var key2 in queryObject.TimePeriodFilter.filters[key].months[i]) {
							monthFilterValue = key2;
						}
						timePeriodQuery.or[index-1].and[1].cond.v.push(monthFilterValue);
					}
				}
				
				if(timePeriodQuery.or.length) {
					nestedFilterRequest.and.push(timePeriodQuery);
				}
			}
			
			if(queryObject.hasOwnProperty("ByVariableFilter")) {
				var byVarQuery = {and : []};

				for(var i in queryObject.ByVariableFilter) {
					
					if(queryObject.ByVariableFilter[i].hasOwnProperty("column")) {
						var cond = {f : queryObject.ByVariableFilter[i].column.id };
						
						if(queryObject.ByVariableFilter[i].hasOwnProperty("filters")) {
							cond.v = [];
							for (var j in queryObject.ByVariableFilter[i].filters) {
								cond.v.push(queryObject.ByVariableFilter[i].filters[j].value);
							}
							byVarQuery.and.push({cond : cond});
						} else if (queryObject.ByVariableFilter[i].hasOwnProperty("ranges")) {
							cond.r = [];
							for (var j in queryObject.ByVariableFilter[i].filters) {
								cond.r.push(queryObject.ByVariableFilter[i].filters[j]);
							}
							byVarQuery.and.push({cond : cond});
						} 
					}
				}

				if(byVarQuery.and.length) {
					nestedFilterRequest.and.push(byVarQuery);
				}
			}
			
			
			if(nestedFilterRequest.and.length) {
				filters = nestedFilterRequest;
			} else {
				filters = null;
			}
			
			scriptName = queryObject.scriptSelected;
			// var stringifiedQO = JSON.stringify(queryObject);
			// console.log("query", stringifiedQO);
			// console.log(JSON.parse(stringifiedQO));
			

			this.runScript(scriptName, scriptInputs, filters).then(function(resultData) {
				if(!angular.isUndefined(resultData.data))//only if something is returned open weave
					{
						if(!weaveWindow || weaveWindow.closed) {
							weaveWindow = $window.open("/weave.html?",
									"abc","toolbar=no, fullscreen = no, scrollbars=yes, addressbar=no, resizable=yes");
						}
						that.waitForWeave(weaveWindow , function(weave) {
							WeaveService.weave = weave;
							WeaveService.addCSVData(resultData.data);
							WeaveService.columnNames = resultData.data[0];
							console.log("service.validated", that);
							that.isValidated = false;
							console.log("service.validated", that);
							if(!runInRealTime)//if false
							{
								//check for the vizzies and make the required calls
								if(queryObject.BarChartTool.enabled){
									console.log("barchart tool enabled");
									WeaveService.BarChartTool(queryObject.BarChartTool);
								}
								if(queryObject.DataTableTool.enabled){
									console.log('dt tool enbaled');
									WeaveService.DataTableTool(queryObject.DataTableTool);
								}
								if(queryObject.ScatterPlotTool.enabled){
									console.log('scplot tool enabled');
									WeaveService.ScatterPlotTool(queryObject.ScatterPlotTool);
								}
								if(queryObject.MapTool.enabled){
									console.log('mp tool enabled');
									WeaveService.MapTool(queryObject.MapTool);
								}
								if(queryObject.ColorColumn){
									WeaveService.ColorColumn(queryObject.ColorColumn);
								}
							}
							$scope.$apply();
						});
					}
				
			});
		}
	
	};
	
	
}]);

qh_module.controller('QueryHandlerCtrl', function($scope, queryService, QueryHandlerService) {
	
	$scope.service = queryService;
	$scope.runService = QueryHandlerService;
	//$scope.isValidated = false;
	
//	$scope.$watch(function(){
//		return QueryHandlerService.isValidated;
//	}, function(){
//		$scope.isValidated = QueryHandlerService.isValidated;
//		console.log("in the service",QueryHandlerService.isValidated );
//		
//	});
	
//	$scope.isValidated = function(b)
//	{
//		if( typeof b === "undefined" )
//			return $scope.runService.isValidated;
//		
//		$scope.runService.isValidated = b;
//	};
});

