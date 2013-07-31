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
.controller("AnalysisCtrl", function($scope, queryobj, dataService){
	$scope.refreshButton = "btn-primary";
	
	$scope.refreshColumns = function(scope, id){
//		if(!id){
//			id = queryobj.conn.dataTable;
//		}
//		// get the promise of future values
//		scope.options = dataService.giveMeColObjs(scope, id);
		$scope.$broadcast("refreshColumns");
		$scope.refreshButton= "btn-primary";
	};
	
	$scope.$watch(function(){
		return queryobj.conn['dataTable'];
	},
		function(newVal, oldVal){
			if(newVal != oldVal){
				$scope.refreshButton="btn-danger";
				//console.log("danger button");
			}
	});
	
})
.controller("CalculationCtrl", function($scope){
	
})
.controller("VisualizationCtrl", function($scope){
	
})