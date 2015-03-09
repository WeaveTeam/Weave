AnalysisModule.directive('filter', function() {
	
	function link(scope, element, attrs) {
		element.draggable().resizable();
		element.addClass('databox');
		element.width(300);
		element.height("100%");
	}
	
	return {
		restrict : 'E',
		transclude : true,
		templateUrl : 'src/analysis/data_filters/generic_filter.html',
		link : link,
		scope : {
			columns : '='
		},
		controller: function($scope, $filter) {
			var columns = scope.columns;
			$scope.$watch('columns', function() {
				columns = $scope.columns;
			});
			$scope.getItemId = function(item) {
				return item.id;
			};
			$scope.getItemText = function(item) {
				return item.description || item.title;
			};
			
			$scope.getFilterInputOptions = function(term, done) {
				done($filter('filter')(columns, {title:term}, 'title'));
			};
			
			$scope.getMetadata = function() {
				
			};
		}
	};
});

AnalysisModule.controller('dataFilterCtrl', function($scope, queryService, $filter){
	
	$scope.queryService = queryService;
	$scope.filterType;
	
	$scope.uiFilterOptions = ["combobox", "slider", "multiselect"];
	
	$scope.filterOptions = {};
	
	$scope.$watchCollection('queryService.queryObject.filters', function() {
		console.log($scope.$index); 
	});
	
	$scope.getItemId = function(item) {
		return item.id;
	};
	
	$scope.getItemText = function(item) {
		if(queryService.queryObject.properties.displayAsQuestions)
			return item.description || item.title;
		return item.title;
	};
	
	$scope.getFilterInputOptions = function(term, done) {
		var values = queryService.cache.columns;
		done($filter('filter')(values, {title:term}, 'title'));
	};
	// this makes the panel draggable upon initialization
	// there might be a better way to do this
//	$scope.$watchCollection(function() {
//		return $(".draggable_filter");
//	}, function() {
//		 $(".draggable_filter" ).draggable();
//	});
	
	$scope.add = function () {
		queryService.queryObject.filters.push({
			title :	"Generic Filter",
			template_url : "src/analysis/data_filters/generic_filter.html"
		});
	};
	$scope.categoricalFilterValues = [];
	
	$scope.updateCategoricalFilter = function(index)
	{
		queryService.queryObject.filters[index].value = $scope.categoricalFilterValues;
	};
	
//	$scope.$watch('queryService.queryObject.filters[$parent.$index].value', function() {
//		if($scope.filterType = "comboxbox" || $scope.filterType == "multiselect")
//		{
//			if(queryService.queryObject.filters[$scope.$parent.$index] && queryService.queryObject.filters[$scope.$parent.$index].value)
//			{
//				$scope.categoricalFilterValues = queryService.queryObject.filters[$scope.$parent.$index].value;
//			}
//		}
//	});
			
	
	$scope.getMetadata = function(index) {
		if(queryService.queryObject.filters[index] && 
			queryService.queryObject.filters[index].column &&
			queryService.queryObject.filters[index].column.hasOwnProperty("id"))
		{
			var column = queryService.queryObject.filters[index].column;
			queryService.getEntitiesById([column.id], true).then(function(entity) {
				entity = entity[0];
				if(entity && entity.publicMetadata.hasOwnProperty("aws_metadata")) {
					var metadata = angular.fromJson(entity.publicMetadata.aws_metadata);
					if(metadata.hasOwnProperty("varType")) {
						if(metadata.varType == "continuous") {
							$scope.filterType = "slider";
							$scope.filterOptions.min = angular.fromJson(metadata.varRange)[0];
							$scope.filterOptions.max = angular.fromJson(metadata.varRange)[1];
							queryService.queryObject.filters[index].value = [($scope.filterOptions.max - $scope.filterOptions.min) / 5, 3*($scope.filterOptions.max - $scope.filterOptions.min) / 5];
							queryService.queryObject.filters[index].value = {
									range : true,
									min: ($scope.filterOptions.max - $scope.filterOptions.min) / 5,
									max: 3*($scope.filterOptions.max - $scope.filterOptions.min) / 5
							};
						} else if(metadata.varType == "categorical") {
							if(metadata.varValues.length < 10) {
								$scope.filterType = "combobox";
							} else {
								$scope.filterType = "multiselect";
							}
							$scope.filterOptions = metadata.varValues;
						}
					}
				}
			});
		}
	};
	
}); 