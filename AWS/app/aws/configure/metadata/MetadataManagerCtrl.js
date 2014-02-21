angular.module('aws.configure.metadata', [])
			
			.controller("MetadataManagerCtrl", function($scope, metadataManagerService){
				
				var dataTableList = [];
				
				queryService.getDataTableList();
				
				$scope.$watch(function() {
					return queryService.dataObject.dataTableList;
				}, function() {
					$scope.dataTableList = queryService.dataObject.dataTableList;
				});
				
				$scope.columnList = [];
				
				$scope.$watch('dataTable', function() {
					if($scope.dataTable){
						queryService.getDataColumnsEntitiesFromId($scope.dataTable.id, true);
						$('#log').html('');
					};
				});
				
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
				
				$scope.$watch('columnSelected', function(){
					if($scope.columnSelected){
						$scope.aws_metadataTextArea = JSON.stringify(JSON.parse($scope.columnSelected.aws_metadata), null, 2);
						$('#log').html('');
					} else {
						$scope.aws_metadataTextArea = "";
					}
				})
				
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
				} 
				
				$scope.refresh = function() {
					queryService.getDataColumnsEntitiesFromId($scope.dataTable.id, true);
					$scope.aws_metadataTextArea = "";
				}
				
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
				}
			});