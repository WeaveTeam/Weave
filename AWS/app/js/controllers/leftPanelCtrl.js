/**
 * Left Panel Module
 * LeftPanelCtrl - Manages the model for the left panel.
 */
angular.module("aws.leftPanel", [])
.controller("LeftPanelCtrl", function($scope, $location){
	$scope.isActive = function(route){
		return route == $location.path();
	};
	
});