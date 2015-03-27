//main analysis controller
AnalysisModule.controller('CrossTabCtrl', function($scope, $filter, queryService, AnalysisService, WeaveService, QueryHandlerService, $window) {
	
	queryService.getDataTableList(true);
	
	
	$scope.$watch("queryService.queryObject.dataTable.id", function() {
		if($scope.queryService.queryObject.dataTable)
			queryService.getDataColumnsEntitiesFromId(queryService.queryObject.dataTable.id, true);
	});
	
	queryService.crossTabQuery = {
			filters : [{},{}]
	};

	$scope.queryService = queryService;
	$scope.firstFilterMetadata = {};
	$scope.secondFilterMetadata = {};
	
	$scope.rowInfo = "Select a row variable. Some analysts refer to the row as the dependent variable.";
	$scope.columnInfo = "Select a column variable. Some analysts refer to the column as the independent variable.";
	$scope.controlInfo = "Select additional control variables.";
	$scope.sampleSizeInfo = "Unweighted Sample Size of each subpopulation";
	$scope.rowPercentageInfo = "Percentage of the subpopulation within each Row";
	$scope.columnPercentageInfo = "Percentage of the subpopulation within each Column";
	$scope.chiSquareInfo = "Chi square test results for 2-way tables";
	$scope.weightedSizeInfo = "Weighted Sample Size of each subpopulation";
	$scope.totalPercentage = "Total percentage of the subpopulation within each control";

	$scope.$watch('queryService.queryObject.dataTable', function() {
		// check if dataTable has been cleared
		
	});
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
	
	
	$scope.$watch('queryService.crossTabQuery.filters[0].column', function() {
		
		if(queryService.crossTabQuery.filters[0].column && queryService.crossTabQuery.filters[0].column.id) {
			queryService.getEntitiesById([queryService.crossTabQuery.filters[0].column.id], true).then(function (result) {
				if(result.length) {
					var resultMetadata = result[0];
					if(resultMetadata.publicMetadata.hasOwnProperty("aws_metadata")) {
						var metadata = angular.fromJson(resultMetadata.publicMetadata.aws_metadata);
						if(metadata.hasOwnProperty("varValues")) {
							queryService.getDataMapping(metadata.varValues).then(function(result) {
								$scope.firstFilterMetadata = result;
							});
						}
					}
				}
			});
		} else {
			// delete metadata if filter column is cleared
			$scope.firstFilterMetadata = [];
		}
	});
	
	$scope.$watch('queryService.crossTabQuery.filters[1].column', function() {
		
		if(queryService.crossTabQuery.filters[1].column && queryService.crossTabQuery.filters[1].column.id) {
			queryService.getEntitiesById([queryService.crossTabQuery.filters[1].column.id], true).then(function (result) {
				if(result.length) {
					var resultMetadata = result[0];
					if(resultMetadata.publicMetadata.hasOwnProperty("aws_metadata")) {
						var metadata = angular.fromJson(resultMetadata.publicMetadata.aws_metadata);
						if(metadata.hasOwnProperty("varValues")) {
							queryService.getDataMapping(metadata.varValues).then(function(result) {
								$scope.secondFilterMetadata = result;
							});
						}
					}
				}
			});
		} else {
			// delete metadata if filter column is cleared
			$scope.secondFilterMetadata = [];
		}
	});
	
	$scope.runReport = function() {
		var dataRequest = {
				columnIds : [],
				namesToAssign : [],
				filters : null
		};
		var scriptInput = [];
		var filters = {and : []};

		
		if(queryService.crossTabQuery.filters[0] && queryService.crossTabQuery.filters[0].column && queryService.crossTabQuery.filters[0].option)
			filters.and.push({
				cond : {
					f : queryService.crossTabQuery.filters[0].column.id,
					v : [queryService.crossTabQuery.filters[0].option.value]
				}
			});
		
		if(queryService.crossTabQuery.filters[1] && queryService.crossTabQuery.filters[1].column
				&& queryService.crossTabQuery.filters[1].option)
			filters.and.push({
				cond : {
					f : queryService.crossTabQuery.filters[1].column.id,
					v : [queryService.crossTabQuery.filters[1].option.value]
				}
			});
		
		if(!queryService.crossTabQuery.row && !queryService.crossTabQuery.row.hasOwnProperty("id"))
		{
			$scope.crossTabStatus = "Row variable required.";
		} else
		{
			$scope.crossTabStatus = "Loading data from database...";
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
			
			if(filters.and.length)
				dataRequest.filters = filters;
			
			
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
		
		queryService.getDataFromServer(scriptInput).then(function(result) {
			$scope.crossTabStatus = "Running script...";

			queryService.runScript("Cross Tabulation.R").then(function(result)
			{
				var formattedResult = WeaveService.createCSVDataFormat(result.resultData, result.columnNames);
				$scope.crossTabStatus = "Done.";
				queryService.crossTabQuery.result = formattedResult;
			});
		});
	};
});