AnalysisModule.controller('GeographyCtrl', function($scope, queryService){
	
	var geoTreeData;
	
	var stateValueKey = null;
	var stateLabelKey = null;
	var countyValueKey = null;
	var countyLabelKey = null;
	var processedMetadata;
	var metadataTableTitle = null;
	
	
	$scope.service = queryService;
	
	$scope.$watch(function() { 
		return queryService.queryObject.GeographyFilter.metadataTable;
	}, function(newValue, oldValue) {
		if(newValue) {
			metadataTable = angular.fromJson(newValue);
			metadataTableTitle = metadataTable.title;
			queryService.getEntitiesById([metadataTable.id], true).then(function(metadataTableArray) {
				
				var metadataTable = metadataTableArray[0];
				
				if(metadataTable.publicMetadata.hasOwnProperty("stateValues")) {
					stateValueKey = metadataTable.publicMetadata.stateValues;
				}
				if( metadataTable.publicMetadata.hasOwnProperty("stateLabels")) {
					stateLabelKey = metadataTable.publicMetadata.stateLabels;
				}
				
				if( metadataTable.publicMetadata.hasOwnProperty("countyValues")) {
					countyValueKey = metadataTable.publicMetadata.countyValues;
				}
				
				if( metadataTable.publicMetadata.hasOwnProperty("countyLabels")) {
					countyLabelKey = metadataTable.publicMetadata.countyLabels;
				}
				if( metadataTable.publicMetadata.hasOwnProperty("title")) {
					metadataTableTitle = metadataTable.publicMetadata.title;
				}
				queryService.getDataSetFromTableId(metadataTable.id, true);
			});
		}
	});
	
	$scope.$watchCollection(function() {
		return [queryService.cache.geographyMetadata,
		         							stateValueKey,
		         							stateLabelKey,
		         							countyValueKey,
		         							countyLabelKey,
		         							metadataTableTitle];
	}, function() {
		
		geographyMetadata = queryService.cache.geographyMetadata;
		if(geographyMetadata) {
			if(stateValueKey == null ||
			   stateLabelKey == null ||
			   countyValueKey == null ||
			   countyLabelKey == null ||
			   metadataTableTitle == null) {
			   console.log("Could not find all the geography metadata");
			} else {
				var records = geographyMetadata.records[metadataTableTitle];
				processedMetadata = [];
				for(key in records) {
					var record = records[key];
					// push the first state
					if(!processedMetadata.length) {
						processedMetadata.push({value : record[stateValueKey], 
							label : record[stateLabelKey],
							counties : []});
					}
					
					for(var i = 0; i < processedMetadata.length; i++) {
						if(record[stateValueKey] == processedMetadata[i].value) {
							processedMetadata[i].counties.push({value : record[countyValueKey],
								label : record[countyLabelKey]});
						break;
						}
						
						else if( record[stateValueKey] != processedMetadata[i].value ) {
							
							if (i == processedMetadata.length - 1){
						
								// we r	eached the end of the processedMetadata array without finding the corresponding state,
								// which means it's a new state
								processedMetadata.push({value : record[stateValueKey], 
									label : record[stateLabelKey],
									counties : [/*{value : record[countyValueKey],
									label : record[countyLabelKey]
								
								}*/]});
							} else {
								//continue the search
								continue;
							}
						}
					} 
				}
			}
		}
	});

//	$scope.$watchCollection(function() {
//
//		return [queryService.queryObject.GeographyFilter.stateColumn, queryService.queryObject.GeographyFilter.countyColumn, processedMetadata];
//		
//	}, function() {
//		var stateColumn = queryService.queryObject.GeographyFilter.stateColumn;
//		var countyColumn = queryService.queryObject.GeographyFilter.countyColumn;
//		if(stateColumn != undefined && countyColumn != undefined && processedMetadata != undefined) {
//			if(stateColumn != "" && countyColumn != "" && processedMetadata.length) {
//				geoTreeData = createGeoTreeData(processedMetadata);
//			}
//		}
//	});
	
//	var createGeoTreeData = function(metadata) {
//		var treeData = [];
//		for(var i in metadata) {
//			treeData[i] = { title : metadata[i].label, key : metadata[i].value, isFolder : true,  children : [] };
//			for(var j in metadata[i].counties) {
//				treeData[i].children.push({ title : metadata[i].counties[j].label, key : metadata[i].counties[j].value });
//			}
//		}
//		return treeData;
//	}
	
//	$scope.$watch(function() {
//		return geoTreeData;
//	}, function(){
//		if(geoTreeData) {
//			$("#geoTree").dynatree({
//				minExpandLevel: 1,
//				checkbox : true,
//				selectMode : 3,
//				children : geoTreeData,
//				keyBoard : true,
//				onSelect: function(select, node) {
//					var treeSelection = {};
//					var root = $("#geoTree").dynatree("getRoot");
//					
//					for (var i = 0; i < root.childList.length; i++) {
//						var state = root.childList[i];
//						for(var j = 0; j < state.childList.length; j++) {
//							var county = state.childList[j];
//							if(state.childList[j].bSelected) {
//								if(!treeSelection[state.data.key]) {
//									treeSelection[state.data.key] = {};
//									treeSelection[state.data.key].label = state.data.title;
//									var countyObj = {};
//									var countyKey = county.data.key;
//									countyObj[countyKey] = county.data.title;
//									treeSelection[state.data.key].counties = [countyObj];
//								} else {
//									var countyKey = county.data.key;
//									var countyObj = {};
//									countyObj[countyKey] = county.data.title;
//									treeSelection[state.data.key].counties.push(countyObj);
//								}
//							}
//						}
//					}
//					queryService.queryObject.GeographyFilter.filters = treeSelection;
//					
//				},
//				onKeydown: function(node, event) {
//					if( event.which == 32 ) {
//						node.toggleSelect();
//						return false;
//					}
//				},
//				cookieId: "geo-tree",
//				idPrefix: "geo-tree-",
//				debugLevel: 0
//			});
//			
//			var node = $("#geoTree").dynatree("getRoot");
//			node.sortChildren(cmp, true);
//			$("#geoTree").dynatree("getTree").reload();
//		}
//	});
//	
//	 $scope.toggleSelect = function(){
//	      $("#geoTree").dynatree("getRoot").visit(function(node){
//	        node.toggleSelect();
//	      });
//	 };
//	 
//	$scope.deSelectAll = function(){
//      $("#geoTree").dynatree("getRoot").visit(function(node){
//        node.select(false);
//      });
//    };
//    
//    $scope.selectAll = function(){
//    	$("#geoTree").dynatree("getRoot").visit(function(node){
//    		node.select(true);
//    	});
//    };
//    
//     var cmp = function(a, b) {
//        a = a.data.title;
//        b = b.data.title;
//        return a > b ? 1 : a < b ? -1 : 0;
//     };
});