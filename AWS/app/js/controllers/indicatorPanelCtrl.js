angular.module("aws.IndicatorPanel", [])
.controller("IndicatorPanelCtrl", function($scope, queryobj, Data){

	$scope.options = ["Values are not", "yet returned", "from the server"];

	var promise = Data.getColNamesFromDb("indicator", $scope);
	
	//$scope.$watch('promise', function(){
		$scope.options = promise;
	//});
	
	$scope.selection;
	
	$scope.$watch('selection', function(){
		queryobj[$scope.selectorId] = $scope.selection;
	});

})
