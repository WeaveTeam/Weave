angular.module("aws.IndicatorPanel", [])
.controller("IndicatorPanelCtrl", function($scope, queryobj, Data){
	// Need to add code that goes to get the options from the server. 

	var getPromise = Data.getColNamesFromDb("indicator", $scope);
	var answer = ["one", "two", "three"];
	$scope.options = getPromise;

	//$scope.options = answer;
	$scope.selection;
	
	$scope.$watch('selection', function(){
		queryobj[$scope.panelTitle] = $scope.selection;
	});

})
