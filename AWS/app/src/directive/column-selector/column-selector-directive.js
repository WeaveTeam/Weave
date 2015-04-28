AnalysisModule.directive('columnSelector', function(queryService) {
	
	function link($scope, element, attrs, ngModel, ngModelCtrl) {
//		var panel = element.find('#panel');
//		panel.draggrable().resizable({
//			 maxHeight: 300,
//		     maxWidth: 250,
//		     minHeight: 80,
//		     minWidth: 180
//		});
	}
	
	function controller($scope, $element, $rootScope, $filter) {
		
		var tree = $element.find("#hierarchyTree");
		
		$scope.showSelector = function() {
			$scope.show = !$scope.show;
		};
		
		$scope.closeSelector = function () {
			$scope.show = false;
		};
		
		$scope.$watch('hierarchy', function(newVal) {
			console.log(newVal);
			updateTree(newVal);
		}, true);
		
		function updateTree(rootNode) {
			if(!rootNode)
				return;
			$(tree).dynatree(rootNode);
		};
		
	}
	
	return {
		restrict : 'E',
		transclude : true,
		templateUrl : 'src/directive/column-selector/column_selector.tpl.html',
		link : link,
		controller : controller,
		require : 'ngModel',
		scope : {
			hierarchy : '=',
			ngModel : '='
		}
	};
});