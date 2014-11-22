AnalysisModule.controller('byVariableCtrl', function($scope, queryService){
	
	$scope.service = queryService;
	
	queryService.cache.byVariableItems = [0];
	queryService.cache.byVariableFilters = [0];
	queryService.cache.filterType = [];
	queryService.cache.filterOptions = [];
	
	$scope.addByVariable = function() {
		queryService.cache.byVariableItems.push(queryService.cache.byVariableItems.length + 1);
		queryService.cache.byVariableFilters.push(queryService.cache.byVariableItems.length + 1);
	};
	
	$scope.removeByVariable = function(index) {
		if(queryService.cache.byVariableItems.length == 1) {
			queryService.cache.byVariableItems[0] = 0;
			queryService.cache.byVariableFilters[0] = 0;
			
			queryService.queryObject.ByVariableColumns[0] = "";
			queryService.queryObject.ByVariableFilters[0] = [];
		} else {
			queryService.cache.byVariableItems.splice(index, 1);
			queryService.cache.byVariableFilters.splice(index, 1);

			queryService.queryObject.ByVariableFilters.splice(index, 1);
			queryService.queryObject.ByVariableColumns.splice(index, 1);
		}
	};
	
	$scope.getFilterType = function(columnStr, index) {
		
		var column;
		if(columnStr) {
			column = angular.fromJson(columnStr);
			if(column.hasOwnProperty("id")) {
				queryService.getEntitiesById([column.id], true).then(function(entities) {
					entity = entities[0];
					if(entity.publicMetadata.hasOwnProperty('aws_metadata')) {
						aws_metadata = angular.fromJson(entity.publicMetadata.aws_metadata);
						if(aws_metadata.hasOwnProperty("varType")) {
							if(aws_metadata.varType == "continuous") {
								queryService.cache.filterType[index] = aws_metadata.varType;
								queryService.cache.filterOptions[index] = { 
																				range : true, 
																				min : aws_metadata.varRange[0], 
																				max : aws_metadata.varRange[1],
																				values : [(aws_metadata.varRange[1] - aws_metadata.varRange[0]) / 3, 2 * (aws_metadata.varRange[1] - aws_metadata.varRange[0]) / 3]};
							} else if(aws_metadata.varType == "categorical") {
								queryService.cache.filterType[index] = aws_metadata.varType;
								queryService.getDataMapping(aws_metadata.varValues).then(function(result) {
									queryService.cache.filterOptions[index] = result;
								});
							}
						}
					}
				});
			}
		}
	};
	
}); 