AnalysisModule.controller('dataFilterCtrl', function($scope, queryService){
	
	$scope.queryService = queryService;
	$scope.filterType;
	
	$scope.add = function () {
		if(queryService.cache.filters.length < 3) {
			queryService.cache.filters.push({
				title :	"Custom Filter",
				addSecond : false,
				filter1 : {},
				filter2 : {},
				template_url : "aws/analysis/data_filters/generic_filter.html"
			});
			queryService.queryObject.filters.or.push(
				{ 
					columns : ["", ""],
					filters : {}
				}
			);
		};
	};
	
	$scope.removeFilter = function(index){
		queryService.cache.filters.splice(index, 1);
		queryService.queryObject.filters.or.splice(index, 1); // clear both the queryObject and cache
	};
	
	$scope.removeSecond = function(index) {
		if(!queryService.cache.filters.addSecond) {
			queryService.queryObject.filters.or[index].columns[1] = "";
		};
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