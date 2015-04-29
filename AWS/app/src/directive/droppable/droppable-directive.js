AnalysisModule.directive('droppable', function() {
	
	function link($scope, element, attrs, ngModel) {
		$scope.label = "drop column here";
		
		element.droppable({
			hoverClass : "drophover",
			addClasses : true,
	
			drop : function(event, ui) {
				$scope.ngModel = ui.helper.data("dtSourceNode");
				$scope.$apply();
			}
		});
	}
	
	return {
		restrict : 'A',
		link : link,
		require : 'ngModel',
		scope : {
			ngModel : '='
		}
	};
});