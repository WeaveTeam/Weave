/**
 *  Individual Panel Type Controllers
 *  These controllers will be specified via the panel directive
 */
angular.module("aws.panelControllers", [])
.controller("SelectColumnPanelCtrl", function($scope, queryobj, dataService){
	$scope.options = ["Values are not", "yet returned", "from the server"];

	var promise = dataService.giveMeColObjs('byvar');
	
	//$scope.$watch('promise', function(){
		$scope.options = promise;
	//});
	
	$scope.selection;
	
	$scope.$watch('selection', function(){
		queryobj[$scope.selectorId] = $scope.selection;
	});

})
.controller("SelectScriptPanelCtrl", function($scope, queryobj, dataService){
	
})
.controller("WeaveVisSelectorPanelCtrl", function($scope, queryobj, dataService){
	
})
.controller("RunPanelCtrl", function($scope, queryobj, dataService){
	$scope.underdog = 0;
	console.log("reading the RunPanelCtrl");
	$scope.clicked = function(){
		alert("clicked");
	}
})
.controller("GenericPanelCtrl", function($scope){
	
})

/*.controller("CategoryFilterPanelCrtl", function($scope, queryobj, dataService){
	
})
.controller("ContinuousFilterPanelCtrl", function($scope, queryobj, dataService){
	
})*/
/*.controller("ScriptOptionsPanelCtrl", function($scope, queryobj, dataService){
	
})*/