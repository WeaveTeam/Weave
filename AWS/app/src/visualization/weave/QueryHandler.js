/**
 * This Service is designed to receive a query object and interpret its content.
 * 
 **/
var qh_module = angular.module('aws.QueryHandlerModule', []);

qh_module.service('QueryHandlerService', ['$q', '$rootScope','queryService','WeaveService','errorLogService','runQueryService','geoService', '$window', '$modal',
                                 function($q, scope, queryService, WeaveService, errorLogService,runQueryService,geoService, $window, $modal) {
	
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
     * this function handles geography filters
     **/
    this.handleGeographyFilters = function(incoming_qo){
    	var geoQuery = {};
    	var currentGeo;
    	var tempGeoFilter;
 
    	incoming_qo.GeographyFilter.filters = geoService.selectedGeographies;

		geoQuery.or = [];
		
		if(incoming_qo.GeographyFilter.hasOwnProperty("filters")) {
			if(Object.keys(incoming_qo.GeographyFilter.filters).length !== 0)
			{
				//state filter
				if(!incoming_qo.GeographyFilter.countyColumn)
				{
					var states = [];
					for(var state in incoming_qo.GeographyFilter.filters)
					{
						states.push(state);
					}
					
					
					geoQuery = 	{
									  cond : { 
										  		f : incoming_qo.GeographyFilter.stateColumn.id, 
										  		v : states
									  		 }
								};
												
					
					console.log("geoQuery", geoQuery);
				}
				// state + county filter
				else
				{
					for(var key in incoming_qo.GeographyFilter.filters)
					{
						var counties = [];
						var singleState = incoming_qo.GeographyFilter.filters[key].counties;
						console.log("single state", singleState);
						
						counties = Object.keys(singleState);
						geoQuery.or.push({ and : [
													{
														  cond : { 
															  		f : incoming_qo.GeographyFilter.nestedStateColumn.id, 
															  		v : [key] 
														  		 }
													},
													{
														  cond: {
															  		f : incoming_qo.GeographyFilter.countyColumn.id,
															  		v : counties
														  		}
													}
													]});
					}
					console.log("geoQuery", geoQuery);
				}
				
				
//				for(var key in incoming_qo.GeographyFilter.filters)
//				{
//					var index = geoQuery.or.push({ and : [
//					                                      {
//					                                    	  cond : { 
//					                                    		  		f : stateId, 
//					                                    		  		v : [key] 
//					                                    	  		 }
//					                                      },
//					                                      {
//					                                    	  cond: {
//					                                    		  		f : countyId, 
//					                                    		  		v : []
//					                                    	  		}
//					                                      }
//					                                      ]});
//					console.log("geoQuery", geoQuery);
//					for(var i in incoming_qo.GeographyFilter.filters[key].counties) 
//					{
//						var countyFilterValue = "";
//						for(var key2 in incoming_qo.GeographyFilter.filters[key].counties[i]) 
//						{
//							countyFilterValue = key2;
//						}
//						geoQuery.or[index-1].and[1].cond.v.push(countyFilterValue);
//					}
//				}
				if(geoQuery.or.length) {
					nestedFilterRequest.and.push(geoQuery);
				}
			}
		}
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
			
			var queryObject = incoming_queryObject;
			var scriptInputObjects = [];//final collection of script input objects
			
			//TODO handle filters before handling script options
			//handling geo filters
			if(queryObject.GeographyFilter)
			{
				this.handleGeographyFilters(queryObject);
			}
			
			
			//		
			//		if(nestedFilterRequest.and.length) {
			//			filters = nestedFilterRequest;
			//		} else {
			//			filters = null;
			//		}
			
			//handling script inputs
			scriptInputObjects = this.handleScriptOptions(queryObject.scriptOptions);
			
			//handles re-identification for aggregation scripts
			this.handleReidentification(scriptInputObjects);

			//console.log("scriptInputObjects", scriptInputObjects);
				scriptName = queryObject.scriptSelected;
				 //var stringifiedQO = JSON.stringify(queryObject);
				 //console.log("query", stringifiedQO);
				 //console.log(JSON.parse(stringifiedQO));
				queryService.queryObject.properties.queryDone = false;
				queryService.queryObject.properties.queryStatus = "Loading data from database...";
				startTimer = new Date().getTime();
				
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
								queryService.queryObject.properties.queryStatus = "Data Load: "+(time1/1000).toPrecision(2)+"s" + ",   Analysis: "+(time2/1000).toPrecision(2)+"s";
								
								if(WeaveService.weave){
									
									//convert result into csvdata format
									var formattedResult = WeaveService.createCSVDataFormat(resultData.resultData, resultData.columnNames);
									//create the CSVDataSource
									WeaveService.addCSVData(formattedResult, queryService.queryObject.Indicator.title, queryService.queryObject);
									console.log(queryService.queryObject.resultSet);
								}
							}
						}, function(error) {
							queryService.queryObject.properties.queryDone = false;
							queryService.queryObject.properties.queryStatus = "Error running script. See error log for details.";
						});
					}
				}, function(error) {
					queryService.queryObject.properties.queryDone = false;
					queryService.queryObject.properties.queryStatus = "Error Loading data. See error log for details.";
				});
				
			}//validation check
		};
}]);