analysis_mod.controller("MapCtrl", function($scope, queryService){
	
	if(queryService.queryObject.Indicator.label) {
		$scope.title = "Map of " + queryService.queryObject.scriptSelected.split(".")[0] + " for " +  queryService.queryObject.Indicator.label;
		$scope.enableTitle = true;
	}
	
	queryService.getGeometryDataColumnsEntities();
	$scope.geomTables = [];
	
	$scope.$watch(function() {
		return queryService.dataObject.geometryColumns;
	}, function () {
		if(queryService.dataObject.hasOwnProperty('geometryColumns')){
			var geometryColumns = queryService.dataObject.geometryColumns;
			for (var i = 0; i < geometryColumns.length; i++) {
				$scope.geomTables.push( {
											id : geometryColumns[i].id,
											title : geometryColumns[i].publicMetadata.title,
											keyType : geometryColumns[i].publicMetadata.keyType
				});
			}
		}
	});

	$scope.$watch('enabled', function() {
		if($scope.enabled != undefined) {
			queryService.queryObject.MapTool.enabled = $scope.enabled;
		}
	});
	
	$scope.$watch(function(){
		return queryService.queryObject.MapTool.enabled;
	}, function() {
		$scope.enabled = queryService.queryObject.MapTool.enabled;
	});
		
	$scope.$watch('selected', function(newVal, oldVal) {
		if(newVal != oldVal) {
			if(newVal)  {
				queryService.queryObject.MapTool.selected = angular.fromJson(newVal);
			}
		}
	});
	
	
	$scope.options = [];
	
	$scope.$watch(function(){
		return queryService.dataObject.scriptMetadata;
	}, function() {
		$scope.options = [];
		if(queryService.dataObject.hasOwnProperty("scriptMetadata")) {
			if(queryService.dataObject.scriptMetadata.hasOwnProperty("outputs")) {
				var outputs = queryService.dataObject.scriptMetadata.outputs;
				for( var i = 0; i < outputs.length; i++) {
					$scope.options.push(outputs[i].param);
				}
			}
		}
	});		
	
	$scope.$watch(function(){
		return queryService.queryObject.MapTool.selected;
	}, function() {
		$scope.selected = angular.toJson(queryService.queryObject.MapTool.selected);	
	});
	
	$scope.$watch('title', function() {
		if($scope.title != undefined) {
			queryService.queryObject.MapTool.title = $scope.title;
		}
	});
	
	$scope.$watch('label', function() {
		if($scope.label) {
			queryService.queryObject.MapTool.labelLayer = $scope.label;
		}
	});
	
	$scope.$watch('enableTitle', function() {
		if($scope.enableTitle != undefined) {
			queryService.queryObject.MapTool.enableTitle = $scope.enableTitle;
		}
	});
	
	$scope.$watch(function(){
		return queryService.queryObject.MapTool.title;
	}, function() {
		$scope.title = queryService.queryObject.MapTool.title;
	});
	
	$scope.$watch(function(){
		return queryService.queryObject.MapTool.enableTitle;
	}, function() {
		$scope.enableTitle = queryService.queryObject.MapTool.enableTitle;
	});
});