/**
 * controls the attribute menu visualization tool  widget
 */
AnalysisModule.controller("AttributeMenuCtrl", function($scope, WeaveService, $timeout){

	$scope.WeaveService = WeaveService;

//	$scope.$watch('tool.enabled', function(){
//		if($scope.tool.enabled)
//			$scope.openTools = WeaveService.listOfTools();
//	});
	
	$scope.$watch('tool.selectedVizTool', function(){
		//console.log("tools selected", $scope.tool.selectedVizTool);
		if($scope.tool.selectedVizTool){
			$scope.vizAttributeColl = [];
			$scope.vizAttributeColl = WeaveService.getSelectableAttributes($scope.tool.title, $scope.tool.selectedVizTool);
		}
	});
	
	$scope.$watch('tool', function() {
		if($scope.toolId) // this gets triggered twice, the second time toolId with a undefined value.
			WeaveService.AttributeMenuTool($scope.tool, $scope.toolId);
	}, true);
	
	$scope.setAttributes = function(attr){
		if(attr)
			$scope.tool.chosenAttribute = attr;
		//check for tha attrbite selected
		if($scope.tool.vizAttribute && $scope.tool.selectedVizTool && $scope.tool.chosenAttribute)
			//set the attribute in weave
			WeaveService.setVizAttribute($scope.tool.title,
										  $scope.tool.selectedVizTool,
										  $scope.tool.vizAttribute,
										  $scope.tool.chosenAttribute);
	};
});