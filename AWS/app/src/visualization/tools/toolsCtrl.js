AnalysisModule.controller("toolsCtrl", function($scope, queryService, WeaveService, AnalysisService){
	
	$scope.queryService = queryService;
	$scope.WeaveService = WeaveService;
	$scope.AnalysisService = AnalysisService;
	
	$scope.removeTool = function(index) {
		WeaveService.weave.path(queryService.queryObject.weaveToolsList[index].id).remove();
		delete queryService.queryObject[queryService.queryObject.weaveToolsList[index].id];
		queryService.queryObject.weaveToolsList.splice(index, 1);
	};

//	$scope.getItemId = function(item) {
//		return item.id;
//	};
//	
//	$scope.getItemText = function(item) {
//		return item.title;
//	};
	
	//datatable
	$scope.resultColumns = function(term, done) {
		var values = WeaveService.resultSet;
		done($filter('filter')(values, {name:term}, 'name'));
	};
});