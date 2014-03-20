analysis_mod.controller("MapCtrl", function($scope, queryService){
	
	queryService.queryObject.MapTool = {
											enabled : "false",
											selected : { 
												id : "",
												title : "",
												keyType : ""
											},
											 enableTitle : false,
											 title : ""
									   };
	
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
		
	$scope.$watch('selected', function() {
		if($scope.selected != undefined && $scope.selected != "") {
			queryService.queryObject.MapTool.selected = angular.fromJson($scope.selected);
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