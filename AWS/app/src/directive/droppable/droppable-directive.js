AnalysisModule.directive('droppable', function() {
	
	function link($scope, element, attrs, ngModelCtrl) {
		
		element.css('cursor', 'default'); 
		element.css('user-select', 'none'); 
		element.css('-o-user-select', 'none'); 
		element.css('-moz-user-select', 'none'); 
		element.css('-khtml-user-select', 'none'); 
		element.css('-webkit-user-select', 'none');

		element.html("&nbsp drop column here...");
		
		var multiple = angular.isDefined(attrs.multiple);
		
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
							if(multiple) {
								if(!$scope.ngModel) {
									$scope.ngModel = [weaveNode.getColumnMetadata()];
								} else {
									$scope.ngModel.push(weaveNode.getColumnMetadata());
								}
							} else {
								$scope.ngModel = weaveNode.getColumnMetadata();
							}
							$scope.$apply();
						}
					}
				}
			}
		});
		
		$scope.$watch('ngModel', function() {
			// update the ui when ngModel changes
			if($scope.ngModel) {
				if(multiple) {
					if($scope.ngModel.length) {
						element.html('');
						$scope.ngModel.forEach(function(model, index) {
							element.append('&nbsp <div class="pill">' + model.title + '<span id=' + index +' style="cursor : default; color:gray; margin-top:3px" class="glyphicon glyphicon-remove"></span></div');
							var closebtn = element.find($('[id ='+ index + ']'));
							closebtn.on('click', function() {
								$scope.ngModel.splice(index, 1);
								$scope.$apply();
							});
						});
					} else {
						element.html('&nbsp drop column here...');
					}
				} else {
					element.html('&nbsp' + $scope.ngModel.title);
				}
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