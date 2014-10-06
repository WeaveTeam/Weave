AnalysisModule.controller('dataFilterCtrl', function($scope, queryService){
	
	$scope.queryService = queryService;
	$scope.filterType;
	
	$scope.add = function () {
		if(queryService.dataObject.filters.length < 3) {
			queryService.dataObject.filters.push({
				title :	"Custom Filter",
				template_url : "aws/analysis/data_filters/generic_filter.html"
			});
		};
	};
	
	$scope.removeFilter = function(index){
		queryService.dataObject.filters.splice(index, 1);
		queryService.queryObject.filters.or.splice(index, 1); // clear both the queryObject and dataObject
	};
	
	$scope.getFilter = function(id) {
		console.log(id);
		runQueryService.queryRequest(dataServiceURL, "getEntitiesById", [[id]], function(entity) {
			console.log(entity[0]);
			if(entity[0].publicMetadata.hasOwnProperty("aws_metadata")) {
				var metadata = angular.fromJson(entity[0].publicMetadata.aws_metadata);
				if(metadata.hasOwnProperty("varType")) {
					$scope.filterType = metadata;
					$scope.$apply();
				}
			}
		});
	};
}); 