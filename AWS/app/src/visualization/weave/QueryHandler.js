/**
 * This Service is designed to receive a query object and interpret its content.
 * 
 **/
var qh_module = angular.module('aws.QueryHandlerModule', []);

qh_module.service('QueryHandlerService', ['$q', '$rootScope','queryService','WeaveService','errorLogService','runQueryService', 'd3Service','usSpinnerService', '$window', '$modal',
                                 function($q, scope, queryService, WeaveService, errorLogService,runQueryService,d3Service,usSpinnerService, $window, $modal) {
	
	var scriptInputs = {};
	var filters = {};
	var scriptName = ""; 
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
    			type: "filteredRows",//this will be decided depending on what type of object is being sent to server
    			value: {
    				columnIds : [],
    				namesToAssign: [],
    				filters: nestedFilterRequest.and.length ? nestedFilterRequest : null //will be {} once filters are completed
    				
    			}
    	};
    	
    	
    	for(var key in scriptOptions) {
			var input = scriptOptions[key];
			
			// handle multiColumns. Note that we do this first because type of arrayVariabel == 'object' returns true.
			if(Array.isArray(input)) {
				typedInputObjects.push({
					name : key,
					type : 'dataColumnMatrix',
					value : {
						
						columnIds : $.map(input, function(column) {
							return column.id;
						}), 
						filters : nestedFilterRequest.and.length ? nestedFilterRequest : null,
						namesToAssign : $.map(input, function(column) {
							return column.title;
						})
					}
				});
			} 
			
			// handle single column
			else if((typeof input) == 'object') {
	    		rowsObject.value.columnIds.push(input.id);
    			rowsObject.value.namesToAssign.push(key);
	    		if($.inArray(rowsObject,typedInputObjects) == -1)//if not present in array before
	    			typedInputObjects.push(rowsObject);
	    	}

			else if ((typeof input) == 'string'){
				typedInputObjects.push({
					name : key, 
					type : 'string',
					value : input
				});
	    	}
	    	else if ((typeof input) == 'number'){// regular number
	    		typedInputObjects.push({
					name : key, 
					type : 'number',
					value : input
				});
	    	} 
	    	else if ((typeof input) == 'boolean'){ // boolean 
	    		typedInputObjects.push({
					name : key, 
					type : 'boolean',
					value : input
				});
	    	}
	    	else{
				console.log("unknown script input type ", input);
			}
    	}
    	
    	return typedInputObjects;
    };
    
    /**
     * this  function handles the re-identification during aggregation   
     */
    this.handleReidentification = function(scriptInputObjects){
    	
    	scriptInputObjects.push({
			type : "Reidentification",
			name: "ReIdPrevention",
			value : queryService.queryObject.Reidentification
		});
    	
    };
    /**
     * this function converts the columnRemap object into a
     * java bean
     */
    this.handleColumnRemap = function(jsColumnRemap) {
    	
    	var remapObjects = [];
    	for(title in jsColumnRemap) {
    		remapObject = {
				columnName : title,
				originalValues : [],
				reMappedValues : []
    		};
    		remapValues = jsColumnRemap[title];
    		for(oldVal in remapValues)
    		{
    			remapObject.originalValues.push(oldVal);
    			remapObject.reMappedValues.push(remapValues[oldVal]);
    		}
    		remapObjects.push(remapObject);
    	}
    	return remapObjects;
    };
    
    /**
     * this function handles geography filters
     **/
    this.handleGeographyFilters = function(incoming_qo){
    	var geoQuery = {};
    	geoQuery.or = [];
 
    	if(incoming_qo.GeographyFilter.stateColumn.id)
    		incoming_qo.GeographyFilter.selectedStates = d3Service.mapT.cache.selectedStates;
    	if(incoming_qo.GeographyFilter.countyColumn.id)
    		incoming_qo.GeographyFilter.selectedCounties = d3Service.mapT.cache.selectedCounties;

		
		
			//state filter
			if(!incoming_qo.GeographyFilter.countyColumn)
			{
				var states = [];
				for(var state in incoming_qo.GeographyFilter.selectedStates)
				{
					states.push(state);
				}
				
				
				geoQuery = 	{
								  cond : { 
									  		f : incoming_qo.GeographyFilter.stateColumn.id, 
									  		v : states
								  		 }
							};
											
				
				
				nestedFilterRequest.and.push(geoQuery);
			}
			// state + county filter
			else
			{
				for(var key in incoming_qo.GeographyFilter.selectedCounties)
				{
					geoQuery.or.push({ and : [
												{
													  cond : { 
														  		f : incoming_qo.GeographyFilter.nestedStateColumn.id, 
														  		v : key
													  		 }
												},
												{
													  cond: {
														  		f : incoming_qo.GeographyFilter.countyColumn.id,
														  		v : Object.keys(incoming_qo.GeographyFilter.selectedCounties[key].counties)
													  		}
												}
												]});
				}
				if(geoQuery.or.length) {
					nestedFilterRequest.and.push(geoQuery);
				}
			}
			
				
    };
    
    

    this.run = function(queryObject) {
    	if(queryObject.properties.isQueryValid) {
    		if(WeaveService.weave)
			{
    			//var rDataSourceName = WeaveService.generateUniqueName("RDataSource");
    			var rDataSourcePath = weave.path("RDataSource").request("RDataSource").exec("getCallbackCollection(this).delayCallbacks()");
				var inputsPath = rDataSourcePath.push("inputs");
				for(var key in queryObject.scriptOptions)
				{
					var input = queryObject.scriptOptions[key];
					// check if the input is a column
					if(typeof input == "object") {
						if(input.dataSourceName && input.metadata) {
							inputsPath.push(key).request("DynamicColumn").setColumn(input.metadata, input.dataSourceName);
						}
					} else {
						inputsPath.push(key).request("LinkableVariable").state(input);
					}
				}
				
				rDataSourcePath.push("scriptName").state(queryObject.scriptSelected);
				rDataSourcePath.exec("getCallbackCollection(this).resumeCallbacks(); hierarchyRefresh.triggerCallbacks();");
				
				queryService.refreshHierarchy(WeaveService.weave);
			}
    	}
    };
    
	/**
	 * this function processes the received queryObject and makes the async call for running the script
	 */
//	this.run = function(incoming_queryObject) {
//		if(incoming_queryObject.properties.isQueryValid) {
//			var time1;
//			var time2;
//			var startTimer;
//			var endTimer;
//			
//			var queryObject = incoming_queryObject;
//			var scriptInputObjects = [];//final collection of script input objects
//			
//			usSpinnerService.spin('roundtrip-spinner');
//			
//			nestedFilterRequest = {and : []}; // clear the nested filter object at each run.
//			
//			//HANDLING FILTERS
//			if(queryObject.GeographyFilter)
//			{
//				this.handleGeographyFilters(queryObject);
//			}
//			
//			queryService.queryObject.filters.forEach(function(filter) {
//				if(filter.nestedFilter && filter.nestedFilter.cond) {
//					nestedFilterRequest.and.push(filter.nestedFilter);
//				}
//			});
//			
//			queryService.queryObject.treeFilters.forEach(function(filter) {
//				if(filter.nestedFilter && ((filter.nestedFilter.or && filter.nestedFilter.or.length)
//									   || (filter.nestedFilter.cond))) {
//					nestedFilterRequest.and.push(filter.nestedFilter);
//				}
//			});
//			
//			console.log(nestedFilterRequest);
//	
//			//console.log(nestedFilterRequest);
//			//handling script inputs
//			scriptInputObjects = this.handleScriptOptions(queryObject.scriptOptions);
//			
//			var remapObjects = this.handleColumnRemap(queryObject.columnRemap);
//			
//			//handles re-identification for aggregation scripts
//			this.handleReidentification(scriptInputObjects);
//
//			scriptName = queryObject.scriptSelected;
//			 //var stringifiedQO = JSON.stringify(queryObject);
//			 //console.log("query", stringifiedQO);
//			 //console.log(JSON.parse(stringifiedQO));
//			queryService.queryObject.properties.queryDone = false;
//			queryService.queryObject.properties.queryStatus = "Loading data from database...";
//			startTimer = new Date().getTime();
//				
//				//getting the data
//				queryService.getDataFromServer(scriptInputObjects, remapObjects).then(function(numRows) {
//					if(numRows > 0) {
//						time1 =  new Date().getTime() - startTimer;
//						startTimer = new Date().getTime();
//						queryService.queryObject.properties.queryStatus = numRows + " records. Running analysis...";
//						
//						//executing the script
//						queryService.runScript(scriptName).then(function(resultData) {
//							if(!angular.isUndefined(resultData))
//							{
//								console.log(resultData);
//								time2 = new Date().getTime() - startTimer;
//								queryService.queryObject.properties.queryDone = true;
//								queryService.queryObject.properties.queryStatus = "Data Load: "+(time1/1000).toPrecision(2)+"s" + ",   Analysis: "+(time2/1000).toPrecision(2)+"s";
//								
//								if(WeaveService.weave){
//									
//									//convert result into csvdata format
//									var formattedResult = WeaveService.createCSVDataFormat(resultData.resultData, resultData.columnNames);
//									//create the CSVDataSource]
//									var dsn = queryService.queryObject.Indicator ? queryService.queryObject.Indicator.title : "";
//									WeaveService.addCSVData(formattedResult, dsn, queryService.queryObject);
//									
//									usSpinnerService.stop('roundtrip-spinner');//TODO handle areas of control for spinner
//								}
//							}
//						}, function(error) {
//							queryService.queryObject.properties.queryDone = false;
//							queryService.queryObject.properties.queryStatus = "Error running script. See error log for details.";
//							usSpinnerService.stop('roundtrip-spinner');//TODO handle areas of control for spinner
//						});
//					} else {
//						queryService.queryObject.properties.queryStatus = "Data request did not return any rows";
//						usSpinnerService.stop('roundtrip-spinner');//TODO handle areas of control for spinner
//					}
//				}, function(error) {
//					queryService.queryObject.properties.queryDone = false;
//					queryService.queryObject.properties.queryStatus = "Error Loading data. See error log for details.";
//					usSpinnerService.stop('roundtrip-spinner');//TODO handle areas of control for spinner
//				});
//			}//validation check
//		};
}]);