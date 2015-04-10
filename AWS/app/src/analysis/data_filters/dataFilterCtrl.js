AnalysisModule.controller('dataFilterCtrl', function($scope, queryService, $filter){
	$scope.queryService = queryService;
	$scope.filtersModel = queryService.queryObject.filters;
	$scope.treeFiltersModel = queryService.queryObject.treeFilters;
	
	$scope.addFilter = function() {
		// the values are the same as the index for convenience
		queryService.queryObject.filterArray.push(queryService.queryObject.filterArray.length);
	};
	
	$scope.removeFilter = function(index) {
		queryService.queryObject.filterArray.splice(index, 1);
		queryService.queryObject.filters.splice(index, 1);
	};

	$scope.addTreeFilter = function() {
		// the values are the same as the index for convenience
		queryService.queryObject.treeFilterArray.push(queryService.queryObject.treeFilterArray.length);
	};
	
	$scope.removeTreeFilter = function(index) {
		queryService.queryObject.treeFilterArray.splice(index, 1);
		queryService.queryObject.treeFilters.splice(index, 1);
	};	
});