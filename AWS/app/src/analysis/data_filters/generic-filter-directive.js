AnalysisModule.directive('filter', function(queryService) {
	
	function link($scope, element, attrs, ngModelCtrl) {
//		element.draggable({ containment: "parent" }).resizable({
//			 //maxHeight: 150,
//		     maxWidth: 250,
//		     minHeight: 100,
//		     minWidth: 180
//		});
		element.addClass('databox');
		element.width(180);
	}

	return {

		restrict : 'E',
		transclude : true,
		templateUrl : 'src/analysis/data_filters/generic_filter.html',
		link : link,
		require : 'ngModel',
		scope : {
			columns : '=',
			ngModel : '='
		},
		controller : function($scope, $filter) {
			
			$scope.ngModel = $scope.$parent.filtersModel[$scope.$parent.$index] || {
					comboboxModel : [],
					multiselectModel : [],
					sliderModel : [],
					nestedFilter : {},
			};
			$scope.filterType = "";
			$scope.filterOptions = [];
			
			$scope.$watch('ngModel.column',  function(newVal, oldVal) {
				if($scope.ngModel.column && $scope.ngModel.column.hasOwnProperty("id")) {
					queryService.getEntitiesById([$scope.ngModel.column.id], true).then(function(entity) {
						entity = entity[0];
						if(entity && entity.publicMetadata.hasOwnProperty("aws_metadata")) {
							var metadata = angular.fromJson(entity.publicMetadata.aws_metadata);
							if(metadata.hasOwnProperty("varType")) {
								if(metadata.varType == "continuous") {
									$scope.filterType = "slider";
									var min = angular.fromJson(metadata.varRange)[0];
									var max = angular.fromJson(metadata.varRange)[1];
									$scope.sliderOptions = { range:true, min:min, max:max }; // todo. put the slider values on top of the slider
									$scope.ngModel.sliderModel = [Math.floor((max - min) / 3), Math.floor(2*(max - min) / 3)];
								} else if(metadata.varType == "categorical") {
									if(metadata.varValues) {
										queryService.getDataMapping(metadata.varValues).then(function(varValues) {
											$scope.filterOptions = varValues;
											if($scope.filterOptions.length < 10) {
												$scope.filterType = "combobox";
											} else {
												$scope.filterType = "multiselect";
											}
										});
									}
								}
							} else {
								$scope.filterType = "";
							}
						}
					});
				}
			}, true);
			
			$scope.$watch('ngModel.column', function(newVal, oldVal) {
				if(!$scope.ngModel.column || !$scope.ngModel.column.hasOwnProperty("id")) {
					$scope.filterType = "";
				}
			}, true);
			
			$scope.$watchCollection('ngModel.multiselectModel', function(newVal, oldVal) {
				var ngModel = $scope.ngModel.multiselectModel;
				
				$scope.ngModel.comboboxModel = [];
				$scope.ngModel.sliderModel = [];

				if(!ngModel || !ngModel.length)
					return;
				
				$scope.ngModel.nestedFilter = 
					{
						cond : {
							f : $scope.ngModel.column.id,
							v : ngModel
						}
					};
			});
			
			/* combo box controls    */
			$scope.$watchCollection('ngModel.comboboxModel', function(newVal, oldVal) {
				
				var ngModel = $scope.ngModel.comboboxModel;
				
				$scope.ngModel.multiselectModel = [];
				$scope.ngModel.sliderModel = [];
				
				if(!ngModel.length)
					return;
				
				var result = [];
				for(var i in ngModel)
				{
					if(ngModel[i] && $scope.filterOptions[i])
						result.push($scope.filterOptions[i].value);
				}
				$scope.ngModel.nestedFilter = 
					{
						cond : {
							f : $scope.ngModel.column.id,
							v : result
						}
					};
			});
			
			/* combo box controls    */
			$scope.$watchCollection('ngModel.sliderModel', function(newVal, oldVal) {

				var ngModel = $scope.ngModel.sliderModel;

				$scope.ngModel.multiselectModel = [];
				$scope.ngModel.comboboxModel = [];

				if(!ngModel.length)
					return;
				
				$scope.ngModel.nestedFilter = 
					{
						cond : {
							f : $scope.ngModel.column.id,
							r : [ngModel]
						}
					};
			});
		}
	};
});