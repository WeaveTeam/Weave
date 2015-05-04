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
		
		if(multiple) {
			$scope.ngModel =[];
		}
		
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
								if($scope.ngModel.length == 0) {
									element.html("");
								}
								var index = $scope.ngModel.push(weaveNode.getColumnMetadata()) - 1;
								element.append('&nbsp <div class="pill">' + weaveNode.getColumnMetadata().title + '<span id=' + index +' style="cursor : default; color:gray; margin-top:3px" class="glyphicon glyphicon-remove"></span></div');
								
								//var span = element.find(index);
								var span = $('#' + index); // element.find didn't seem to work, so we use the jquery selector.
								span.on('click', function() {
									$scope.ngModel.splice(index, 1);
								});
								console.log(element);
							} else {
								$scope.ngModel = weaveNode.getColumnMetadata();
								element.html('&nbsp' + weaveNode.getColumnMetadata().title);
							}
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
							var span = $('#' + index); // element.find didn't seem to work, so we use the jquery selector.
							span.on('click', function() {
								$scope.ngModel.splice(index, 1);
							});
						});
						console.log(element);
					} else {
						element.html('&nbsp drop column here...');
					}
				} else {
					element.html('&nbsp' + model.title);
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