/**
 * This Service is designed to receive a query object and interpret its content.
 * 
 **/
var computationServiceURL = '/WeaveAnalystServices/ComputationalServlet';

var qh_module = angular.module('aws.QueryHandlerModule', []);

qh_module.service('QueryHandlerService',  ['$q', '$rootScope', function($q, scope) {
	
	this.weaveWindow;
	
	/**
     * This function wraps the async aws runScript function into an angular defer/promise
     * So that the UI asynchronously wait for the data to be available...
     */
    this.runScript = function(scriptName, inputs, filters) {
        
    	var deferred = $q.defer();

    	
    	aws.queryService(computationServiceURL, 'runScript', [scriptName, inputs, filters], function(result){	
    		scope.$safeApply(function() {
				deferred.resolve(result);
			});
		});
    	
        return deferred.promise;
    };
	
}]);

qh_module.controller('QueryHandlerCtrl', function($scope, queryService, QueryHandlerService, WeaveService, $window) {
	
	var scriptInputs = {};
	var filters = {};
	var scriptName = ""; 
	var queryObject = queryService.queryObject;
	var nestedFilterRequest = {and : []};
	
	$scope.service = queryService;
	
	$scope.run = function() {
		
		for(var key in queryObject.scriptOptions) {
			var input = queryObject.scriptOptions[key];
			switch(typeof input) {
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
		
		QueryHandlerService.runScript(scriptName, scriptInputs, filters).then(function(resultData) {
			if(!QueryHandlerService.weaveWindow || QueryHandlerService.weaveWindow.closed) {
				QueryHandlerService.weaveWindow = $window.open("aws/visualization/weave/weave.html",
						"abc","toolbar=no, fullscreen = no, scrollbars=yes, addressbar=no, resizable=yes");
			}
			
			WeaveService.resultData = resultData;
		});
	};
});