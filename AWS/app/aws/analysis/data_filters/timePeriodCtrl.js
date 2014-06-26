analysis_mod.controller('timePeriodCtrl', function($scope, queryService){
	
	var timeTreeData;
	
	$scope.$watchCollection('[yearColumn, monthColumn]', function() {
		if($scope.yearColumn && $scope.monthColumn) {
				
				aws.queryDataService('getEntities', [angular.fromJson(yearColumn).id, angular.fromJson(monthColumn).id], function(entities) {
					yearColumnEntity = entities[0];
					monthColumnEntity = entities[1];
				});

				var year_metadata; 
				var month_metadata;
				
				year_metadata = angular.fromJson(entities[0].publicMetadata.aws_metadata).varValues;
				month_metadata = angular.fromJson(entities[1].publicMetadata.aws_metadata).varValues;
				
				timeTreeData = createTimeTreeData(year_metadata, month_metadata);
		}
	});
	
	var createTimeTreeData = function(year_metadata, month_metadata) {
		var treeData = [];
		for(var i in year_metadata) {
			treeData[i] = { title : year_metadata[i].label, key : year_metadata[i].value, isFolder : true,  children : [] };
			for(var j in month_metadata) {
				treeData[i].children.push({ title : month_metadata[j].label, key : month_metadata[j].value });
			}
		}
		return treeData;
	};

	$scope.$watch(function() {
		
		return timeTreeData;
		
	}, function(){
		
		$("#timeTree").dynatree({
			minExpandLevel: 1,
			checkbox : true,
			selectMode : 3,
			children : timeTreeData,
			keyBoard : true,
			onSelect: function() {
				var treeSelection = {};
				var root = $("#timeTree").dynatree("getRoot");
				
				for (var i = 0; i < root.childList.length; i++) {
					var year = root.childList[i];
					for(var j = 0; j < year.childList.length; j++) {
						var month = year.childList[j];
						if(year.childList[j].bSelected) {
							if(!treeSelection[year.data.key]) {
								var monthKey = month.data.key;
								treeSelection[year.data.key] = {};
								treeSelection[year.data.key].label = year.data.title;
								var monthObj = {};
								monthObj[monthKey] = month.data.title;
								treeSelection[year.data.key].months = [monthObj];
							} else {
								var monthKey = month.data.key;
								var monthObj = {};
								monthObj[monthKey] = month.data.title;
								treeSelection[year.data.key].months.push( monthObj );
							}
						}
					}
				}
				queryService.queryObject.TimePeriodFilter.filters = treeSelection;
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
		var node = $("#timeTree").dynatree("getRoot");
	    node.sortChildren(cmp, true);
		$("#timeTree").dynatree("getTree").reload();
	});
	
	 $scope.toggleSelect = function(){
	      $("#timeTree").dynatree("getRoot").visit(function(node){
	        node.toggleSelect();
	      });
	 };
	 
	$scope.deSelectAll = function(){
      $("#timeTree").dynatree("getRoot").visit(function(node){
        node.select(false);
      });
    };
    
    $scope.selectAll = function(){
    	$("#timeTree").dynatree("getRoot").visit(function(node){
    		node.select(true);
    	});
    };
    
    var cmp = function(a, b) {
		a = a.data.key;
		b = b.data.key;
		return a > b ? 1 : a < b ? -1 : 0;
    }
});