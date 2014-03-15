angular.module('aws.configure.metadata', []).controller("MetadataManagerCtrl", function($scope, queryService){			
	
	var treeData = [];
	$scope.myData = [];
	$scope.maxTasks = 100;
	$scope.progressValue = 0;
	$scope.selectedColumnId;
	
	var generateTree = function() {
		queryService.getDataTableList().then(function(dataTableList) {
			for (var i = 0; i < dataTableList.length; i++) {
				dataTable = dataTableList[i];
				treeNode = { title: dataTable.title, key : dataTable.id,
						children : [], isFolder : true
				};
				
				(function(treeNode, i, end) {
					queryService.getDataColumnsEntitiesFromId(dataTable.id).then(function(dataColumns) {
						var children = [];
						for(var j in dataColumns) {
							dataColumn = dataColumns[j];
							children.push({ title : dataColumn.publicMetadata.title, key : dataColumn.id });
						}
						treeNode.children = children;
						treeData.push(treeNode);
						console.log("refresh");
						if( treeData.length == end) {
							$("#tree").dynatree({
								minExpandLevel: 1,
								children : treeData,
								keyBoard : true,
								onPostInit: function(isReloading, isError) {
									this.reactivate();
								},
								onActivate: function(node) {
									$scope.selectedColumnId = node.data.key;
									getColumnMetadata(node.data.key);
								},
								debugLevel: 0
							});
						}
					});
				})(treeNode, i, dataTableList.length);
			}
		});
	};
	
	generateTree();

	var getColumnMetadata = function (id) {
		aws.DataClient.getDataColumnEntities(id, function(result) {
			var metadata = result[0];
			if(metadata.hasOwnProperty("publicMetadata")) {
				if(metadata.publicMetadata.hasOwnProperty("aws_metadata")) {
					var data = [];
					var aws_metadata = angular.fromJson(metadata.publicMetadata.aws_metadata);
					data = convertToTableFormat(aws_metadata);
					setMyData(data);
				} else {
					setMyData([]);
				}
			} 
		});
	};
	
	var convertToTableFormat = function(aws_metadata) {
		var data = [];
		for (var key in aws_metadata) {
			data.push({property : key, value : aws_metadata[key] });
		}
		return data;
	};
	
	var convertToMetadataFormat = function(tableData) {
		var aws_metadata = {};
		for (var i in tableData) {
			aws_metadata[tableData[i].property] = tableData[i].value;
		}
		return aws_metadata;
	};
	
	 var setMyData = function(data) {
		  $scope.myData = data;
		  $scope.$apply();
	 };
	 $scope.selectedItems = [];
	 
	 $scope.gridOptions = { 
	        data: 'myData',
	        enableRowSelection: true,
	        enableCellEdit: true,
	        columnDefs: [{field: 'property', displayName: 'Property', enableCellEdit: true}, 
	                     {field:'value', displayName:'Value', enableCellEdit: true}],
	        multiSelect : false,
	        selectedItems : $scope.selectedItems
	                     
	 };
	 
	 $scope.addNewRow = function () {
		 $scope.myData.push({property: 'Property Name', value: 'Value'});
		 updateMetadata($scope.myData);
	 };
	 
	 $scope.removeRow = function() {
		 var index = $scope.myData.indexOf($scope.gridOptions.selectedItems[0]);
	     $scope.myData.splice(0, 1);
	     updateMetadata($scope.myData);
	 };
	 
	 $scope.$watch('progressValue', function(){
		if($scope.progressValue == $scope.maxTasks) {
			setTimeout(function() {
				$scope.inProgress = false;
				$scope.progressValue = 0;
				$scope.$apply();
			}, 50);
		} else {
			$scope.inProgress = true;
		}
	 });
	 
	 $scope.$on('ngGridEventEndCellEdit', function(){
		 updateMetadata($scope.myData);
	 });
	 
	 var updateMetadata = function(metadata) {
		 var jsonaws_metadata = angular.toJson(convertToMetadataFormat(metadata));
		 queryService.updateEntity("mysql", 
			"pass", 
			$scope.selectedColumnId, { 
										publicMetadata : { 
															aws_metadata : jsonaws_metadata 
														}
										}
		 ).then(function() {
     		 $scope.maxTasks = 100;
			 $scope.progressValue = 100;
		 });
	 };
	 
	$scope.refresh = function() {
		console.log("refresh");
		generateTree();
	};
	
	$scope.importQueryObject = function() {
	
	};
			
	$scope.$on('fileUploaded', function(e) {
          $scope.$safeApply(function() {
        	  var metadataArray = queryService.CSVToArray(e.targetScope.file);
        	  if($scope.selectedColumnId) {
        		  aws.DataClient.getEntityChildIds($scope.selectedColumnId, function(idsArray) {
        			  aws.DataClient.getDataColumnEntities(idsArray, function(columns) {
            			  if(columns.length) {
            				  for (var i = 1; i < metadataArray.length; i++) {
            					  	var metadata = metadataArray[i][1];
            						var title = metadataArray[i][0];
            						$scope.progressValue = 0;
            						var end = columns.length;
            						$scope.maxTasks = end;
            						var id;
            						for(var j = 0; j < columns.length; j++) {
            							if(columns[j].publicMetadata.title == title) {
            								id = columns[j].id;
            								break; // we assume there is only one match
            							}
            						}
    	        					if(id) {
    	        						queryService.updateEntity("mysql", 
    	        								"pass", 
    	        								 id, { 
    	        															publicMetadata : { 
    	        																				aws_metadata : metadata.replace(/\s/g, '')
    	        																			}
    	        															}
    	        							 ).then(function() {
    	        								 $scope.progressValue++;
    	        							 });								
    	        					}
    							 }
            			  } else {
            				  console.log("selected entity is not a table or table does not contain any columns.");
            			  }
        			  });
        		  });
        	  } else {
  					console.log("no selected tables");
        	  };
            });
	});
});