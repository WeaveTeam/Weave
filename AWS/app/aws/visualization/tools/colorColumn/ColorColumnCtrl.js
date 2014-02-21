angular.module("aws.visualization.tools.colorColumn", [])
// COLOR CONTROLLER
.controller("ColorColumnCtrl", function($scope, queryService){

	queryService.queryObject.ColorColumn = { 
											 enabled : false,
											 selected : ""
											};

	$scope.options = [];
	
	$scope.$watch(function(){
		return queryService.dataObject.scriptMetadata;
	}, function() {
		if(queryService.dataObject.hasOwnProperty("scriptMetadata")) {
			$scope.options = [];
			if(queryService.dataObject.scriptMetadata.hasOwnProperty("outputs")) {
				var outputs = queryService.dataObject.scriptMetadata.outputs;
				for( var i = 0; i < outputs.length; i++) {
					$scope.options.push(outputs[i].param);
				}
			}
		}
	});
	
		
	/*** double binding *****/
	$scope.$watch('enabled', function() {
		if($scope.enabled != undefined) {
			queryService.queryObject.ColorColumn.enabled = $scope.enabled;
		}
	});
	
	$scope.$watch(function(){
		return queryService.queryObject.ColorColumn.enabled;
	}, function() {
		$scope.enabled = queryService.queryObject.ColorColumn.enabled;
	});

	$scope.$watch('selected', function() {
		if($scope.selected != undefined) {
			queryService.queryObject.ColorColumn.selected = $scope.selected;
		}
		
	});
	
	$scope.$watch(function(){
		return queryService.queryObject.ColorColumn.selected;
	}, function() {
		$scope.selected = queryService.queryObject.ColorColumn.selected;	
	});
	/**************************/
});