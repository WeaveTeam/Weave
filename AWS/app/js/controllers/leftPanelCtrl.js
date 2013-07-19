/**
 * Left Panel Module
 * LeftPanelCtrl - Manages the model for the left panel.
 */
angular.module("aws.leftPanel", [])
.controller("LeftPanelCtrl", function($scope){
	$scope.oneAtATime = true;

	 // = probably passed in as a var.


	$scope.addItem = function() {
		var cont = "content";

	};
})


/** Kludge for the Demo */
/*function LeftPanelsCtrl($scope) {
	
	$scope.panels = [
		{
			panelTitle: "Analysis Builder",
			content: "Summary of selected parameters",
			id: 1
		},
		{
			panelTitle: "Calculation",
			content: "Summary of selected calculation script",
			id: 2
		},
		{
			panelTitle: "Weave",
			content: "Summary of visualization parameters",
			id: 3
		}
	];

	$scope.addContent = function(elem){
		$("#" + elem.id + "-panel").find(".portlet-content").html(elem.content);
	};
}*/