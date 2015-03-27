/**
 * controls the attribute menu visualization tool  widget
 */
var x ;
AnalysisModule.controller("AttributeMenuCtrl", function($scope, WeaveService, $timeout){

	$scope.WeaveService = WeaveService;
	
	$scope.$watch('tool.enabled', function(){
		if($scope.tool.enabled)
			$scope.openTools = WeaveService.listOfTools();
	});
	
	$scope.$watch('tool.selectedVizTool', function(){
		//console.log("tools selected", $scope.tool.selectedVizTool);
		if($scope.tool.selectedVizTool)
			$scope.vizAttributes = WeaveService.getSelectableAttributes($scope.tool.selectedVizTool);
	});
	
	$scope.$watch('tool', function() {
		if($scope.toolId) // this gets triggered twice, the second time toolId with a undefined value.
			WeaveService.AttributeMenuTool($scope.tool, $scope.toolId);
	}, true);
	
	$scope.setAttributes = function(attr){
		console.log("attr", attr);
		
		//check for tha attrbite selected
		//if($scope.tool.vizAttribute" && $scope.tool.selectedVizTool && attr)
			//set the attribute in weave
	};
});