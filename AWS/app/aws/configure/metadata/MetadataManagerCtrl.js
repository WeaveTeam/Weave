angular.module('aws.configure.metadata', []).controller("MetadataManagerCtrl", function($scope, queryService){			
	
	var treeData = [];

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
						if( treeData.length == end) {
							$("#tree").dynatree({
								minExpandLevel: 1,
								children : treeData,
								onPostInit: function(isReloading, isError) {
									this.reactivate();
								},
								onActivate: function(node) {
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
					for (key in aws_metadata) {
						data.push({property : key, value : aws_metadata[key] });
					}
					setMyData(data);
				}
			}
		});
	};
	 $scope.myData = [{property:'property1', value: 'value1'}];
	 
	 var setMyData = function(data) {
		 console.log($scope.myData);
		  $scope.myData = data;
		  $scope.$apply();
	 };
	 $scope.gridOptions = { 
	        data: 'myData',
	        enableCellSelection: true,
	        enableRowSelection: false,
	        enableCellEditOnFocus: true,
	        columnDefs: [{field: 'property', displayName: 'Property', enableCellEdit: false}, 
	                     {field:'value', displayName:'Value', enableCellEdit: true}]
	 };

	 $scope.$watch(function() {
			return queryService.dataObject.columns;
		}, function(){
			if(queryService.dataObject.columns) {
				$scope.columnList = $.map(queryService.dataObject.columns, function(item){
						return {
							id : item.id,
							title : item.publicMetadata.title,
							aws_metadata : item.publicMetadata.aws_metadata
						};
				});
			}					
		});
	 

		$scope.$watch('dataTable', function() {
			if($scope.dataTable){
				queryService.getDataColumnsEntitiesFromId($scope.dataTable.id, true);
				$('#log').html('');
			};
		});
		
		$scope.$watch('columnSelected', function(){
			if($scope.columnSelected){
				$scope.aws_metadataTextArea = JSON.stringify(JSON.parse($scope.columnSelected.aws_metadata), null, 2);
				$('#log').html('');
			} else {
				$scope.aws_metadataTextArea = "";
			}
		});
		
		$scope.columnList = [];
		
		$scope.showUpload = function() {
			console.log("clicked");
			$scope.uploadScript = true;
			$scope.textScript = false;
			$scope.saveButton = true;
		};
		$scope.showTextArea = function() {
			$scope.uploadScript = false;
			$scope.textScript = true;
			$scope.saveButton = true;
		};
		

		$scope.update = function() {
			queryService.updateEntity("mysql", 
										"pass", 
										$scope.columnSelected.id, { 
																	publicMetadata : { 
																						aws_metadata : JSON.stringify(JSON.parse($scope.aws_metadataTextArea)) 
																					}
																	}
									 ).then(function() {
										$scope.refresh();
										$('#log').html(" metadata updated...");
									 });
		}; 
		
		$scope.refresh = function() {
			generateTree();
		};
		
		$scope.updateFromCSV = function() {
			var metadataArray = queryService.CSVToArray($scope.aws_metadataCSV);
			
			if($scope.dataTable) {
				for (var i = 1; i < metadataArray.length; i++) {
					var metadata = metadataArray[i][1];
					var title = metadataArray[i][0];
					var progress = 0;
					var end = $scope.columnList.length;
					var id = -1;
					var j = 0;
					for(j = 0; j < $scope.columnList.length; j++) {
						if($scope.columnList[j].title == title) {
							id = $scope.columnList[j].id;
							break; // we assume there is only one match
						}
					}
					
					if(id != -1) {
						queryService.updateEntity("mysql", 
								"pass", 
								 id, { 
															publicMetadata : { 
																				aws_metadata : metadata.replace(/\s/g, '')
																			}
															}
							 ).then(function() {
								 progress++;
								 $('#log').html(progress);
								 $('#log').append(" of ");
								 $('#log').append(end);
								 $('#log').append(" metadata updated...");
							 });								
					}
				}						
			} else {
				$('#log').html("select a data table..");
			}
		};
});