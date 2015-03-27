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
		//element.height(120);
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
			
			$scope.model = {
					comboboxModel : [],
					multiSelectModel : [],
					sliderModel : []
			};
			$scope.filterType = "";
			
			$scope.ngModel = {
					model : $scope.model,
					nestedFilter : {}
			};
			
			$scope.$watch('model.column',  function() {
				if($scope.model.column && $scope.model.column.hasOwnProperty("id")) {
					queryService.getEntitiesById([$scope.model.column.id], true).then(function(entity) {
						entity = entity[0];
						if(entity && entity.publicMetadata.hasOwnProperty("aws_metadata")) {
							var metadata = angular.fromJson(entity.publicMetadata.aws_metadata);
							if(metadata.hasOwnProperty("varType")) {
								if(metadata.varType == "continuous") {
									$scope.filterType = "slider";
									var min = angular.fromJson(metadata.varRange)[0];
									var max = angular.fromJson(metadata.varRange)[1];
									$scope.sliderOptions = { range:true, min:min, max:max }; // todo. put the slider values on top of the slider
									$scope.model.sliderModel = [Math.floor((max - min) / 3), Math.floor(2*(max - min) / 3)];
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
			
			$scope.$watch('model.column', function() {
				if(!$scope.model.column || !$scope.model.column.hasOwnProperty("id")) {
					$scope.filterType = "";
				}
			}, true);
			
			$scope.$watchCollection('model.multiSelectModel', function() {
				var model = $scope.model.multiSelectModel;
				
				$scope.model.comboboxModel = [];
				$scope.model.sliderModel = [];

				if(!model.length)
					return;
				
				$scope.ngModel.nestedFilter = 
					{
						cond : {
							f : $scope.model.column.id,
							v : model
						}
					};
			});
			
			/* combo box controls    */
			$scope.$watchCollection('model.comboboxModel', function () {
				
				var model = $scope.model.comboboxModel;
				
				$scope.model.multiSelectModel = [];
				$scope.model.sliderModel = [];
				
				if(!model.length)
					return;
				
				var result = [];
				for(var i in model)
				{
					if(model[i])
						result.push($scope.filterOptions[i].value);
				}
				$scope.ngModel.nestedFilter = 
					{
						cond : {
							f : $scope.model.column.id,
							v : result
						}
					};
			});
			
			/* combo box controls    */
			$scope.$watchCollection('model.sliderModel', function() {
				var model = $scope.model.sliderModel;

				$scope.model.multiSelectModel = [];
				$scope.model.comboboxModel = [];

				if(!model.length)
					return;
				
				$scope.ngModel.nestedFilter = 
					{
						cond : {
							f : $scope.model.column.id,
							v : [model]
						}
					};
			});
			
			/* 
			 * we watch the ngModel inside the directive because
			 * when ngModel change externally, we should be able to adjust the 
			 * internal model accordingly
			 *
			 */
			$scope.$watch('ngModel.model', function() { 
				if($scope.ngModel && $scope.ngModel.model) {
					$scope.model = $scope.ngModel.model;
				}
			}, true);
		}
	};
});

AnalysisModule.controller('dataFilterCtrl', function($scope, queryService, $filter){
	
	$scope.addFilter = function() {
		// the values are the same as the index for convenience
		queryService.queryObject.filterArray.push(queryService.queryObject.filterArray.length);
	};
	
	$scope.removeFilter = function(index) {
		queryService.queryObject.filterArray.splice(index, 1);
		queryService.queryObject.filters.splice(index, 1);
	};

	$scope.addTreeFilter = function() {
		// the values are the same as the index for convenience
		queryService.queryObject.treeFilterArray.push(queryService.queryObject.treeFilterArray.length);
	};
	
	$scope.removeTreeFilter = function(index) {
		queryService.queryObject.treeFilterArray.splice(index, 1);
		queryService.queryObject.treeFilters.splice(index, 1);
	};	
});