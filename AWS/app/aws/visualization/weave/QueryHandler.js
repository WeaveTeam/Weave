/**
 * This Service is designed to receive a query object and interpret its content.
 * 
 **/
//var computationServiceURL = '/WeaveAnalystServices/ComputationalServlet';

var qh_module = angular.module('aws.QueryHandlerModule', []);
var weaveWindow;

qh_module.service('QueryHandlerService', ['$q', '$rootScope','queryService','WeaveService','errorLogService','runQueryService','computationServiceURL', '$window', '$modal',
                                 function($q, scope, queryService, WeaveService, errorLogService,runQueryService,computationServiceURL, $window, $modal) {
	
	//this.weaveWindow;
	var scriptInputs = {};
	var filters = {};
	var scriptName = ""; 
	//booleans used for validation of a query object
	this.isValidated = false;
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
	    	
	        var weave = $('#weave');
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
    	runQueryService.queryRequest(computationServiceURL, 'runScript', [scriptName, inputs, filters], function(result){	
//    		if(result.logs != null){
//    			errorLogService.logInErrorLog(result.logs[0]);
//    			$modal.open(errorLogService.errorLogModalOptions);
//    		}

    		scope.$safeApply(function() {
				deferred.resolve(result);
			});
		});
    	
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
    	
    	var scriptOptionsComplete = false;//true if all parameters have been filled in by UI
    	var counter = Object.keys(queryObjectToValidate.scriptOptions).length;
    	if(!scriptOptionsComplete)
    	{
    		var g = 0;
    		for(var f in queryObjectToValidate.scriptOptions)
    		{
    			//var check = queryObjectToValidate.scriptOptions[f];
    			if(!(queryObjectToValidate.scriptOptions[f]))
    				{
    				    console.log("param", f);
	    				alert(f + " parameter has not been entered");
	    				break;
    				}
    			else
    				g++;
    		}
    		if(g == counter)
    			scriptOptionsComplete = true;
    		
    	}
    	
    	
    	if(queryObjectToValidate.dataTable && queryObjectToValidate.scriptSelected && scriptOptionsComplete)
    		{
    			this.isValidated = true;
    			this.validationUpdate = "Your query object is validated";
    		}
    	else
    		{
	    		console.log("Please select a datatable, select a script and enter ALL script parameters");
	    		this.validationUpdate = "Your query object is not validated";
	    		this.isValidated = false;
    		
    		}
    	
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
			

			this.runScript(scriptName, scriptInputs, null).then(function(resultData) {
				if(!angular.isUndefined(resultData.data))//only if something is returned open weave
					{
						WeaveService.addCSVData(resultData.data);
						WeaveService.columnNames = resultData.data[0];
						that.isValidated = false;
						that.validationUpdate = "Ready for validation";
//						if(!weaveWindow || weaveWindow.closed) {
//							weaveWindow = $window.open("/weave.html?",
//									"abc","toolbar=no, fullscreen = no, scrollbars=yes, addressbar=no, resizable=yes");
//						}
//						that.waitForWeave(weaveWindow , function(weave) {
//							//WeaveService.weave = weave;
//							WeaveService.addCSVData(resultData.data);
//							WeaveService.columnNames = resultData.data[0];
//							
//							//updates required for updating query object validation and to enable visualization widget controls
//							//that.displayVizMenu = true;
//							that.isValidated = false;
//							that.validationUpdate = "Ready for validation";
//							
//							scope.$apply();//re-fires the digest cycle and updates the view
//						});
					}
				
			});
		}
	
	};
	
	
}]);

qh_module.controller('QueryHandlerCtrl', function($scope, queryService, QueryHandlerService) {
	
	$scope.service = queryService;
	$scope.runService = QueryHandlerService;
});