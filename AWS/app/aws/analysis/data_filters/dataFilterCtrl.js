AnalysisModule.controller('dataFilterCtrl', function($scope, queryService){
	
	$scope.queryService = queryService;
	
	$scope.add = function () {
		console.log("adding new filter");
		console.log(queryService.dataObject);
		if(queryService.dataObject.filters.length < 3) {
			queryService.dataObject.filters.push({
				title :	"Custom Filter",
				template_url : "aws/analysis/data_filters/generic_filter.html"
			});
		};
	};
	
	$scope.removeFilter = function(index){
		queryService.dataObject.filters.splice(index, 1);
		queryService.queryObject.filters.or.splice(index, 1); // clear both the queryObject and dataObject
	};
	
	
	
	
}); 