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


//************************SERVICE***********************************************************
dataStatsModule.service('statisticsService', ['$q','$rootScope', 'runQueryService', 'queryService', 'QueryHandlerService','computationServiceURL', 'scriptManagementURL',
                                              'summaryStatistics','correlationMatrix',
                                              function($q,scope, runQueryService, queryService, QueryHandlerService, computationServiceURL,  scriptManagementURL,
                                              summaryStatistics, correlationMatrix){
	
	
	var that = this;
	
	//getting the list of datatables if they have not been retrieved yet
	//that is if the person visits this tab directly
	if(queryService.cache.dataTableList.length == 0){
		queryService.getDataTableList(true);
	}
	
	//cache object that will contain all diff analytic statistics for ONE datatable
	this.cache= {
			dataTableSelected : null,
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
		
		//empty the cache of previously calculated stats
		//TODO confirm if better way to do this
//		this.cache.summaryStats.statsData = [];
//		this.cache.summaryStats.columnDefinitions = [];
//		this.cache.correlationMatrix = [];
//		this.cache.columnTitles= [];
//		this.sparklineData.breaks = [];
//		this.sparklineData.counts = {};
		
		
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
										that.handleStatsAndSparklines(result.resultData, that.cache.statsInputMetadata.inputs );
										break;
									case correlationMatrix:
										//that.cache.correlationMatrix = result;
										that.handleCorrelationData(result.resultData);
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
	
	this.handleStatsAndSparklines = function(resultData, metadata){
		var dataForStatsGrid = resultData[0];
		var dataForSparklines = resultData[1];
		
		this.handleDataStats(dataForStatsGrid, metadata);
		this.handleSparklineData(dataForSparklines);
	};
	
	/**
	 * this function populates the Summary statistics grid
	 * @param resultData summary statistics of the numerical columns
	 * @param metadata script metadata for the stats script
	 */
	this.handleDataStats = function(resultData, metadata){
		if(resultData){
			var data = [];
			
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
				
				//during the last iteration
				if(x == (resultData.length - 1)){
					this.cache.summaryStats.columnDefinitions = [];
					for(var z = 0; z < metadata.length; z++){
						//populates the column definitions of the grid
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
	 * processes the sparklineData populates the data provider for the sparkline directives
	 * @param result the sparkline data returned from R
	 */
	this.handleSparklineData = function(result){
		//pre-process the sparklines
		var sparklineData= {breaks:[], counts:{}};
		
		sparklineData.breaks  = result[0][0];//breaks are same for all columns needed only once
		for(var x =0; x < result.length; x++){
			sparklineData.counts[this.cache.columnTitles[x]] = result[x][1];//TODO get rid of hard code
		}
		
		// used as the data provider for drawing the sparkline directives
		this.cache.sparklineData = {};//clear the previous content
		this.cache.sparklineData = sparklineData;
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
	        rowHeight : 70,
	        enableRowSelection: true,
	        enableCellEdit: true,
	        columnDefs: 'columnDefinitions',
	        multiSelect : false
	 };
		
	$scope.$watch(function(){
		return $scope.statisticsService.cache.summaryStats.statsData;
	}, function(){
		
		if($scope.statisticsService.cache.summaryStats.statsData &&  
		   $scope.queryService.cache.numericalColumns && 
		   $scope.statisticsService.cache.statsInputMetadata.inputs){
			
			$scope.columnDefinitions = $scope.statisticsService.cache.summaryStats.columnDefinitions;
			$scope.statsData = $scope.statisticsService.cache.summaryStats.statsData;
		}
	});
	
	$('#singleContainer').on('scroll', function () {
	    $('#datagridDiv').scrollTop($(this).scrollTop());
	});
	
	
	$scope.getStatistics = function(){
		if($scope.statisticsService.cache.dataTableSelected.id)
			{
				console.log("Async call made for getting statistics");
				$scope.statisticsService.getStatsMetadata("getStatistics.R");
				
				$scope.queryService.getDataColumnsEntitiesFromId($scope.statisticsService.cache.dataTableSelected.id, true).then(function(result){
					//getting column titles
					$scope.statisticsService.getColumnTitles($scope.queryService.cache.numericalColumns);
					//call for displaying summary stats once numerical columns are returned
					$scope.statisticsService.calculateStats("getStatistics.R", $scope.queryService.cache.numericalColumns, summaryStatistics, true);
				});
			}
	};
	
});
