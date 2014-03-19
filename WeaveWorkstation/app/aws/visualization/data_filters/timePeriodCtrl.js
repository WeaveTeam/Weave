analysis_mod.controller('timePeriodCtrl', function($scope, queryService){
	queryService.queryObject.TimePeriodFilter = {
			years : [],
			months : [],
			yearColumn : {},
			monthColumn : {}
	};
	
	var timeTreeData;
	
	$scope.$watch(function() {
		return queryService.dataObject.columns;
	}, function() {
		if(queryService.dataObject.columns != undefined) {

			$scope.yearDBOptions = $.map(queryService.dataObject.columns, function(column) {
					var aws_metadata = angular.fromJson(column.publicMetadata.aws_metadata);
					if(aws_metadata != undefined){
						if(aws_metadata.hasOwnProperty("columnType")) {
							if(aws_metadata.columnType == "time") {
								return { id : column.id , title : column.publicMetadata.title};
							} else {
								// skip
							}
						}
					}
				});
			$scope.monthDBOptions = $scope.yearDBOptions;
		};
	});
	
	
	$scope.$watch('yearDBSelection', function() {
		if($scope.yearDBSelection != undefined) {
			if($scope.yearDBSelection != "") {
				queryService.queryObject.TimePeriodFilter.yearColumn = angular.fromJson($scope.yearDBSelection);
			} else {
				queryService.queryObject.TimePeriodFilter.yearColumn = {};
			}
		}
	});
	
	$scope.$watch('monthDBSelection', function() {
		if($scope.stateDBSelection != undefined) {
			if($scope.stateDBSelection != "") {
				queryService.queryObject.TimePeriodFilter.monthColumn = angular.fromJson($scope.monthDBSelection);
			} else {
				queryService.queryObject.TimePeriodFilter.monthColumn = {};
			}
		}
	});
	
	$scope.$watchCollection('[yearDBSelection, monthDBSelection]', function() {
		if($scope.yearDBSelection != undefined && $scope.monthDBSelection != undefined) {
			if($scope.yearDBSelection != "" && $scope.monthDBSelection != "") {
				var yearColumnId = angular.fromJson($scope.yearDBSelection).id;
				var monthColumnId = angular.fromJson($scope.monthDBSelection).id;
				columns = queryService.dataObject.columns;
				var year_metadata; 
				var month_metadata;
				
				// run time on average is less than O(n)
				for(var i in columns) {
					if(columns[i].id == yearColumnId) {
						if(columns[i].publicMetadata.hasOwnProperty("aws_metadata")) {
							year_metadata = angular.fromJson(columns[i].publicMetadata.aws_metadata).varValues;
							break;
						}
					}
				}
				for(var i in columns) {
					if(columns[i].id == monthColumnId) {
						if(columns[i].publicMetadata.hasOwnProperty("aws_metadata")) {
							month_metadata = angular.fromJson(columns[i].publicMetadata.aws_metadata).varValues;
							break;
						}
					}
				}
				
				if(year_metadata && month_metadata) {
					timeTreeData = createTimeTreeData(year_metadata, month_metadata);
				}
			}
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
	}

	$scope.$watch(function() {
		return timeTreeData;
	}, function(){
		$("#timeTree").dynatree({
			minExpandLevel: 1,
			checkbox : true,
			selectMode : 3,
			children : timeTreeData,
			keyBoard : true,
			onSelect: function(select, node) {
				var year_nodes = {};
				var month_nodes = {};
				$("#timeTree").dynatree("getRoot").visit(function(node){
					var partSel = [];
					if(node.childList) { // dirty check to see if year node
						if(node.bSelected) {
							year_nodes[node.data.key] = node.data.title;
						}
					} else {
						if(node.bSelected) {
							month_nodes[node.data.key] = node.data.title;
						}
					}
					$(".dynatree-partsel:not(.dynatree-selected)").each(function () {
				        var node = $.ui.dynatree.getNode(this);
				        if(node.childList) {
				        	year_nodes[node.data.key] = node.data.title;
				        } else {
				        	
				        }
				    });
				});

					var year_array = [];
					var month_array = [];
					for(key in year_nodes) {
						year_array.push({value : key, label : year_nodes[key]});
					}
					for(key in month_nodes) {
						month_array.push({value : key, label : month_nodes[key]});
					}
					
					queryService.queryObject.TimePeriodFilter.years = year_array;
					queryService.queryObject.TimePeriodFilter.months = month_array;
					console.log(queryService.queryObject.TimePeriodFilter.years);
					console.log(queryService.queryObject.TimePeriodFilter.months);
			},
			 onKeydown: function(node, event) {
				 if( event.which == 32 ) {
					 node.toggleSelect();
					 return false;
				 }
		     },
		     debugLevel: 0
		});
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
});