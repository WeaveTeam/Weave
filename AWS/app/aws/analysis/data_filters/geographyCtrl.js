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
		return [queryService.dataObject.geographyMetadata,
		         							stateValueKey,
		         							stateLabelKey,
		         							countyValueKey,
		         							countyLabelKey,
		         							metadataTableTitle];
	}, function() {
		
		geographyMetadata = queryService.dataObject.geographyMetadata;
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

	$scope.$watchCollection(function() {

		return [queryService.queryObject.GeographyFilter.stateColumn, queryService.queryObject.GeographyFilter.countyColumn, processedMetadata];
		
	}, function() {
		var stateColumn = queryService.queryObject.GeographyFilter.stateColumn;
		var countyColumn = queryService.queryObject.GeographyFilter.countyColumn;
		if(stateColumn != undefined && countyColumn != undefined && processedMetadata != undefined) {
			if(stateColumn != "" && countyColumn != "" && processedMetadata.length) {
				//once the state, county column have been filled AND their metadata is available, construct the tree data structure
				geoTreeData = createGeoTreeData(processedMetadata);
			}
		}
	});
	
	//create the data structure to be used by the dynatree library
	var createGeoTreeData = function(metadata) {
		var treeData = [];
		for(var i in metadata) {//looping through state metadata
			treeData[i] = { title : metadata[i].label,
							key : metadata[i].value, 
							isFolder : true,  
							children : [] };
			
			for(var j in metadata[i].counties) {//looping through counties
				treeData[i].children.push({ title : metadata[i].counties[j].label, 
											key : metadata[i].counties[j].value });
			}//end of looping through counties
		}//end of looping through state metadata
		return treeData;
	};
	
	$scope.$watch(function() {
		return geoTreeData;//once the data strcuture has been created, draw the dynatree using that data structure
	}, function(){
		if(geoTreeData) {
			$("#geoTree").dynatree({
				minExpandLevel: 1,
				checkbox : true,
				selectMode : 3,
				children : geoTreeData,
				keyBoard : true,
				onSelect: function(select, node) {
					var treeSelection = {};
					var root = $("#geoTree").dynatree("getRoot");//represents all the states in the country
					
					for (var i = 0; i < root.childList.length; i++) {//looping through all states
						var state = root.childList[i];//picking up a single state
						
						for(var j = 0; j < state.childList.length; j++) {//looping through a single state
							var county = state.childList[j];//picking up a single county
							
							if(county.bSelected) {//if county is selected
								
								var countyKey = county.data.key;//get its key
								var countyObj = {};
								countyObj[countyKey] = county.data.title;//store title
								
								if(!treeSelection[state.data.key])//if the state object has not been created, create it
								{
									treeSelection[state.data.key] = {};
									treeSelection[state.data.key].label = state.data.title;
									
									treeSelection[state.data.key].counties = [countyObj];//add the county
									
								} else {
									treeSelection[state.data.key].counties.push(countyObj);//simply add the county
								}
							}
							
						}//end of looping through a single state
						
						
					}//end of looping through all states
					
					//setting the filters
					queryService.queryObject.GeographyFilter.filters = treeSelection;
					
				},
				onKeydown: function(node, event) {
					if( event.which == 32 ) {
						node.toggleSelect();
						return false;
					}
				},
				cookieId: "geo-tree",
				idPrefix: "geo-tree-",
				debugLevel: 0
			});
			
			var node = $("#geoTree").dynatree("getRoot");
			node.sortChildren(cmp, true);
			$("#geoTree").dynatree("getTree").reload();
		}
	});//end of dynatree construction
	
	 $scope.toggleSelect = function(){
	      $("#geoTree").dynatree("getRoot").visit(function(node){
	        node.toggleSelect();
	      });
	 };
	 
	$scope.deSelectAll = function(){
      $("#geoTree").dynatree("getRoot").visit(function(node){
        node.select(false);
      });
    };
    
    $scope.selectAll = function(){
    	$("#geoTree").dynatree("getRoot").visit(function(node){
    		node.select(true);
    	});
    };
    
     var cmp = function(a, b) {
        a = a.data.title;
        b = b.data.title;
        return a > b ? 1 : a < b ? -1 : 0;
     };
});