AnalysisModule.directive('time-filter', function(queryService) {

	
});
AnalysisModule.controller('timePeriodCtrl', function($scope, queryService){
	
	$scope.service = queryService;
	
	var timeTreeData;
	
	$scope.$watchCollection(function() {
		return [queryService.queryObject.TimePeriodFilter.yearColumn, queryService.queryObject.TimePeriodFilter.monthColumn];
	}, function() {
		if(queryService.queryObject.TimePeriodFilter.yearColumn &&
	    	queryService.queryObject.TimePeriodFilter.monthColumn) {
				var yearColumn = angular.fromJson(queryService.queryObject.TimePeriodFilter.yearColumn);
				var monthColumn = angular.fromJson(queryService.queryObject.TimePeriodFilter.monthColumn);

				queryService.getEntitiesById([yearColumn.id, monthColumn.id], true).then(function(entities) {
					yearColumnEntity = entities[0];
					monthColumnEntity = entities[1];
					if(yearColumnEntity.publicMetadata.hasOwnProperty("aws_metadata") &&
							monthColumnEntity.publicMetadata.hasOwnProperty("aws_metadata")) {
						var year_metadata; 
						var month_metadata;
						
						year_metadata = angular.fromJson(yearColumnEntity.publicMetadata.aws_metadata).varValues;
						month_metadata = angular.fromJson(monthColumnEntity.publicMetadata.aws_metadata).varValues;
						
						timeTreeData = createTimeTreeData(year_metadata, month_metadata);
					}
				});
		} else if(queryService.queryObject.TimePeriodFilter.yearColumn &&
	    	!queryService.queryObject.TimePeriodFilter.monthColumn) {
			var yearColumn = angular.fromJson(queryService.queryObject.TimePeriodFilter.yearColumn);

			queryService.getEntitiesById([yearColumn.id], true).then(function(entities) {
				yearColumnEntity = entities[0];
				if(yearColumnEntity.publicMetadata.hasOwnProperty("aws_metadata")) {
					var year_metadata; 
					
					year_metadata = angular.fromJson(yearColumnEntity.publicMetadata.aws_metadata).varValues;
					timeTreeData = createTimeTreeData(year_metadata, []);
				}
			});
		} // just the year column and no month column.
	});
	
	var createTimeTreeData = function(year_metadata, month_metadata) {
		var treeData = [];
		for(var i in year_metadata) {
			if(!month_metadata.length) {
				treeData[i] = { title : year_metadata[i].label, key : year_metadata[i].value, isFolder : true,  children : [] };
			} else {
				console.log(month_metadata);
				treeData[i] = { title : year_metadata[i].label, key : year_metadata[i].value, isFolder : false,  children : [] };
			}
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
				queryqueryService.queryObject.TimePeriodFilter.filters = treeSelection;
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