AnalysisModule.controller('dataFilterCtrl', function($scope, queryService){
	
	$scope.queryService = queryService;
	$scope.filterType;
	
	$scope.uiFilterOptions = ["combo box", "slider", "multi select"];
	
	$scope.$watchCollection('queryService.queryObject.filters', function() {
		console.log($scope.$index); 
	});
	
	// this makes the panel draggable upon initialization
	// there might be a better way to do this
	$scope.$watchCollection(function() {
		return $(".draggable_filter");
	}, function() {
		 $(".draggable_filter" ).draggable();
	});
	
	$scope.add = function () {
		queryService.queryObject.filters.push({
			title :	"Generic Filter",
			template_url : "src/analysis/data_filters/generic_filter.html"
		});
	};
	
	$scope.removeFilter = function(index){
	};
	
	$scope.removeSecond = function(index) {
	};
	
	$scope.initialize = function() {
		 $('#generic_filter').draggable().resizable();
		 console.log("we get here: ", $('#generic_filter'));
	};
	
	$scope.updateFilterView = function(index) {
		
		var column1 = queryService.queryObject.filters.or[index].columns[0];
		var column2 = queryService.queryObject.filters.or[index].columns[1];
		var dynatreeData;
		var entity1;
		var entity2;
		var metadata1;
		var metadata2;
		
		if(column1) {
			aws.queryService(dataServiceURL, "getEntitiesById", [[angular.fromJson(column1).id]], function(entity) {
				entity1 = entity[0];
				if(entity1.publicMetadata.hasOwnProperty("aws_metadata")) {
					metadata1 = angular.fromJson(entity1.publicMetadata.aws_metadata);
					if(metadata1.hasOwnProperty("varType")) {
						queryService.cache.filters[index].filter1.type = metadata1.varType;
					}
					console.log("metadata1", metadata1);
					$scope.$apply();
					//}
				}
			});
			if(column2) {
				aws.queryService(dataServiceURL, "getEntitiesById", [[angular.fromJson(column2).id]], function(entity) {
					entity2 = entity[0];
					if(entity2.publicMetadata.hasOwnProperty("aws_metadata")) {
						metadata2 = angular.fromJson(entity2.publicMetadata.aws_metadata);
						if(metadata2.hasOwnProperty("varType")) {
							queryService.cache.filters[index].filter2.type = metadata2.varType;
						}
						console.log("metadata2", metadata2);
						$scope.$apply();
						//}
					}
				});
				// 2 level tree
			} else {
				// 1 level tree
			}
		} else {
			// no tree, reset dynatree
		}
	
	};
}); 