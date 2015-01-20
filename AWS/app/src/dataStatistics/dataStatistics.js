/**
 * controllers and service for the 'Data Stats' tab and its nested tabs
 */
//TODO create submodules corresponding to every nested tab
//Module definition
var dataStatsModule = angular.module('aws.dataStatistics', []);

//*******************************Value recipes********************************************
//Correlation coefficients
dataStatsModule.value('pearsonCoeff', {label:"Pearson's Coefficent", scriptName : "getCorrelationMatrix.R"});
dataStatsModule.value('spearmanCoeff', {label : "Spearman's Coefficient", scriptName:"getSpearmanCoefficient.R"});

//value recipes to be used in result handling of non-query statistics
//Summary statistics for each numerical data columns
dataStatsModule.value('summaryStatistics', 'SummaryStatistics');

//correlation Matrices computed using different algorithms
dataStatsModule.value('correlationMatrix', 'CorrelationMatrix');

//sparklines data i.e. bins and counts in each bin
dataStatsModule.value('sparklines', 'Sparklines');

//************************SERVICE***********************************************************
dataStatsModule.service('statisticsService', ['$q','$rootScope', 'runQueryService', 'queryService', 'QueryHandlerService','computationServiceURL', 'scriptManagementURL',
                                              'summaryStatistics','correlationMatrix', 'sparklines',
                                              function($q,scope, runQueryService, queryService, QueryHandlerService, computationServiceURL,  scriptManagementURL,
                                              summaryStatistics, correlationMatrix, sparklines ){
	
	
	var that = this;
	
	//getting the list of datatables if they have not been retrieved yet
	if(queryService.cache.dataTableList.length == 0){
		queryService.getDataTableList(true);
		console.log("got new list");
	}
	//cache object that will contain all diff analytic statistics for ONE datatable
	this.cache= {
			statsInputMetadata:[],
			summaryStats : {statsData:[], columnDefinitions:[]},
			correlationMatrix : [],
			sparklineData :{ breaks: [], counts: {}},
			columnTitles:[]//column titles of the columns in current table 
	};
	
	
	/**
	 * common function that runs various statistical tests and scripts and processes results accordingly
	 * @param scriptName name of the script 
	 * @param numercialColumns columns to be used in the script
	 * @param name of the statistic to calculate 
	 */
	this.calculateStats = function(scriptName, numericalColumns, statToCalculate, forceUpdate){
		
		if(!forceUpdate){
			return this.cache.summaryStats;
		}
		var statsInputs = QueryHandlerService.handleScriptOptions(numericalColumns);//will return int[] ids
		if(statsInputs){
			//hack fix this
			statsInputs[0].name = statToCalculate;
			statsInputs[0].type = "DATACOLUMNMATRIX";
			//getting the data
			queryService.getDataFromServer(statsInputs, null).then(function(success){
				
				//executing the stats script
				if(success){
					queryService.runScript(scriptName).then(function(result){
						if(result){
							//handling different kinds of non -query results returned from R
							for(var x = 0; x < statsInputs.length; x++){
								
								switch (statToCalculate)
								{
									case summaryStatistics:
										//that.cache.summaryStats = result;
										that.handleDataStats(result.resultData, that.cache.statsInputMetadata.inputs );
										break;
									case correlationMatrix:
										//that.cache.correlationMatrix = result;
										that.handleCorrelationData(result.resultData);
										break;
									case sparklines:
										that.handleSparklineData(result.resultData);
										break;
								}
									
								
							}//end of loop for statsinputs
						}
					});
				}
			});
		}
	};
	
  	
	/**
	 * convenience function to get column titles
	 * @param column objects 
	 * @returns an array of respective titles
	 */
	this.getColumnTitles = function(columns){
		
		for(var t=0; t < columns.length; t++){
			this.cache.columnTitles[t] = columns[t].title;
		}
		
		//return columnTitles;
	};
	

	/**
	 * gets the metadata for the a script
	 * @param statsScript scriptName
	 */
	this.getStatsMetadata = function(statsScript){
		var deferred = $q.defer();
		runQueryService.queryRequest(scriptManagementURL, 'getScriptMetadata', [statsScript], function(result){
			that.cache.statsInputMetadata = result;
			scope.$safeApply(function() {
				deferred.resolve(that.cache.statsInputMetadata);
			});
		});
		
		return deferred.promise;
	};
	
	/**
	 * this function populates the Summary statistics grid
	 * @param resultData summary statistics of the numerical columns
	 * @param metadata script metadata for the stats script
	 */
	this.handleDataStats = function(resultData, metadata){
		if(resultData){
			var data = [];
			//getting column titles
			this.getColumnTitles(queryService.cache.numericalColumns);
			var columnTitles = this.cache.columnTitles;
			for(var x = 0; x < resultData.length; x++){// x number of numerical columns
				
				var oneStatsGridObject = {};
				for(var y = 0; y < metadata.length; y++){//y number of metadata objects
					
					if(metadata[y].param == 'ColumnName'){//since the dataprovider for this entry is different i.e. columnTitles
						oneStatsGridObject[metadata[y].param] = columnTitles[x];
						continue;
					}
					
					oneStatsGridObject[metadata[y].param] = resultData[x][y-1];
				}
				
				data.push(oneStatsGridObject);
				
				//during the last iteration TODO confirm if this is the right place for the loop
				//console.log(x);
				if(x == (resultData.length - 1)){
					this.cache.summaryStats.columnDefinitions = [];
					for(var z = 0; z < metadata.length; z++){
						//populates the columndefinitions of the grid
						this.cache.summaryStats.columnDefinitions.push({
							field: metadata[z].param,
							displayName : metadata[z].param,
							enableCellEdit:false
						});
					}
					
				}
			}
			
			this.cache.summaryStats.statsData = [];//clear previous entries
			this.cache.summaryStats.statsData = data;//populates the data displayed in the grid
		}
	};
	
	
	/**
	 * processes the sparklineData and prepares for rendering
	 * @param the sparkline data returned from R
	 */
	this.handleSparklineData = function(result){
		var sparklineData= {breaks:[], counts:{}};
		sparklineData.breaks  = result[0][0];//breaks are same for all columns needed only once
		for(var x =0; x < result.length; x++){
			sparklineData.counts[this.cache.columnTitles[x]] = result[x][1];//TODO get rid of hard code
		}
	};
	
	this.handleCorrelationData = function(){
		
	};
	
	
}]);


//********************CONTROLLERS***************************************************************
dataStatsModule.controller('dataStatsCtrl', function($scope,$filter, 
													 queryService, statisticsService,
													 summaryStatistics){
	
	$scope.queryService = queryService;//links it to the analysis datatable
	$scope.statisticsService = statisticsService;
	
	
/*******************************************************datagrid***********************************************/
	$scope.columnDefinitions = [];//populates the stats grid
	$scope.statsData = [];//the array that gets populated by the Column statistics
		
		
	//defines the main grid that displays descriptive column statistics
	$scope.statsGrid = { 
	        data: 'statsData',
	        enableRowSelection: true,
	        enableCellEdit: true,
	        columnDefs: 'columnDefinitions',
	        multiSelect : false
	 };
		
	$scope.$watch(function(){
		return $scope.statisticsService.cache.summaryStats.statsData;
	}, function(){
		if($scope.statisticsService.cache.summaryStats.statsData &&  $scope.queryService.cache.numericalColumns && $scope.statisticsService.cache.statsInputMetadata.inputs){
			$scope.columnDefinitions = $scope.statisticsService.cache.summaryStats.columnDefinitions;
			$scope.statsData = $scope.statisticsService.cache.summaryStats.statsData;
		}
	});
	
	
	
	//select2-sortable handlers
	$scope.getItemId = function(item) {
		return item.id;
	};
	
	$scope.getItemText = function(item) {
		return item.title;
	};
	
	//datatable
	$scope.getDataTable = function(term, done) {
		var values = $scope.queryService.cache.dataTableList;
		done($filter('filter')(values, {title:term}, 'title'));
	};

	//runs when the datatable is changed
	$scope.$watch(function(){
		if ($scope.queryService.queryObject.dataTable)
			return $scope.queryService.queryObject.dataTable.id;
	}, function() {
		if($scope.queryService.queryObject.dataTable.id){
			console.log("Async call made for getting statistics");
			
			$scope.statisticsService.getStatsMetadata("getStatistics.R");
			$scope.queryService.getDataColumnsEntitiesFromId(queryService.queryObject.dataTable.id, true).then(function(){
				$scope.statisticsService.calculateStats("getStatistics.R", queryService.cache.numericalColumns, summaryStatistics, true);
			});
		}
			
	});
	
});
