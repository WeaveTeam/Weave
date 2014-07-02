analysis_mod.controller('byVariableCtrl', function($scope, queryService){
	
	$scope.service = queryService;
	
	queryService.dataObject.byVariableItems = [0];
	queryService.dataObject.byVariableFilters = [0];
	queryService.dataObject.filterType = [];
	queryService.dataObject.filterOptions = [];
	
	$scope.addByVariable = function() {
		queryService.dataObject.byVariableItems.push(queryService.dataObject.byVariableItems.length + 1);
		queryService.dataObject.byVariableFilters.push(queryService.dataObject.byVariableItems.length + 1);
	};
	
	$scope.removeByVariable = function(index) {
		if(queryService.dataObject.byVariableItems.length == 1) {
			queryService.dataObject.byVariableItems[0] = 0;
			queryService.dataObject.byVariableFilters[0] = 0;
			
			queryService.queryObject.ByVariableColumns[0] = "";
			queryService.queryObject.ByVariableFilters[0] = [];
		} else {
			queryService.dataObject.byVariableItems.splice(index, 1);
			queryService.dataObject.byVariableFilters.splice(index, 1);

			queryService.queryObject.ByVariableFilters.splice(index, 1);
			queryService.queryObject.ByVariableColumns.splice(index, 1);
		}
	};
	
	$scope.getFilterType = function(columnStr, index) {
		
		var column;
		if(columnStr) {
			column = angular.fromJson(columnStr);
			if(column.hasOwnProperty("id")) {
				aws.DataClient.getDataColumnEntities([column.id], function(entities) {
					entity = entities[0];
					if(entity.publicMetadata.hasOwnProperty('aws_metadata')) {
						aws_metadata = angular.fromJson(entity.publicMetadata.aws_metadata);
						if(aws_metadata.hasOwnProperty("varType")) {
							if(aws_metadata.varType == "continuous") {
								queryService.dataObject.filterType[index] = aws_metadata.varType;
								console.log(aws_metadata.varRange[1]);
								queryService.dataObject.filterOptions[index] = { 
																				range : true, 
																				min : aws_metadata.varRange[0], 
																				max : aws_metadata.varRange[1],
																				values : [(aws_metadata.varRange[1] - aws_metadata.varRange[0]) / 3, 2 * (aws_metadata.varRange[1] - aws_metadata.varRange[0]) / 3]};
							} else if(aws_metadata.varType == "categorical") {
								queryService.dataObject.filterType[index] = aws_metadata.varType;
								queryService.dataObject.filterOptions[index] = aws_metadata.varValues;
							}
						}
						$scope.$apply();
					}
				});
			}
		}
	};
	
}); 