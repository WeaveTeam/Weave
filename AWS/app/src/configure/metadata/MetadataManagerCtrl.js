var metadataModule = angular.module('aws.configure.metadata', []);

// SOURCE: from stack overflow : http://stackoverflow.com/questions/25531961/angularjs-bootstrap-progressbar-max-changing
//adding a decorator that encapsulates the progressbar and bar directives provided by ui-bootstrap
metadataModule.config(function($provide){
	var progressDecorator = function($delegate){//$delegate is the original service instance which is decorated
		var directive = $delegate[0];
		var compile = directive.compile;
		var link = directive.link;
		
		directive.compile = function(){
			compile.apply(this,arguments);
			
			return function(scope, elem, attr, ctrl){
				link.apply(this,arguments);
				
				if(angular.isDefined(attr.dynamicMax)){
					attr.$observe('dynamicMax', function(max) {
			              scope.max = max;
		              scope.percent = +(100 * scope.value / max).toFixed(2);
			        }); 
			}
			};
		};//end of compile function
		
		return $delegate;
	};//end of progressIndicator;
	
	//the decorator function decorates the given service while instantiating it and returns the decorated service instance
	$provide.decorator('progressbarDirective', progressDecorator);
    $provide.decorator('barDirective', progressDecorator);
	
})

.controller("MetadataManagerCtrl", function($scope, queryService, authenticationService, runQueryService, dataServiceURL, errorLogService, $rootScope){			

	var treeData = [];
	$scope.myData = [];
//	$scope.maxTasks;
//	$scope.progressValue = 0;
	$scope.selectedDataTableId;//datatable selected by the user
    $scope.fileUpload;
    
    $scope.queryService = queryService;
    $scope.authenticationService = authenticationService;
    
    //generated when the dynatree directive loads
	$scope.generateTree = function(element) {
		queryService.getDataTableList(true).then(function(dataTableList) {
			for (var i = 0; i < dataTableList.length; i++) {
				dataTable = dataTableList[i];
				treeNode = { title: dataTable.title, key : dataTable.id,
						children : [], isFolder : true, isLazy : true
				};
				treeData.push(treeNode);
				if( treeData.length == dataTableList.length) {
					$(element).dynatree({
						minExpandLevel: 1,
						children : treeData,
						keyBoard : true,
						onPostInit: function(isReloading, isError) {
							this.reactivate();
						},
						onActivate: function(node) {
							//handling nodes when tables TODO check if handling is done correctly
							if(!node.data.metadata)
								{
									$scope.selectedDataTableId = parseInt(node.data.key);
									//clears the grid when nodes are selected
									$scope.myData= [];
									$scope.$apply();//TODO check if this is the right thing to do
								}

							//handle when node is a column
							if(node.data.metadata){
								$scope.selectedDataTableId = node.data.id;
								getColumnMetadata(node.data);
							}
						},
						//******************************************lazy loading*****************************************************
						onLazyRead : function(node){
							 var request = {
									 jsonrpc: "2.0",
									 id: "no_id",
									 method : "getEntityChildIds",
									 params : [node.data.key]
							 };
						      
							node.appendAjax({
								url : dataServiceURL,
								data : JSON.stringify(request),
								type: "POST",
								dataType : "json",
								error : function(node, XMLHttpRequest, textStatus, errorThrown)//refer to dynatree documentation
											{
												errorLogService.openErrorLog(errorThrown);
											},
								success : function(node, status, jqxhr)//this success function is different from the regular ajax success (modified by dynatree)
											{
												if(status.error)
													errorLogService.openErrorLog(status.error.message);
													
												if(status.result)
													{
														node.removeChildren();
														var list = status.result;// the actual result from ajax
														
														var columnChildren= [];
														//as soon as ids are returned retrieve their metadata
														runQueryService.queryRequest(dataServiceURL, 'getEntitiesById', [list], function(columnsWithMetadata){
															for(var i=0, l=columnsWithMetadata.length; i<l; i++){
																var singleColumn = columnsWithMetadata[i];
										                        columnChildren.push({title: singleColumn.publicMetadata.title,
										                            	id: singleColumn.id,
										                            	metadata: singleColumn.publicMetadata,
										                            	addClass : "custom1",// for a particular kind of document representation
										                            	focus: true});
										                    }
										                    node.setLazyNodeStatus(DTNodeStatus_Ok);//look at dynatree documentation
										                    node.addChild(columnChildren);
														});
													}
												
											}
							});
						},
						debugLevel: 0
					});
				}
				
//*********************************************************************************************unlazy loading********************************************************				
//				(function(treeNode, i, end) {
//					queryService.getDataColumnsEntitiesFromId(dataTable.id, true).then(function(dataColumns) {
//						var children = [];
//						for(var j in dataColumns) {
//							dataColumn = dataColumns[j];
//							children.push({ title : dataColumn.title, key : dataColumn.id });
//						}
//						treeNode.children = children;
//						treeData.push(treeNode);
//						if( treeData.length == end) {
//							$(element).dynatree({
//								minExpandLevel: 1,
//								children : treeData,
//								keyBoard : true,
//								onPostInit: function(isReloading, isError) {
//									this.reactivate();
//								},
//								onActivate: function(node) {
//									$scope.selectedDataTableId = node.data.key;
//									getColumnMetadata(node.data.key);//getting the metadata for a single column
//								},
//								debugLevel: 0
//							});
//							var node = $(element).dynatree("getRoot");
//						    // node.sortChildren(cmp, true);
//						}
//					});
//				})(treeNode, i, dataTableList.length);
//*********************************************************************************************unlazy loading********************************************************
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
	var getColumnMetadata = function (columnObject) {
		if(columnObject && columnObject.id) {
			queryService.getEntitiesById([columnObject.id], true).then(function(entity) {
					entity = entity[0];
					if(entity.publicMetadata.hasOwnProperty('aws_metadata')) {
						var data = [];
						var aws_metadata = angular.fromJson(entity.publicMetadata.aws_metadata);//converts the json string into an object
						data = convertToTableFormat(aws_metadata);//to use in the grid
						$scope.myData = data;
						$rootScope.$safeApply();
					}
			});
		} else {
				setMyData([]);
		}
		//*********************used to retrieve metadata from the server******************************
		//aws.queryService('/WeaveServices/DataService', "getEntitiesById", [[ids]], function (result){
			//var metadata = result[0];
//			if(metadata.hasOwnProperty("publicMetadata")) {
//				if(metadata.publicMetadata.hasOwnProperty("aws_metadata")) {
//					var data = [];
//					var aws_metadata = angular.fromJson(metadata.publicMetadata.aws_metadata);//converts the json string into an object
//					data = convertToTableFormat(aws_metadata);//to use in the grid
//					setMyData(data);
//				} else {
//					setMyData([]);
//				}
//			} 
		//});
	};

	/**
	 * function that converts a aws-metadata json object into an array of objects that look like this { property:
	 * 																	 								value : }
	 * for using in the grid
	 * */
	var convertToTableFormat = function(aws_metadata) {
		var data = [];
		for (var key in aws_metadata) {
			data.push({property : key, value : angular.toJson(aws_metadata[key]) });
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
			aws_metadata[tableData[i].property] = angular.fromJson(tableData[i].value);
		}
		return aws_metadata;
	};

	 var setMyData = function(data) {
		  $scope.myData = data;
		  $rootScope.$safeApply();
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

	 $scope.$on('ngGridEventEndCellEdit', function(){
		 updateMetadata($scope.myData);
	 });

	 /**
	  * this function is called whenever the user adds or deletes a column metadata property
	  * function converts an object into a json string to send to server
	  */
	 var updateMetadata = function(metadata) {
		 var jsonaws_metadata = angular.toJson(convertToMetadataFormat(metadata));
		 if(angular.isDefined($scope.selectedDataTableId))
			 {
						 queryService.updateEntity($scope.authenticationService.user, 
				 				   $scope.authenticationService.password, 
				 				   $scope.selectedDataTableId, 
				 				   { 
										publicMetadata : { aws_metadata : jsonaws_metadata }
				 				   }).then(function() {
				 					   	//$scope.maxTasks = 100;
				 					   //$scope.progressValue = 100;
				 				   });
			 }
		 
		 alert("Metadata Updated for id : " + $scope.selectedDataTableId);
	 };
	 
	 /**
	  * Editing
	  * function calls for editing a column metadata property
	  */
	 //adding
	 $scope.addNewRow = function () {
		 $scope.myData.push({property: 'Property Name', value: 'Value'});
		 updateMetadata($scope.myData);
	 };

	 //deleting
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

/*
 *applies metadata standards defined by user in a csv to the selected datatable 
 *updates the aws-metadata property of columns in a datatable 
 */
.controller("MetadataFileController", function ($scope, queryService, authenticationService, errorLogService){
	$scope.maxTasks= 0;
	$scope.progressValue = 0;
	
	//object representation of the metadata csv uploaded 
	$scope.metadataUploaded = {
			file : {
				filename : "",
				content :""
			}
	};
	
	$scope.$watch('metadataUploaded.file', function(n, o) {
		if($scope.metadataUploaded.file.content){
			
	        	  //metadata file(.csv) uploaded by the user is converted to update the columns
	           var metadataArray = queryService.CSVToArray($scope.metadataUploaded.file.content);
	            
	    	  if($scope.selectedDataTableId) {//works only if a selection is made
	    		  queryService.getDataColumnsEntitiesFromId($scope.selectedDataTableId, true).then(function(columns) {
	    			 // console.log("columns", columns);
	    			  if(columns.length) {//works only if a datatable that contains column children is selected, will not work if a column is selected
		    				  var end = columns.length;
		    				  $scope.maxTasks = end;
		    				  
	        				  for (var i = 1; i < metadataArray.length; i++) {//starting the loop from index 1 to avoid headers
	        						var title = metadataArray[i][0];//gets the title of a single column
	        						
	        						var metadata = metadataArray[i][1];//gets the metadata to be updated per column
	        						
	        						//$scope.progressValue = 0;
	        						//console.log("scope", $scope);
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
		        									metadata = metadata;
		        								
		        								
		        								//updating the column metadata(adding the aws_metadata property to the public metadata) on the server 
		        								queryService.updateEntity(authenticationService.user, authenticationService.password, id, {publicMetadata :{ 
		        																												aws_metadata : metadata
		        																											 }
		        																							}
			        							 ).then(function() {
			        								 $scope.progressValue++;
			        							 });								
		        							}
								 }
	        			  } else {
	        				  //if a column is selected
	        				  errorLogService.openErrorLog("Selected entity is not a table or table does not contain any columns.");
	        				  console.log("selected entity is not a table or table does not contain any columns.");
	        			  }
				  });
	    	  } else {
	    		  		errorLogService.openErrorLog("no selected tables");
						console.log("no selected tables");
	    	  		};
        }

      }, true);
	
	//watch expression to reset the progress bar after the task has been completed
	 $scope.$watch('progressValue', function(){
		 //console.log("progress", $scope.progressValue);
		if($scope.progressValue == $scope.maxTasks) {
			//console.log("equal");
			setTimeout(function() {
				//resetting variables
				$scope.inProgress = false;
				$scope.progressValue = 0;
				$scope.maxTasks = 0;
				//resetting the uploaded file (because if we repeated upload same file)
				$scope.metadataUploaded.file.filename = "";
				$scope.metadataUploaded.file.content = "";
				
				$scope.$apply();
			}, 5000);
		} else {
			//console.log("not equal");
			$scope.inProgress = true;
		}
	 });
});		


angular.module('aws.configure.metadata').directive('dynatree', function() {
	return {
        link: function(scope, element, attrs) {
        	scope.generateTree(element);
        }
   };	
});