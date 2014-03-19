analysis_mod.controller('byVariableCtrl', function($scope, queryService){
	
	$scope.byVariableColumns = [];
	$scope.byVariableSelection = [];
	$scope.items = [1];
	lastIndex = 1;

	$scope.$watch(function() {
		return queryService.dataObject.columns;
	}, function() {
		if(queryService.dataObject.columns != undefined) {
			$scope.byVariableColumns = $.map(queryService.dataObject.columns, function(column) {
					var aws_metadata = angular.fromJson(column.publicMetadata.aws_metadata);
					if(aws_metadata != undefined){
						if(aws_metadata.hasOwnProperty("columnType")) {
							if(aws_metadata.columnType == "by-variable" || "indicator") {
								return { id : column.id , title : column.publicMetadata.title};
							} else {
								// skip
							}
						}
					}
				});
		};
	});
	
	$scope.$watchCollection('byVariableSelection', function() {
		// loop over the selections
		for(var i in $scope.byVariableSelection) {
			var column = angular.fromJson($scope.byVariableSelection[i]);
			console.log(column);
			var metadata;
			// find the original column this came from using the id
			for(var j in queryService.dataObject.columns) {
				if(column.id == queryService.dataObject.columns[j]){
					if( queryService.dataObject.columns[j].publicMetadata.hasOwnProperty("aws_metadata") ) {
						metadata = angular.fromJson(queryService.dataObject.aws_metadata);
						break;// break once we find match
					}
				}
			}
			
			if(metadata) {
				if(metadata.hasOwnProperty("varType") && metadata.hasOwnProperty("varValues")) {
					$scope.filterType = metadata.varType;
					$scope.filterValues[i] = metadata.varValues;
				}
			}
		}
	});
	
	$scope.addByVariable = function() {
		$scope.items.push(lastIndex + 1);
	}
	
	$scope.removeByVariable = function(index) {
		$scope.items.splice(index, 1);
		$scope.byVariableSelection.splice(index, 1);
	};
	
});