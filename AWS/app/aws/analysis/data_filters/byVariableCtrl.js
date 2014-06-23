analysis_mod.controller('byVariableCtrl', function($scope, queryService){
	
	queryService.queryObject.ByVariableFilter = [];
	$scope.byVariableColumns = [];
	$scope.byVariableSelection = [];
	$scope.filterType = [];
	$scope.filterValues = [];
	$scope.filterOptions = [];
	$scope.items = [1];
	var lastIndex = 1;

	$scope.$watch(function() {
		return queryService.dataObject.columns;
	}, function() {
		if(queryService.dataObject.columns != undefined) {
			$scope.byVariableColumns = $.map(queryService.dataObject.columns, function(column) {
					var aws_metadata = angular.fromJson(column.publicMetadata.aws_metadata);
					if(aws_metadata != undefined){
						if(aws_metadata.hasOwnProperty("columnType")) {
							if(aws_metadata.columnType == "by-variable" || "indicator") {
								return { id : column.id , title : column.publicMetadata.title};
							} else {
								// skip
							}
						}
					}
			});
		};
	});
	
	$scope.$watchCollection('byVariableSelection', function(newValue, oldValue) {
	    // loop over the selections
		for(var i in $scope.byVariableSelection) {
			if($scope.byVariableSelection[i] != "") {
				var column = angular.fromJson($scope.byVariableSelection[i]);
				var metadata;
				// find the original column this came from using the id
				for(var j in queryService.dataObject.columns) {
					if(column.id == queryService.dataObject.columns[j].id){
						if( queryService.dataObject.columns[j].publicMetadata.hasOwnProperty("aws_metadata") ) {
							metadata = angular.fromJson(queryService.dataObject.columns[j].publicMetadata.aws_metadata);
							break;// break once we find match
						}
					}
				}
				
				queryService.queryObject.ByVariableFilter[i] = { 
																	column : column
															   }
				if(metadata) {
					if(metadata.hasOwnProperty("varType") && metadata.hasOwnProperty("varValues")) {
						$scope.filterType[i] = metadata.varType;
						$scope.filterOptions[i] = metadata.varValues;
					} else {
						$scope.filterType[i] = "";
						$scope.filterOptions[i] = [];
						$scope.filterValues[i] = "";
					}
				} else {
					$scope.filterType[i] = "";
					$scope.filterOptions[i] = [];
					$scope.filterValues[i] = "";
				}
			} else {
				queryService.queryObject.ByVariableFilter[i] = {};
			}
		}
	});
	
	$scope.$watchCollection('filterValues', function () {
		for(var i in $scope.filterValues){
			if ($scope.filterValues[i] != undefined && $scope.filterValues[i] != []) {

				var temp = $.map($scope.filterValues[i], function(item) {
					return angular.fromJson(item);
				});

				if ($scope.filterType[i] == "categorical") {
					queryService.queryObject.ByVariableFilter[i].filters = temp;
				} else if ($scope.filterType[i] == "continuous") {// continuous, we want arrays of ranges
					queryService.queryObject.ByVariableFilter[i].filters = [temp];
				}
			}
		}
	});
	
	$scope.$watchCollection(function() {
		return queryService.queryObject.ByVariableFilter;
	}, function () {
		// fill out the UI based on the queryObject info.
	});

	$scope.addByVariable = function() {
		lastIndex++;
		$scope.items.push(lastIndex);
	};
	
	$scope.removeByVariable = function(index) {
		if($scope.items.length != 1) {
			$scope.items.splice(index, 1);
			$scope.byVariableSelection.splice(index, 1);
			$scope.filterValues[index] = "";
			queryService.queryObject.ByVariableFilter.splice(index, 1);
		} else {
			$scope.byVariableSelection[index] = "";
			$scope.filterValues[index] = "";
			$scope.filterType[index] = "";
			queryService.queryObject.ByVariableFilter = [];
		}
	};
	
});