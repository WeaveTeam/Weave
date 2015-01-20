//main analysis controller
AnalysisModule.controller('CrossTabCtrl', function($scope, $filter, queryService, AnalysisService, WeaveService, QueryHandlerService, $window,statisticsService ) {
	
	queryService.getDataTableList(true);
	
	queryService.crossTabQuery = {};
	
	$scope.queryService = queryService;

	$scope.rowInfo = "Select a row variable. Some analysts refer to the row as the dependent variable.";
	$scope.columnInfo = "Select a column variable. Some analysts refer to the column as the independent variable.";
	$scope.controlInfo = "Select additional control variables.";
	$scope.sampleSizeInfo = "Unweighted Sample Size of each subpopulation";
	$scope.rowPercentageInfo = "Percentage of the subpopulation within each Row";
	$scope.columnPercentageInfo = "Percentage of the subpopulation within each Column";
	$scope.chiSquareInfo = "Chi square test results for 2-way tables";
	$scope.weightedSizeInfo = "Weighted Sample Size of each subpopulation";
	$scope.totalPercentage = "Total percentage of the subpopulation within each control";

	$scope.$watch('queryService.crossTabQuery.row', function() {
		
		if(queryService.crossTabQuery.row) {
			queryService.getEntitiesById([queryService.crossTabQuery.row.id], true).then(function (result) {
				if(result.length) {
					var resultMetadata = result[0];
					if(resultMetadata.publicMetadata.hasOwnProperty("aws_metadata")) {
						var metadata = angular.fromJson(resultMetadata.publicMetadata.aws_metadata);
						if(metadata.hasOwnProperty("varValues")) {
							queryService.getDataMapping(metadata.varValues).then(function(result) {
								$scope.rVarValues = result;
							});
						}
					}
				}
			});
		} else {
			// delete description and table if the indicator is cleared
			$scope.rVarValues = [];
		}
	});
	
	
	$scope.$watch('queryService.crossTabQuery.column', function() {
		
		if(queryService.crossTabQuery.column) {
			queryService.getEntitiesById([queryService.crossTabQuery.column.id], true).then(function (result) {
				if(result.length) {
					var resultMetadata = result[0];
					if(resultMetadata.publicMetadata.hasOwnProperty("aws_metadata")) {
						var metadata = angular.fromJson(resultMetadata.publicMetadata.aws_metadata);
						if(metadata.hasOwnProperty("varValues")) {
							queryService.getDataMapping(metadata.varValues).then(function(result) {
								$scope.cVarValues = result;
							});
						}
					}
				}
			});
		} else {
			// delete description and table if the indicator is cleared
			$scope.cVarValues = [];
		}
	});
	$scope.getItemId = function(item) {
		return item.id;
	};
	
	$scope.getItemText = function(item) {
		return item.description || item.title;;
	};
	
	//datatable
	$scope.getDataTable = function(term, done) {
		var values = queryService.cache.dataTableList;
		done($filter('filter')(values, {title:term}, 'title'));
	};
	
	
	$scope.$watch("queryService.queryObject.dataTable.id", function() {
		queryService.getDataColumnsEntitiesFromId(queryService.queryObject.dataTable.id, true);
	});
	
	//Indicator
	 $scope.getIndicators = function(term, done) {
			var columns = queryService.cache.columns;
			done($filter('filter')(columns,{columnType : 'indicator',title:term},'title'));
	};
	
	$scope.runReport = function() {
		var dataRequest = {
				columnIds : [],
				namesToAssign : [],
				filters : null
		};
		if(!queryService.crossTabQuery.row && !queryService.crossTabQuery.row.hasOwnProperty("id"))
		{
			$scope.crossTabStatus = "Row variable required.";
		} else
		{
			$scope.crossTabStatus = "Getting data from Database...";
			dataRequest.columnIds.push(queryService.crossTabQuery.row.id);
			dataRequest.namesToAssign.push("row");

			if(queryService.crossTabQuery.column && queryService.crossTabQuery.column.hasOwnProperty("id"))
			{
				dataRequest.columnIds.push(queryService.crossTabQuery.column.id);
				dataRequest.namesToAssign.push("column");
			}
			
			if(queryService.crossTabQuery.control1 && queryService.crossTabQuery.control1.hasOwnProperty("id"))
			{
				dataRequest.columnIds.push(queryService.crossTabQuery.control1.id);
				dataRequest.namesToAssign.push("control1");
			}
			if(queryService.crossTabQuery.control2 && queryService.crossTabQuery.control2.hasOwnProperty("id"))
			{
				dataRequest.columnIds.push(queryService.crossTabQuery.control2.id);
				dataRequest.namesToAssign.push("control2");
			}
			if(queryService.crossTabQuery.control3 && queryService.crossTabQuery.control3.hasOwnProperty("id"))
			{
				dataRequest.columnIds.push(queryService.crossTabQuery.control3.id);
				dataRequest.namesToAssign.push("control3");
			}
		}
		var scriptInput = [
				{
					type : "filteredRows",
					value : dataRequest
				},
				{
					name : "sampleSize",
					type : "boolean",
					value : !!queryService.crossTabQuery.sampleSize // !! converts to boolean
				},
				{
					name : "chiSquare",
					type : "boolean",
					value : !!queryService.crossTabQuery.chiSquare
				},
				{
					name : "rowPercentage",
					type : "boolean",
					value : !!queryService.crossTabQuery.rowPercentage
				},
				{
					name : "columnPercentage",
					type : "boolean",
					value : !!queryService.crossTabQuery.columnPercentage
						 
				},
				{
					name : "totalPercentage",
					type : "boolean",
					value : !!queryService.crossTabQuery.totalPercentage
				},
				{
					name : "weightedSize",
					type : "boolean",
					value : !!queryService.crossTabQuery.weightedSize
				}
		];
		queryService.getDataFromServer(scriptInput, null).then(function(result) {
			console.log(result);
		});
	};
});