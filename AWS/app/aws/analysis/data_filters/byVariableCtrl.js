analysis_mod.controller('byVariableCtrl', function($scope, queryService){
	
	$scope.service = queryService;
	$scope.items = [1];
	var lastIndex = 1;

	$scope.$watchCollection(function() {
		return queryService.queryObject.ByVariableFilter;
	}, function(newValue, oldValue) {
	    // loop over the selections
		var ByVariableFilter = queryService.queryObject.ByVariableFilter;
		
		if(ByVariableFilter) {
			for(var i in ByVariableFilter) {
				var column = angular.fromJson(ByVariableFilterColumns[i]);
				aws.DataClient.getDataColumnEntities([column.id], function(entities) {
					var entity = entities[0];
					if(entity.publicMetadata.hasOwnProperty("aws_metadata")) {
						var metadata = angular.fromJson(entity.publicMetadata.aws_metadata);
						if(metadata) {
							if(metadata.hasOwnProperty("varType") && metadata.hasOwnProperty("varValues")) {
								queryService.dataObject.filterType[i] = metadata.varType;
								queryService.dataObject.filterOptions[i] = metadata.varValues;
							} else {
								queryService.dataObject.filterType[i] = "";
								queryService.dataObject.filterOptions[i] = [];
								queryService.queryObject.filterValues[i] = "";
							}
						}
					}
				});
			}
		}
	});
	
	$scope.addByVariable = function() {
		lastIndex++;
		$scope.items.push(lastIndex);
	};
	
	$scope.removeByVariable = function(index) {
		if($scope.items.length != 1) {
			$scope.items.splice(index, 1);
			queryService.queryObject.ByVariableFilterColumns.splice(index, 1);
			queryService.queryObject.filterValues[index] = "";
		} else {
			queryService.queryObject.filterValues[index] = "";
			$scope.filterType[index] = "";
		}
	};
	
});