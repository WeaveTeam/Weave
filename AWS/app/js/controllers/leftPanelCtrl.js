/**
 * Left Panel Module
 * LeftPanelCtrl - Manages the model for the left panel.
 */
angular.module("aws.leftPanel", [])
.controller("LeftPanelCtrl", function($scope, queryobj){
	$scope.oneAtATime = true; // for accordion settings
	
	/*$scope.QueryObjectModel = JSON.stringify(queryobj, undefined, 2);
	$scope.$watch('queryobj', function(){
		$scope.QueryObjectModel = JSON.stringify(queryobj, undefined, 2); 
	}, true);*/
	
});