AnalysisModule.directive('columnSelector', function(queryService) {
	
	function link($scope, element, attrs) {
		
		$scope.showHierarchy = function() {
			queryService.queryObject.properties.showHierarchy = true;
		};

		$scope.clear = function() {
			if($scope.model)
				$scope.model.selected = "";
		};
		
		$scope.$watch('model.selected', function(model) { 
			$scope.ngModel = model;
		}, true);
		
	}
	
	return {
		restrict : 'E',
		transclude : true,
		templateUrl : function(tElement, tAttrs) {
	      return angular.isDefined(tAttrs.multiple) ? 'src/directive/column-selector/column_selector-multiple.tpl.html' : 'src/directive/column-selector/column_selector.tpl.html';
	    },
		link : link,
		scope : {
			ngModel : '=',
		}
	};
});