IndicModule = angular.module('aws.analysis.indicator', []); 
IndicModule.controller('IndicatorControl', function($scope, queryService){
	
	queryService.queryObject.Indicator = {
			id : "",
			label : ""
	};
	
	$scope.$watch(function() {
		return 	queryService.dataObject.columns;
	}, function() {

		var indicColumns = [];
		
		if(queryService.dataObject.columns && queryService.dataObject.columns.length) {
			for(var i = 0; i  < queryService.dataObject.columns.length; i++) {
			
				if (queryService.dataObject.columns[i].publicMetadata.hasOwnProperty("aws_metadata")) {
					var column = queryService.dataObject.columns[i];
					var metadata = angular.fromJson(column.publicMetadata.aws_metadata);
				}
				
				if(metadata.hasOwnProperty("columnType")) {
					if(metadata.columnType == "indicator") {
						indicColumns.push({id : column.id, label : column.publicMetadata.title});
					}
				}
			}
		}
		$scope.indicOptions = indicColumns;
	});
	
	$scope.$watch('indicSelection', function() {
		if($scope.indicSelection != undefined) {
			if($scope.indicSelection != "") {
				queryService.queryObject.Indicator = angular.fromJson($scope.indicSelection);
				for(var i = 0; i  < queryService.dataObject.columns.length; i++) {		
					var column = queryService.dataObject.columns[i];
					if(column.id == angular.fromJson($scope.indicSelection).id) {
						$scope.indicatorDescription = angular.fromJson(column.publicMetadata.aws_metadata).description || "No descriptiton available.";
						$scope.varValues = angular.fromJson(column.publicMetadata.aws_metadata).varValues;
						break;
					}
				}
			} else {
				queryService.queryObject.Indicator = { id : "", label : ""};
				$scope.indicatorDescription = "";
				$scope.varValues = {};
			}
		}
	});
	
	$scope.$watch(function() {
		return queryService.queryObject.Indicator;
	}, function() {
		if(queryService.queryObject.Indicator.id != "" && queryService.queryObject.Indicator.label != "") {
			$scope.indicSelection = angular.toJson(queryService.queryObject.Indicator);
		}
	});
});