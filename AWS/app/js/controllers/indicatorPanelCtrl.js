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
.controller("AnalysisCtrl", function($scope, queryobj, dataService, $timeout){
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
	$timeout(function(){
		$scope.$watch(function(){
			var t = queryobj.conn['dataTable'];
			console.log(t);
			if(!t){
				console.log(this);
			}
			return t;
		},
			function(newVal, oldVal){
				if(newVal != oldVal){
					$scope.refreshButton="btn-danger";
					console.log("danger button");
				}
		});
	},0);
})
.controller("CalculationCtrl", function($scope){
	
})
.controller("VisualizationCtrl", function($scope){
	
})