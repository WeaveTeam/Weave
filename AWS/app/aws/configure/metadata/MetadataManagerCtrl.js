angular.module('aws.configure.metadata', []).controller("MetadataManagerCtrl", function($scope, queryService){			

	var treeData = [];
	$scope.myData = [];
//	$scope.maxTasks;
//	$scope.progressValue = 0;
	$scope.selectedDataTableId;//datatable selected by the user
    $scope.fileUpload;
    
    $scope.queryService = queryService;
    
    //generated when the dynatree directive loads
	$scope.generateTree = function(element) {
		queryService.getDataTableList(true).then(function(dataTableList) {
			for (var i = 0; i < dataTableList.length; i++) {
				dataTable = dataTableList[i];
				treeNode = { title: dataTable.title, key : dataTable.id,
						children : [], isFolder : true
				};

				(function(treeNode, i, end) {
					queryService.getDataColumnsEntitiesFromId(dataTable.id, true).then(function(dataColumns) {
						var children = [];
						for(var j in dataColumns) {
							dataColumn = dataColumns[j];
							children.push({ title : dataColumn.title, key : dataColumn.id });
						}
						treeNode.children = children;
						treeData.push(treeNode);
						if( treeData.length == end) {
							$(element).dynatree({
								minExpandLevel: 1,
								children : treeData,
								keyBoard : true,
								onPostInit: function(isReloading, isError) {
									this.reactivate();
								},
								onActivate: function(node) {
									$scope.selectedDataTableId = node.data.key;
									getColumnMetadata(node.data.key);//getting the metadata for a single column
								},
								debugLevel: 0
							});
							var node = $(element).dynatree("getRoot");
						    // node.sortChildren(cmp, true);
						}
					});
				})(treeNode, i, dataTableList.length);
			}
		});
	};

	var cmp = function(a, b) {
		key1 = a.data.key;
		key2 = b.data.key;
		return key1 > key2 ? 1 : key1 < key2 ? -1 : 0;
	};
	/**
	 * retrieves the metadata for a single column
	 * */
	var getColumnMetadata = function (id) {
		aws.queryService('/WeaveServices/DataService', "getEntitiesById", [id], function (result){
			var metadata = result[0];
			if(metadata.hasOwnProperty("publicMetadata")) {
				if(metadata.publicMetadata.hasOwnProperty("aws_metadata")) {
					var data = [];
					var aws_metadata = angular.fromJson(metadata.publicMetadata.aws_metadata);//converts the json string into an object
					data = convertToTableFormat(aws_metadata);//to use in the grid
					setMyData(data);
				} else {
					setMyData([]);
				}
			} 
		});
	};

	/**
	 * function that converts a aws-metadata json object into an array of objects that look like this { property:
	 * 																	 								value : }
	 * for using in the grid
	 * */
	var convertToTableFormat = function(aws_metadata) {
		var data = [];
		for (var key in aws_metadata) {
			data.push({property : key, value : aws_metadata[key] });
		}
		return data;
	};
	
	
	/**
	 * function that converts a object { property: , value : } into an aws_metadata json object
	 * for updating to the server
	 * */
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
	 
	 //for populating the grid
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

//	 $scope.$watch('progressValue', function(){
//		 console.log("in watch progress value", $scope.progressValue);
//		if($scope.progressValue == $scope.maxTasks) {
//			setTimeout(function() {
//				$scope.inProgress = false;
//				$scope.progressValue = 0;
//				$scope.$apply();
//			}, 50);
//		} else {
//			$scope.inProgress = true;
//		}
//	 });

	 $scope.$on('ngGridEventEndCellEdit', function(){
		 updateMetadata($scope.myData);
	 });

	 /**
	  * this function is called whenever the user adds or deletes a column metadata property
	  * function converts an object into a json string to send to server
	  */
	 var updateMetadata = function(metadata) {
		 var jsonaws_metadata = angular.toJson(convertToMetadataFormat(metadata));
		 queryService.updateEntity($scope.queryService.user, $scope.queryService.password, $scope.selectedDataTableId, { 
																								publicMetadata : { aws_metadata : jsonaws_metadata }
																							  }
		 ).then(function() {
     		 $scope.maxTasks = 100;
			 $scope.progressValue = 100;
		 });
	 };
	 
	 /**
	  * Editing
	  * function calls for editing a column metadata property
	  */
	 $scope.addNewRow = function () {
		 $scope.myData.push({property: 'Property Name', value: 'Value'});
		 updateMetadata($scope.myData);
	 };

	 $scope.removeRow = function() {
		 var index = $scope.myData.indexOf($scope.gridOptions.selectedItems[0]);
	     $scope.myData.splice(index, 1);
	     updateMetadata($scope.myData);
	 };
	 
	 

	 //refreshing the hierarchy
	$scope.refresh = function(element) {
		$("#tree").dynatree("getTree").reload();
		var node = $("#tree").dynatree("getRoot");
	    node.sortChildren(cmp, true);
	};
    
})
.controller("MetadataCtrl", function($scope, queryService){})

/*
 *applies metadata standards defined by user in a csv to the selected datatable 
 *updates the aws-metadata property of columns in a datatable 
 */
.controller("MetadataFileController", function ($scope, queryService){
	$scope.maxTasks;
	$scope.progressValue = 0;
	
	$scope.metadataUploaded = {
			file : {
				filename : "",
				content :""
			}
	};
	
	$scope.$watch('metadataUploaded.file', function(n, o) {
		if($scope.metadataUploaded.file.content){
			console.log("content", $scope.metadataUploaded.file.content);
        	  //metadata file(.csv) uploaded by the user is converted to update the columns
            var metadataArray = queryService.CSVToArray($scope.metadataUploaded.file.content);
            
    	  if($scope.selectedDataTableId) {//works only if a selection is made
    		  queryService.getDataColumnsEntitiesFromId($scope.selectedDataTableId, true).then(function(columns) {
    			 // console.log("columns", columns);
    			  if(columns.length) {//works only if a datatable that contains column children is selected, will not work if a column is selected
	    				  var end = columns.length;
	    				 // $scope.maxTasks = end;
	    				  
        				  for (var i = 1; i < metadataArray.length; i++) {//starting the loop from index 1 to avoid headers
        						var title = metadataArray[i][0];//gets the title of a single column
        						
        						var metadata = metadataArray[i][1];//gets the metadata to be updated per column
        						
        						//$scope.progressValue = 0;
        						//console.log("scope", $scope);
        						console.log("maxtasks", $scope.maxTasks);
        						var id;
        						for(var j = 0; j < columns.length; j++) {
        							if(columns[j].title == title) {
        								id = columns[j].id;
        								break; // we assume there is only one match
        							}
        						}
	        					if(id) {
	        								//TODO handle columns with missing metadata
	        								if(!(angular.isUndefined(metadata)))//if a particular column does not have metadata
	        									metadata = metadata.replace(/\s/g, '');
	        								
	        								//console.log("progress value before", $scope.progressValue);
	        								//updating the column metadata(adding the aws_metadata property to the public metadata) on the server 
//	        								queryService.updateEntity($scope.queryService.user, $scope.queryService.password, id, {publicMetadata :{ 
//	        																												aws_metadata : metadata
//	        																											 }
//	        																							}
//		        							 ).then(function() {
//		        								 $scope.progressValue++;
//		        							 });								
	        							}
							 }
        			  } else {
        				  //if a column is selected
        				  console.log("selected entity is not a table or table does not contain any columns.");
        			  }
			  });
    	  } else {
					console.log("no selected tables");
    	  		};

        }

      }, true);
	
	 $scope.$watch('progressValue', function(){
		 console.log("in watch progress value", $scope.progressValue);
//		if($scope.progressValue == $scope.maxTasks) {
//			setTimeout(function() {
//				$scope.inProgress = false;
//				$scope.progressValue = 0;
//				$scope.$apply();
//			}, 50);
//		} else {
//			$scope.inProgress = true;
//		}
	 });
});		


angular.module('aws.configure.metadata').directive('dynatree', function() {
	return {
        link: function(scope, element, attrs) {
        	scope.generateTree(element);
        }
   };	
});