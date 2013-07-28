angular.module("aws.IndicatorPanel", [])
.controller("IndicatorPanelCtrl", function($scope, queryobj, dataService){

	$scope.options = ["Values are not", "yet returned", "from the server"];

	var promise = dataService.giveMeColObjs();
	
	//$scope.$watch('promise', function(){
		$scope.options = promise;
	//});
	
	$scope.selection;
	
	$scope.$watch('selection', function(){
		queryobj[$scope.selectorId] = $scope.selection;
	});

})
.controller("AnalysisCtrl", function($scope){
	
})
.controller("CalculationCtrl", function($scope){
	
})
.controller("VisualizationCtrl", function($scope){
	
})