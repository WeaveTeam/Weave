AnalysisModule.controller("ScatterPlotCtrl", function($scope, queryService) {

	console.log(queryService);
	$scope.service = queryService;
});