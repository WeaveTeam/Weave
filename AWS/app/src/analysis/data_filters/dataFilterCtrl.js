AnalysisModule.directive('filter', function(queryService) {
	
	function link($scope, element, attrs, ngModelCtrl) {
		element.draggable({ containment: "parent" }).resizable({
			 maxHeight: 300,
		     maxWidth: 650,
		     minHeight: 80,
		     minWidth: 270
		});
		element.addClass('databox');
		element.width(300);
		element.height(120);
	}

	return {

		restrict : 'E',
		transclude : true,
		templateUrl : 'src/analysis/data_filters/generic_filter.html',
		link : link,
		require : 'ngModel',
		scope : {
			columns : '=',
			ngModel : '=',
		},
		controller : function($scope, $filter) {
			
			$scope.model = {
					comboboxModel : [],
					multiSelectModel : [],
					sliderModel : []
			};
			$scope.filterType = "";
			
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
				if(!model.length)
					return;
				
				$scope.ngModel = 
					{
						f : $scope.model.column.id,
						v : model
					};
			});
			
			/* combo box controls    */
			$scope.$watchCollection('model.comboboxModel', function (newVal, oldVal) {
				var model = $scope.model.comboboxModel;
				if(!model.length)
					return;
				
				var result = [];
				for(var i in model)
				{
					if(model[i])
						result.push($scope.filterOptions[i].value);
				}
				$scope.ngModel = 
					{
						f : $scope.model.column.id,
						v : result
					};
			});
			
			/* combo box controls    */
			$scope.$watchCollection('model.sliderModel', function() {
				var model = $scope.model.sliderModel;
				if(!model.length)
					return;
				
				$scope.ngModel = 
					{
						f : $scope.model.column.id,
						v : [model]
					};
			});
			
			/* 
			 * we watch the ngModel inside the directive because
			 * when ngModel change externally, we should be able to adjust the 
			 * internal model accordingly
			 *
			 */
//			$scope.$watch('ngModel', function(newVal, oldVal) {
//				
//				if(!newVal.v.length || !oldVal.v.length || angular.equals(newVal, oldVal))
//					return;
//				// check the column id to find out the ui type.
//				var model = $scope.ngModel;
//				if(model && model.hasOwnProperty("f")) {
//					queryService.getEntitiesById([model.f], true).then(function(entity) {
//						entity = entity[0];
//						if(entity && entity.publicMetadata.hasOwnProperty("aws_metadata")) {
//							var metadata = angular.fromJson(entity.publicMetadata.aws_metadata);
//							if(metadata.hasOwnProperty("varType")) {
//								if(metadata.varType == "continuous") {
//									$scope.filterType = "slider";
//									var min = angular.fromJson(metadata.varRange)[0];
//									var max = angular.fromJson(metadata.varRange)[1];
//									$scope.sliderOptions = { range:true, min:min, max:max };
//									$scope.model.sliderModel = model.v[0];
//								} else if(metadata.varType == "categorical") {
//									if(metadata.varValues) {
//										queryService.getDataMapping(metadata.varValues).then(function(varValues) {
//											$scope.filterOptions = varValues;
//											if($scope.filterOptions.length < 10) {
//												$scope.filterType = "combobox";
//												var tempValueArray = [];
//												var combobox = [];
//												for(var i in $scope.filterOptions)
//												{
//													tempValueArray.push($scope.filterOptions[i].value);
//													combobox[i] = false;
//												}
//												for(var i in model.v) {
//													if(tempValueArray.indexOf(model.v[i]) > -1)
//													{
//														combobox[i] = true;
//													} else {
//														combobox[i] = false;
//													}
//												}
//												$scope.model.comboboxModel = combobox;
//											} else {
//												$scope.filterType = "multiselect";
//												$scope.model.multiSelectModel = model.v;
//											}
//										});
//									}
//								}
//							}
//						}
//					});
//				};
//			}, true);
		}
	};
});

AnalysisModule.controller('dataFilterCtrl', function($scope, queryService, $filter){
	
	$scope.filterArray = [];
	var i = 0;
	$scope.addFilter = function() {
		queryService.cache.filterArray.push(i);
		i++;
	};
	
	$scope.removeFilter = function(index) {
		queryService.cache.filterArray.splice(index, 1);
		queryService.queryObject.splice(index, 1);
	};
});