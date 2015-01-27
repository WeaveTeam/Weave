/**
 * This Service is designed to receive a query object and interpret its content.
 * 
 **/
//var computationServiceURL = '/WeaveAnalystServices/ComputationalServlet';
var check;
var qh_module = angular.module('aws.QueryHandlerModule', []);

qh_module.service('QueryHandlerService', ['$q', '$rootScope','queryService','WeaveService','errorLogService','runQueryService','computationServiceURL', '$window', '$modal',
                                 function($q, scope, queryService, WeaveService, errorLogService,runQueryService, $window, $modal) {
	
	//this.WeaveService.weaveWindow;
	var scriptInputs = {};
	var filters = {};
	var scriptName = ""; 
	
	//var queryObject = queryService.queryObject;
	var nestedFilterRequest = {and : []};
	
	var that = this; // point to this for async responses
	
    /*
     * this function handles different types of script inputs and returns an object of this signature
     * {
				type : eg filtered rows, column matrix, single values, numbers, boolean
				name : describes the purpose of the calculation , example for  correlations, summaryStats etc
				value :  the actual data value
		}
     * */
    this.handleScriptOptions = function(scriptOptions)
    {	
    	var typedInputObjects= [];
    	//TODO create remaining beans
    	
    	//Filtered Rows bean(each column is assigned a name when it reaches the computation engine)
    	var rowsObject = {
    			name: "", //(optional)needed for handling different kinds of results on client end
    			type: "",//this will be decided depending on what type of object is being sent to server
    			value: {
    				columnIds : [],
    				namesToAssign: [],
    				filters: null //will be {} once filters are completed
    				
    			}
    	};
    	
    	
    	for(var key in scriptOptions) {
			var input = scriptOptions[key];
			
			
	    	if((typeof input) == 'object') {
	    		
	    		rowsObject.value.columnIds.push(input.id);
	    		
	    		if($.inArray(rowsObject,typedInputObjects) == -1)//if not present in array before
	    			typedInputObjects.push(rowsObject);
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
    	if($.inArray(typedInputObjects, rowsObject) != 0 && queryService.cache.scriptMetadata)//if it contains the filtered rows
    		{
    			//handling filtered rows
    			//handling column titles for variable assignment
	    		var scriptMetadata = queryService.cache.scriptMetadata;
	    		for(var x in scriptMetadata.inputs){
	    			var singleInput = scriptMetadata.inputs[x];
	    			rowsObject.value.namesToAssign.push(singleInput.param);
	    		}
	    		
	    		rowsObject.type = "FilteredRows";
    		}
    	
    	
    	return typedInputObjects;
    };
    
	/**
	 * this function processes the received queryObject and makes the async call for running the script
	 */
	this.run = function(incoming_queryObject) {
		if(incoming_queryObject.properties.isQueryValid) {
			var time1;
			var time2;
			var startTimer;
			var endTimer;
			
			//setting the query Object to be used for executing the query
			var queryObject = incoming_queryObject;
			var scriptInputObjects = [];//final collection of script input objects
			
			//handling script inputs
			scriptInputObjects = this.handleScriptOptions(queryObject.scriptOptions);

			//TODO handle filters before handling script options
				
				scriptName = queryObject.scriptSelected;
				 var stringifiedQO = JSON.stringify(queryObject);
				 console.log("query", stringifiedQO);
				 console.log(JSON.parse(stringifiedQO));
				queryService.queryObject.properties.queryDone = false;
				queryService.queryObject.properties.queryStatus = "Loading data from database...";
				startTimer = new Date().getTime();
				
				console.log("indicatorRemap", queryService.queryObject.IndicatorRemap);
				
				//getting the data
				queryService.getDataFromServer(scriptInputObjects, queryService.queryObject.IndicatorRemap).then(function(success) {
					if(success) {
						time1 =  new Date().getTime() - startTimer;
						startTimer = new Date().getTime();
						queryService.queryObject.properties.queryStatus = "Running analysis...";
						
						//executing the script
						queryService.runScript(scriptName).then(function(resultData) {
							if(!angular.isUndefined(resultData))
							{
								time2 = new Date().getTime() - startTimer;
								queryService.queryObject.properties.queryDone = true;
								//queryService.queryObject.properties.resultData = resultData;
								queryService.queryObject.properties.queryStatus = "Data Load: "+(time1/1000).toPrecision(2)+"s" + ",   Analysis: "+(time2/1000).toPrecision(2)+"s";
								if(WeaveService.weave){
									
									//convert result into csvdata format
									var formattedResult = WeaveService.createCSVDataFormat(resultData.resultData, resultData.columnNames);
									//create the CSVDataSource
									WeaveService.addCSVData(formattedResult, queryService.queryObject.Indicator.title, queryService.queryObject);
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
	$scope.QueryHandlerService = QueryHandlerService;
	
});