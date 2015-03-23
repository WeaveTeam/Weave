AnalysisModule.directive('treeFilter', function(queryService) {
	
	function link($scope, element, attrs, ngModel, modelCtrl) {
		element.draggable({ containment: "parent"}).resizable({
			 maxHeight: 300,
		     maxWidth: 650,
		     minHeight: 80,
		     minWidth: 270
		});
		element.addClass('databox');
		element.width("30%");
		element.height("100%");
		
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
		controller : function($scope, $element, $filter) {
			
			var tree = $element.find('#tree');
			var treeData = [];
			$scope.model = {
					firstLevel : undefined,
					secondLevel : undefined,
					filter : []
			};
			
			$scope.$watchCollection(function() {
				return [$scope.model.firstLevel, $scope.model.secondLevel];
			}, function() {
				if($scope.model.firstLevel && $scope.model.secondLevel) {
					if($scope.model.firstLevel.id && $scope.model.secondLevel.id) {
						queryService.getEntitiesById([$scope.model.firstLevel.id, $scope.model.secondLevel.id], true).then(function(entities) {
							firstLevelEntity = entities[0];
							secondLevelEntity = entities[1];
							if(firstLevelEntity.publicMetadata.hasOwnProperty("aws_metadata") &&
									secondLevelEntity.publicMetadata.hasOwnProperty("aws_metadata")) {
								var firstLevel_metadata; 
								var secondLevel_metadata;
								
								firstLevel_metadata = angular.fromJson(firstLevelEntity.publicMetadata.aws_metadata).varValues;
								secondLevel_metadata = angular.fromJson(secondLevelEntity.publicMetadata.aws_metadata).varValues;
								
								treeData = convertToTreeData(firstLevel_metadata, secondLevel_metadata);
							}
						});
					} else if($scope.model.firstLevel.id &&
							!$scope.model.secondLevel.id) {
						queryService.getEntitiesById([firstLevel.id], true).then(function(entities) {
							firstLevelEntity = entities[0];
							if(firstLevelEntity.publicMetadata.hasOwnProperty("aws_metadata")) {
								var firstLevel_metadata; 
								
								firstLevel_metadata = angular.fromJson(firstLevelEntity.publicMetadata.aws_metadata).varValues;
								treeData = convertToTreeData(firstLevel_metadata, []);
							}
						});
					} else if(!$scope.model.firstLevel.id &&
							$scope.model.secondLevel.id) {
						var firstLevel = angular.fromJson($scope.model.secondLevel);
						
						queryService.getEntitiesById([firstLevel.id], true).then(function(entities) {
							firstLevelEntity = entities[0];
							if(firstLevelEntity.publicMetadata.hasOwnProperty("aws_metadata")) {
								var firstLevel_metadata; 
								
								firstLevel_metadata = angular.fromJson(firstLevelEntity.publicMetadata.aws_metadata).varValues;
								treeData = convertToTreeData(firstLevel_metadata, []);
							}
						});
					} // just the firstLevel column and no secondLevel column.
				}
			});
			
			var cmp = function(a, b) {
				a = a.data.key;
				b = b.data.key;
				return a > b ? 1 : a < b ? -1 : 0;
			};
			
			var convertToTreeData = function(firstLevel_metadata, secondLevel_metadata) {
				var treeData = [];
				for(var i in firstLevel_metadata) {
					if(!secondLevel_metadata.length) {
						treeData[i] = { title : firstLevel_metadata[i].label, key : firstLevel_metadata[i].value, isFolder : true,  children : [] };
					} else {
						console.log(secondLevel_metadata);
						treeData[i] = { title : firstLevel_metadata[i].label, key : firstLevel_metadata[i].value, isFolder : false,  children : [] };
					}
					for(var j in secondLevel_metadata) {
						treeData[i].children.push({ title : secondLevel_metadata[j].label, key : secondLevel_metadata[j].value });
					}
				}
				return treeData;
			};
			
			$scope.$watch(function() {
				
				return treeData;
				
			}, function(){
				
				if(!treeData.length)
					return
				$(tree).dynatree({
					minExpandLevel: 1,
					checkbox : true,
					selectMode : 3,
					children : treeData,
					keyBoard : true,
					onSelect: function() {
						var treeSelection = {};
						var root = $(tree).dynatree("getRoot");
						
						// convert the selection to a compatible format.
						for (var i = 0; i < root.childList.length; i++) {
							var firstLevel = root.childList[i];
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
						}
						$scope.model.filters = treeSelection;
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
			});
			
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
	}
});