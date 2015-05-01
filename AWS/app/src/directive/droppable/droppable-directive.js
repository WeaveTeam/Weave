AnalysisModule.directive('droppable', function() {
	
	function link($scope, element, attrs, ngModelCtrl) {
		
		element.css('cursor', 'default'); 
		element.css('user-select', 'none'); 
		element.css('-o-user-select', 'none'); 
		element.css('-moz-user-select', 'none'); 
		element.css('-khtml-user-select', 'none'); 
		element.css('-webkit-user-select', 'none');

		element.html("&nbsp drop column here...");
		element.droppable({
			hoverClass : "drophover",
			addClasses : true,
			
			drop : function(event, ui) {
				if(ui && ui.helper) {
					var node = ui.helper.data("dtSourceNode");
					var weaveNode;
					if(node) {
						weaveNode = node.data.weaveNode;
						if(weaveNode) {
							$scope.ngModel = weaveNode.getColumnMetadata();
							element.html('&nbsp' + weaveNode.getColumnMetadata().title);
						}
					}
				}
			}
		});
		
		$scope.$watch('ngModel', function() {
			// update the ui when ngModel changes
			if($scope.ngModel) {
				element.html('&nbsp' + $scope.ngModel.title);
			} else {
				element.html('&nbsp drop column here...');
			}
		}, true);
		
	}
	
	return {
		restrict : 'A',
		link : link,
		scope : {
			ngModel : '=',
		}
	};
});