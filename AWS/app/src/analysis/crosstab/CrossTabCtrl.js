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
		var scriptInput = [];
		if(!queryService.crossTabQuery.row && !queryService.crossTabQuery.row.hasOwnProperty("id"))
		{
			$scope.crossTabStatus = "Row variable required.";
		} else
		{
			$scope.crossTabStatus = "Getting data from Database...";
			dataRequest.columnIds.push(queryService.crossTabQuery.row.id);
			dataRequest.namesToAssign.push("rw");

			if(queryService.crossTabQuery.column && queryService.crossTabQuery.column.hasOwnProperty("id"))
			{
				dataRequest.columnIds.push(queryService.crossTabQuery.column.id);
				dataRequest.namesToAssign.push("column");
			} else {
				// column wasn't specified
				scriptInput.push({
					name : "column",
					type : "value",
					value : null
				});
			}
			
			if(queryService.crossTabQuery.control1 && queryService.crossTabQuery.control1.hasOwnProperty("id"))
			{
				dataRequest.columnIds.push(queryService.crossTabQuery.control1.id);
				dataRequest.namesToAssign.push("control1");
			} else {
				scriptInput.push({
					name : "control1",
					type : "value",
					value : null
				});
			}
			if(queryService.crossTabQuery.control2 && queryService.crossTabQuery.control2.hasOwnProperty("id"))
			{
				dataRequest.columnIds.push(queryService.crossTabQuery.control2.id);
				dataRequest.namesToAssign.push("control2");
			} else {
				scriptInput.push({
					name : "control2",
					type : "value",
					value : null
				});
			}
		}
		scriptInput.push(
				{
					type : "filteredRows",
					value : dataRequest
				});
		scriptInput.push({
					name : "sampleSize",
					type : "boolean",
					value : !!queryService.crossTabQuery.sampleSize // !! converts to boolean
				});
		scriptInput.push({
					name : "chiSquare",
					type : "boolean",
					value : !!queryService.crossTabQuery.chiSquare
				});
		scriptInput.push({
					name : "rowPercentage",
					type : "boolean",
					value : !!queryService.crossTabQuery.rowPercentage
				});
		scriptInput.push({
					name : "columnPercentage",
					type : "boolean",
					value : !!queryService.crossTabQuery.columnPercentage
						 
				});
		scriptInput.push({
					name : "totalPercentage",
					type : "boolean",
					value : !!queryService.crossTabQuery.totalPercentage
				});
		scriptInput.push({
					name : "weightedSize",
					type : "boolean",
					value : !!queryService.crossTabQuery.weightedSize
				});
		
		queryService.getDataFromServer(scriptInput, null).then(function(result) {
			queryService.runScript("Cross Tabulation.R").then(function(result)
			{
				console.log(result);
			});
		});
	};
});