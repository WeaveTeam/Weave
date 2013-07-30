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

function saveJSON(query) {
	var blob = new Blob([JSON.stringify(query, undefined, 2)], {type: "text/plain;charset=utf-8"});
	saveAs(blob, "Query Object.txt");
}
