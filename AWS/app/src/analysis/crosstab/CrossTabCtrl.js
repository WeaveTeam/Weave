//main analysis controller
AnalysisModule.controller('CrossTabCtrl', function($scope, $filter, queryService, AnalysisService, WeaveService, QueryHandlerService, $window,statisticsService ) {
	
	queryService.getDataTableList(true);
	
	queryService.crossTabQuery = {};
	
	$scope.queryService = queryService;

	
	$scope.getItemId = function(item) {
		return item.id;
	};
	
	$scope.getItemText = function(item) {
		if(queryService.queryObject.properties.displayAsQuestions)
			return item.description || item.title;
		return item.title;
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
});