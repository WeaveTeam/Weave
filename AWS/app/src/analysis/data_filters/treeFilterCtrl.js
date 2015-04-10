AnalysisModule.directive('treeFilter', function(queryService) {
	
	function link($scope, element, attrs, ngModel, ngModelCtrl) {
//		element.draggable({ containment: "parent"}).resizable({
//			 //maxHeight: 300,
//		     maxWidth: 250,
//		     minHeight: 80,
//		     minWidth: 180
//		});
		element.addClass('databox');
		element.width(180);
		//element.height("100%");
		
	}

	return {
		restrict : 'E',
		transclude : true,
		templateUrl : 'src/analysis/data_filters/tree_filter.tpl.html',
		link : link,
		require : 'ngModel',
		scope : {
			columns : '=',
			ngModel : '='
		},
		controller : function($scope, $element, $rootScope, $filter) {
			
			var tree = $element.find('#tree');
			var treeData = [];
			$scope.ngModel = $scope.$parent.treeFiltersModel[$scope.$parent.$index] || {
					firstLevel : undefined,
					secondLevel : undefined,
					treeSelection : []
			};
			
			// this 3 watches prevents the user from selecting
			// the same column twice.
			// TODO find a better way to do this
			$scope.$watchCollection('columns', function() {
				if($scope.columns.length) {
					$scope.firstLevelColumns = $.map($scope.columns, function(column) {
						if($scope.ngModel && $scope.ngModel.secondLevel) {
							if(column.id != $scope.ngModel.secondLevel.id) 
								return column;
							else
								console.log(column);
						} else {
							return column;
						}
					});
					$scope.secondLevelColumns = $.map($scope.columns, function(column) {
						if($scope.ngModel && $scope.ngModel.firstLevel) {
							if(column.id != $scope.ngModel.firstLevel.id)
								return column;
							else
								console.log(column);
						} else {
							return column;
						}
					});
					
				}
			}, true);
			
			$scope.$watch(function() {
				return $scope.ngModel.firstLevel;
			}, function() {
				if($scope.columns.length) {
					$scope.secondLevelColumns = $.map($scope.columns, function(column) {
						if($scope.ngModel && $scope.ngModel.firstLevel) {
							if(column.id != $scope.ngModel.firstLevel.id)
								return column;
						} else {
							return column;
						}
					});
				}
			});
			
			$scope.$watch(function() {
				return $scope.ngModel.secondLevel;
			}, function() {
				if($scope.columns.length) {
					$scope.firstLevelColumns = $.map($scope.columns, function(column) {
						if($scope.ngModel && $scope.ngModel.secondLevel) {
							if(column.id != $scope.ngModel.secondLevel.id) 
								return column;
						} else {
							return column;
						}
					});
				}
			});
			$scope.firstLevelColumns = [];
			$scope.secondLevelColumns = [];
			
			$scope.$watchCollection(function() {
				return [$scope.ngModel.firstLevel, $scope.ngModel.secondLevel];
			}, function(newVal, oldVal) {
				if($scope.ngModel.firstLevel && $scope.ngModel.secondLevel && $scope.ngModel.firstLevel.id && $scope.ngModel.secondLevel.id) {
					queryService.getEntitiesById([$scope.ngModel.firstLevel.id, $scope.ngModel.secondLevel.id], true).then(function(entities) {
						firstLevelEntity = entities[0];
						secondLevelEntity = entities[1];
						if(firstLevelEntity.publicMetadata.hasOwnProperty("aws_metadata") &&
								secondLevelEntity.publicMetadata.hasOwnProperty("aws_metadata")) {
							var varValues = angular.fromJson(firstLevelEntity.publicMetadata.aws_metadata).varValues;
							if(varValues) { // check if varValues is not null
								// get var values by checking if not stored in another table.
								queryService.getDataMapping(varValues).then(function(firstLevel_metadata) {
									varValues = angular.fromJson(secondLevelEntity.publicMetadata.aws_metadata).varValues;
									if(varValues) {
										queryService.getDataMapping(varValues).then(function(secondLevel_metadata) {
											treeData = convertToTreeData(firstLevel_metadata, secondLevel_metadata);
										});
									}
								});
							}
						}
					});
				} else if($scope.ngModel.firstLevel && $scope.ngModel.firstLevel.id &&
						!$scope.ngModel.secondLevel) {
					queryService.getEntitiesById([$scope.ngModel.firstLevel.id], true).then(function(entities) {
						firstLevelEntity = entities[0];
						if(firstLevelEntity.publicMetadata.hasOwnProperty("aws_metadata")) {
							var varValues = angular.fromJson(firstLevelEntity.publicMetadata.aws_metadata).varValues;
							if(varValues)
							{
								queryService.getDataMapping(varValues).then(function(firstLevel_metadata) {
									treeData = convertToTreeData(firstLevel_metadata, []);
								});
							}
						}
					});
				} else if(!$scope.ngModel.firstLevel &&
						$scope.ngModel.secondLevel && $scope.ngModel.secondLevel.id) {
					queryService.getEntitiesById([$scope.ngModel.secondLevel.id], true).then(function(entities) {
						firstLevelEntity = entities[0];
						if(firstLevelEntity.publicMetadata.hasOwnProperty("aws_metadata")) {
							var varValues = angular.fromJson(firstLevelEntity.publicMetadata.aws_metadata).varValues;
							if(varValues) {
								queryService.getDataMapping(varValues).then(function(firstLevel_metadata) {
									treeData = convertToTreeData(firstLevel_metadata, []);
								});
							}
						}
					});
				} else {
					treeData = [];
				}// just the firstLevel column and no secondLevel column.
			});
			
			var cmp = function(a, b) {
				a = a.data.key;
				b = b.data.key;
				return a > b ? 1 : a < b ? -1 : 0;
			};
			
			var convertToTreeData = function(firstLevel_metadata, secondLevel_metadata) {
				var treeData = [];
				for(var i in firstLevel_metadata) {
					treeData[i] = { title : firstLevel_metadata[i].label, key : firstLevel_metadata[i].value, isFolder : false, icon : false,  children : [] };
					for(var j in secondLevel_metadata) {
						treeData[i].children.push({ title : secondLevel_metadata[j].label, key : secondLevel_metadata[j].value, icon : false });
					}
				}
				return treeData;
			};
			
			$scope.$watch('ngModel', function() {
				if($scope.ngModel) {
					$scope.ngModel.nestedFilter = {
							or : []
					};
					var nestedFilter = $scope.ngModel.nestedFilter;
					if($scope.ngModel.treeSelection && (Object.keys($scope.ngModel.treeSelection) || $scope.treeSelection.length))
					{
						if($scope.ngModel.firstLevel && $scope.ngModel.firstLevel.id && $scope.ngModel.secondLevel && $scope.ngModel.secondLevel.id)
						{
							for(var key in $scope.ngModel.treeSelection) {
								var index = nestedFilter.or.push({ and : [
								                                          {
								                                        	  cond : { 
								                                        		  f : $scope.ngModel.firstLevel.id, 
								                                        		  v : [key] 
								                                        	  }
								                                          },
								                                          {
								                                        	  cond: {
								                                        		  f : $scope.ngModel.secondLevel.id, 
								                                        		  v : []
								                                        	  }
								                                          }
								                                          ]
								});
								
								for(var i in $scope.ngModel.treeSelection[key].secondLevels) {
									var seconLevelValues = "";
									for(var key2 in $scope.ngModel.treeSelection[key].secondLevels[i]) {
										secondLevelValues = key2;
									}
									nestedFilter.or[index-1].and[1].cond.v.push(secondLevelValues);
								}
							}
						} else {
							var level = $scope.ngModel.firstLevel || $scope.ngModel.secondLevel;
							
							if(level && level.id && $scope.ngModel.treeSelection) {
								$scope.ngModel.nestedFilter = {
										cond : {
											f : level.id,
											v : $scope.ngModel.treeSelection
										}
								};
							}
						}
					}
				}
			}, true);
			
			$scope.$watch(function() {
				
				return treeData;
				
			}, function(){
				
				if(!treeData.length)
				{
					$(tree).dynatree({
						minExpandLevel: 1,
						checkbox : true,
						icon : false,
						selectMode : 3,
						children : []
					});
					 $(tree).dynatree("getTree").reload();
					return;
				}
				$(tree).dynatree({
					minExpandLevel: 1,
					checkbox : true,
					icon : false,
					selectMode : 3,
					children : treeData,
					keyBoard : true,
					onSelect: function() {
						var treeSelection = {};
						var root = $(tree).dynatree("getRoot");
						// convert the selection to a compatible format.
						for (var i = 0; i < root.childList.length; i++) {
							var firstLevel = root.childList[i];
							if(firstLevel.childList) {
								for(var j = 0; j < firstLevel.childList.length; j++) {
									var secondLevel = firstLevel.childList[j];
									if(firstLevel.childList[j].bSelected) {
										if(!treeSelection[firstLevel.data.key]) {
											var secondLevelKey = secondLevel.data.key;
											treeSelection[firstLevel.data.key] = {};
											treeSelection[firstLevel.data.key].label = firstLevel.data.title;
											var secondLevelObj = {};
											secondLevelObj[secondLevelKey] = secondLevel.data.title;
											treeSelection[firstLevel.data.key].secondLevels = [secondLevelObj];
										} else {
											var secondLevelKey = secondLevel.data.key;
											var secondLevelObj = {};
											secondLevelObj[secondLevelKey] = secondLevel.data.title;
											treeSelection[firstLevel.data.key].secondLevels.push(secondLevelObj);
										}
									}
								}
							} else {
								// when the firstLevel doesn't have a childList, it's a one level tree
								if(firstLevel.bSelected) {
									treeSelection[i] = firstLevel.data.key;
									// convert treeSelection to array in the case where it's 1D
									treeSelection = $.map(treeSelection, function(value, index) {
										return [value];
									});
									
									// cleans the array
									treeSelection = treeSelection.filter(function(n){ return n != undefined; }); 
								}
							}
						}
						$scope.ngModel.treeSelection = treeSelection;
						$rootScope.$safeApply();
					},
					onKeydown: function(node, event) {
						if( event.which == 32 ) {
							node.toggleSelect();
							return false;
						}
					},
					cookieId: "time-period-tree",
					idPrefix: "time-period-tree-",
					debugLevel: 0
				});
				var node = $(tree).dynatree("getRoot");
				node.sortChildren(cmp, true);
				$(tree).dynatree("getTree").reload();
			}, true);
			
			$scope.toggleSelect = function(){
				$(tree).dynatree("getRoot").visit(function(node){
					node.toggleSelect();
				});
			};
			
			$scope.deSelectAll = function(){
				$(tree).dynatree("getRoot").visit(function(node){
					node.select(false);
				});
			};
			
			$scope.selectAll = function(){
				$(tree).dynatree("getRoot").visit(function(node){
					node.select(true);
				});
			};
		}
	};
});