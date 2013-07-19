angular.module("aws.IndicatorPanel", [])
.controller("IndicatorPanelCtrl", function($scope){
	// Need to add code that goes to get the options from the server. 
	
	$scope.options = ["one", "two", "three"]; // = $scope.getIndicatorsFromDb()
	$scope.selection;
	
	$scope.$watch('selection', function(){
		$scope.QueryObjectModel['indicatorSelections'] = $scope.selection;
	});
	
	$scope.getIndicatorsFromDb = function(){
		// aws.DataClient.getIndicators()??
	};
	
	
})