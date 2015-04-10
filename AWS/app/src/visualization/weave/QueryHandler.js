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
			
			queryService.queryObject.filters.forEach(function(filter) {
				if(filter.nestedFilter && filter.nestedFilter.cond) {
					nestedFilterRequest.and.push(filter.nestedFilter);
				}
			});
			
			queryService.queryObject.treeFilters.forEach(function(filter) {
				if(filter.nestedFilter && ((filter.nestedFilter.or && filter.nestedFilter.or.length)
									   || (filter.nestedFilter.cond))) {
					nestedFilterRequest.and.push(filter.nestedFilter);
				}
			});
	
			console.log(nestedFilterRequest);
			//handling script inputs
			scriptInputObjects = this.handleScriptOptions(queryObject.scriptOptions);
			
			var remapObjects = this.handleColumnRemap(queryObject.columnRemap);
			
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
				queryService.getDataFromServer(scriptInputObjects, remapObjects).then(function(numRows) {
					if(numRows > 0) {
						time1 =  new Date().getTime() - startTimer;
						startTimer = new Date().getTime();
						queryService.queryObject.properties.queryStatus = numRows + "returned. Running analysis...";
						
						//executing the script
						queryService.runScript(scriptName).then(function(resultData) {
							if(!angular.isUndefined(resultData))
							{
								console.log(resultData);
								time2 = new Date().getTime() - startTimer;
								queryService.queryObject.properties.queryDone = true;
								queryService.queryObject.properties.queryStatus = "Data Load: "+(time1/1000).toPrecision(2)+"s" + ",   Analysis: "+(time2/1000).toPrecision(2)+"s";
								
								if(WeaveService.weave){
									
									//convert result into csvdata format
									var formattedResult = WeaveService.createCSVDataFormat(resultData.resultData, resultData.columnNames);
									//create the CSVDataSource]
									var dsn = queryService.queryObject.Indicator ? queryService.queryObject.Indicator.title : "";
									WeaveService.addCSVData(formattedResult, dsn, queryService.queryObject);
								}
							}
						}, function(error) {
							queryService.queryObject.properties.queryDone = false;
							queryService.queryObject.properties.queryStatus = "Error running script. See error log for details.";
						});
					} else {
						queryService.queryObject.properties.queryStatus = "Data request did not return any rows";
					}
				}, function(error) {
					queryService.queryObject.properties.queryDone = false;
					queryService.queryObject.properties.queryStatus = "Error Loading data. See error log for details.";
				});
				
			}//validation check
		};
}]);