analysis_mod.controller('byVariableCtrl', function($scope, queryService){
	
	$scope.byVariableOptions = [];
	$scope.byVariableSelections = [];
	
	$scope.$watch(function() {
		return queryService.dataObject.columns;
	}, function() {
		if(queryService.dataObject.columns != undefined) {

			$scope.yearDBOptions = $.map(queryService.dataObject.columns, function(column) {
					var aws_metadata = angular.fromJson(column.publicMetadata.aws_metadata);
					if(aws_metadata != undefined){
						if(aws_metadata.hasOwnProperty("columnType")) {
							if(aws_metadata.columnType == "by-variable") {
								return { id : column.id , title : column.publicMetadata.title};
							} else {
								// skip
							}
						}
					}
				});
			$scope.monthDBOptions = $scope.yearDBOptions;
		};
	});
	
});