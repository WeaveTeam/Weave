var scriptUploaded;
var scriptModule = angular.module('aws.configure.script', ['ngGrid', 'mk.editablespan']);

var tryParseJSON = function(jsonString){
    try {
        var o = JSON.parse(jsonString);

        // Handle non-exception-throwing cases:
        // Neither JSON.parse(false) or JSON.parse(1234) throw errors, hence the type-checking,
        // but... JSON.parse(null) returns 'null', and typeof null === "object", 
        // so we must check for that, too.
        if (o && typeof o === "object" && o !== null) {
            return o;
        }
    }
    catch (e) { }

    return false;
};

scriptModule.controller("ScriptManagerCtrl", function($scope, $modal, scriptManagerService, queryService,authenticationService) {
	//needed for dynatree
	var scripts = [
	               { title : "R Scripts", children : [], isFolder : true },
	               
	               { title : "Stata Scripts", children : [], isFolder : true }
	               ];
	  //needed for population options in the metadata grid
	  $scope.inputTypes = ["column", "options", "boolean", "value", "multiColumns"];
	  $scope.columnTypes = ["", "all", "analytic", "geography", "indicator", "time", "by-variable"];
	  
	  
	  $scope.service = scriptManagerService;
	  $scope.queryService = queryService;
	  $scope.authenticationService = authenticationService;
	  $scope.script = {};
	  $scope.selectedScript;
	  $scope.scriptMetadata = {
			  inputs : [],
			  description : ""
	  };
	  $scope.script.content = "";
	  $scope.selectedRow = [];
	  $scope.editScript = false;
	  $scope.editDesc = false;
	  $scope.status = "";
	  $scope.statusColor = "#3276B1";
	  $scope.jsonbtn = "json";
	  $scope.EditDone = "Edit";
	  $scope.EditDoneDesc = "Edit";
	  $scope.inputsAsString = "";

	  //creates the tree for scripts 
		$scope.generateTree = function(element) {
			
			scriptManagerService.getListOfRScripts().then(function(rScripts) {
				  
				  scriptManagerService.getListOfStataScripts().then(function(stataScripts){
					  scripts[0].children = rScripts;
					  scripts[1].children = stataScripts;
					  
						$(element).dynatree({
							minExpandLevel: 1,
							children : scripts,
							keyBoard : true,
							onPostInit: function(isReloading, isError) {
								this.reactivate();
							},
							onActivate: function(node) {
								//handle when node is a column
								if(!node.data.isFolder) {
									$scope.selectedScript = node.data.title;
									$scope.$apply();
								}
							},
							debugLevel: 0
						});
			  });
		  	});
		};
		
	//data structure that populates the metadata grid
	  $scope.scriptMetadataGridOptions = {
			  data: 'scriptMetadata.inputs',
			  columnDefs : [{field : "param", displayName : "Parameter"},
		               {field :"type", displayName : "Type", enableCellEdit : false, cellTemplate : '<select style="vertical-align:middle;" ng-input="COL_FIELD" ng-model="COL_FIELD" ng-options="input for input in inputTypes" style="align:center"></select>'},
		               {field : "columnType", displayName : "Column Type", enableCellEdit : false, cellTemplate : '<select  ng-input="COL_FIELD" ng-if="scriptMetadata.inputs[row.rowIndex].type == &quot;column&quot" ng-model="COL_FIELD" ng-options="type for type in columnTypes" style="align:center"></select>'},
		               {field : "options", displayName : "Options"},
		               {field : "default", displayName : "Default"},
		               {field : "description", displayName : "Description"}],
			  multiSelect: false,
			  enableRowSelection: true,
			  keepLastSelected : false,
			  enableCellEditOnFocus: true,
			  enableCellEdit : true,
			  selectedItems : $scope.selectedRow,
			  enableSorting : false
	  };
	 
//********************************************************************Watches*******************************************************
	  //when a script is selected
	  $scope.$watch('selectedScript', function(newVal, oldVal) {
		  if(newVal) {
			  //retrieve its metadata
			  scriptManagerService.getScriptMetadata(newVal).then(function(result) {
				  $scope.scriptMetadata.description = result.description;
				  $scope.scriptMetadata.inputs = result.inputs;
			  }, function(error) {
				   // no metadata was found, so we create an empty metadata file
				  scriptManagerService.saveScriptMetadata($scope.selectedScript, "{}").then(function(result) { 
					  if(!result) {
						  $scope.statusColor = "red";
						  $scope.status = "Error saving script metadata";
					  }
				  });
			  });
			  //get the actual content of the script
			  scriptManagerService.getScript(newVal).then(function(result) {
				  $scope.script.content = result;
			  });
		  }
      });
	  //
	  $scope.$watchCollection('scriptMetadata.inputs', function() {
		    if($scope.scriptMetadata.inputs && $scope.selectedScript) {
		    	  //returns the metadata of a script if it already exists else creates a metadata data file
				  scriptManagerService.saveScriptMetadata($scope.selectedScript, angular.toJson($scope.scriptMetadata), true).then(function(result) { 
					  if(!result) {
						  $scope.statusColor = "red";
						  $scope.status = "Error creating new script metadata";
					  }
				  });
			  }
      });
	  
	  $scope.$on('ngGridEventEndCellEdit', function(){
		  if($scope.scriptMetadata.inputs && $scope.selectedScript) {
		    	//returns the metadata of a script if it already exists else creates a metadata data file
			 	for(var i in $scope.scriptMetadata.inputs) {
			 		var input = $scope.scriptMetadata.inputs[i];
			 		if(input && input.options)
			 		{
			 			test = tryParseJSON(input.options); // if the data is entered as a json array
			 			if(test) 
			 				input.options = tryParseJSON(input.options); // we jsonparse it
			 			if(!test && typeof input.options == 'string')
			 				input.options = input.options.split(','); // otherwise if it's a list we turn it into an array
			 		}
			 	}
				  scriptManagerService.saveScriptMetadata($scope.selectedScript, angular.toJson(angular.fromJson($scope.scriptMetadata), true)).then(function(result) { 
					  if(!result) {
						  $scope.statusColor = "red";
						  $scope.status = "Error saving script metadata";
					  }
				  });
			  }
		 });
	  
	  /*** two way binding ***/
//	  $scope.$watch('inputsAsString', function() {
//		  if($scope.inputsAsString) {
//			  $scope.scriptMetadata.inputs = angular.fromJson($scope.inputsAsString); 
//		  }
//	  });
//	  $scope.$watch('scriptMetadata.inputs', function () {
//		  if($scope.scriptMetadata.inputs) {
//			  $scope.inputsAsString = angular.toJson($scope.scriptMetadata.inputs, true); 
//		  }
//	  }, true);
	  /***********************/
	  
//***********************************************************************************************************************************
	  
	  
	  /***TEXT EDITING functions*******/
	  //this function permits a user to edit a script on the server 
	  $scope.toggleEdit = function() {
		$scope.editScript = !$scope.editScript;
		
		// every time editScript is turnOff, we should save the changes.
		if(!$scope.editScript) {
			$scope.EditDone = "Edit";
			if($scope.script.content && $scope.selectedScript) {
				scriptManagerService.saveScriptContent($scope.selectedScript,  $scope.script.content).then(function (result) {
					if(result) {
						console.log("script modified successfully");
					} else {
						$scope.statusColor = "red";
						 $scope.status = "Error saving script content";
					}
				});
			}
		} else {
			$scope.EditDone = "Done";
		}
	  };
	  //this function permits a user to edit script description on the server
	  $scope.toggleEditDesc = function() {
		  $scope.editDesc = !$scope.editDesc;
		  
		  // every time editScript is turnOff, we should save the changes.
		  if(!$scope.editDesc) {
			  $scope.EditDoneDesc = "Edit";
				if($scope.scriptMetadata.description && $scope.selectedScript) {
					scriptManagerService.saveScriptMetadata($scope.selectedScript, angular.toJson($scope.scriptMetadata, true)).then(function(result) { 
						 if(!result) {
							 $scope.statusColor = "red";
							 $scope.status = "Error saving script metadata";
						 }
					 });
				}
	  		} else {
	  			$scope.EditDoneDesc = "Done";
	  		}
	  };
	  
	  
	  $scope.toggleJsonView = function() {
		  $scope.viewasjson = !$scope.viewasjson;
		  if($scope.jsonbtn == "json")
		  {
			$scope.jsonbtn = "grid";  
		  } else {
			  $scope.jsonbtn = "json";
		  }
	  };
	  
	  
	  //script METADATA grid editing
	  $scope.addNewRow = function () {
		 if(!$scope.scriptMetadata.inputs)
			 $scope.scriptMetadata.inputs = [];
		 $scope.scriptMetadata.inputs.push({param: '...', type: ' ', columnType : ' ', options : ' ', description : '...'});
		 //so? do we add this object to the scriptMetadata json on the server??
	 };
	
	 $scope.removeRow = function() {
		 if($scope.viewasjson)
			 return;
		 if($scope.scriptMetadataGridOptions.selectedItems.length) {
			 var index = $scope.scriptMetadata.inputs.indexOf($scope.scriptMetadataGridOptions.selectedItems[0]);
			 $scope.scriptMetadata.inputs.splice(index, 1);
			 $scope.scriptMetadataGridOptions.selectAll(false);
		 }
	 };
	 
	 
	 
	//refreshing scripts
	  $scope.refreshScripts = function () {
	 	 //refreshing the hierarchy
 		scriptManagerService.getListOfRScripts().then(function(rScripts) {
		  scriptManagerService.getListOfStataScripts().then(function(stataScripts){
			  scripts[0].children = rScripts;
			  scripts[1].children = stataScripts;
			  $("#tree").dynatree("getTree").reload();
		  });
 		});
	  	
	  };
	  
	 //deleting scripts on the server
	 $scope.deteleScript = function () {
		 if($scope.selectedScript) {
			 console.log($scope.selectedScript);
			 scriptManagerService.deleteScript($scope.selectedScript).then(function(status) {
				 if(status) {
					 console.log("script deleted successfully");
					 $scope.selectedScript = "";
					 $scope.script.content = "";
					 $scope.scriptMetadata = {};
					 $scope.refreshScripts();
				 }
			 });
		 }
	 };
	 
	 //this is the modal for the wizard for creating and saving new scripts
    $scope.saveNewScript = function (content, metadata) {
    	var modal = $modal.open({
			 backdrop: false,
	         backdropClick: true,
	         dialogFade: true,
	         keyboard: true,
	         templateUrl: 'src/configure/script/uploadNewScript.html',
	         controller: 'AddScriptDialogInstanceCtrl'
		});
    	
    	modal.result.then(function() {
    		$scope.refreshScripts();
    	});
    };
   
    //this controller deals with the script wizard
}).controller('AddScriptDialogInstanceCtrl', function ($rootScope, $scope, $modalInstance, scriptManagerService) {
	  
	 $scope.fileName = "";
	 $scope.metadata = "";
	 $scope.validText = "";
	 $scope.isScriptValid = false;
	 $scope.isValidMetadata = true;
	 $scope.metaValidText = "";
	 
	 $scope.step = {
			 value : 1
	 };
	 
	 $scope.scriptUploaded = {
			 metadata : {
				 filename : "",
				 content : ""
			 },
			 script : {
				 filename : "",
				 content :  ""
			 }
	 };
	 $scope.metadataUploaded = {
			 content : ""
	 };
	
	 $scope.close = function () {
		 $modalInstance.close();
	 };
	 
	 $scope.uploadSuccessful = "na";
	 
	 $scope.$watch('scriptUploaded.metadata.content', function() {
		 if($scope.scriptUploaded.metadata.content) {
			 if(tryParseJSON($scope.scriptUploaded.metadata.content)) {
				 $scope.metadataUploaded = angular.fromJson($scope.scriptUploaded.metadata.content);
				 $scope.metaValidText = "";
				 $scope.isValidMetadata = true;
			 } else {
				 $scope.isValidMetadata = false;
				 $scope.metaValidText = "invalid json";
			 }
		 } else if ($scope.scriptUploaded.metadata.content == "") {
			 $scope.isValidMetadata = true;
			 $scope.metaValidText = "";
		 }
	 });
	 
	 $scope.scriptMetadataOptions = {
	      data: 'metadataUploaded.inputs',
		  columnDefs : [{field : "param", displayName : "Parameter"},
		               {field :"type", displayName : "Type"},
		               {field : "columnType", displayName : "Column Type"},
		               {field : "options", displayName : "Options"},
		               {field : "default", displayName : "Default"},
		               {field : "description", displayName : "Description"}],
			  multiSelect: false,
			  enableRowSelection: false,
			  enableCellEdit : false
	  };
	 
	$scope.$watch('scriptUploaded.script.filename', function () {
		
		if($scope.scriptUploaded.script.filename) {
			extension = $scope.scriptUploaded.script.filename.substr((Math.max(0, $scope.scriptUploaded.script.filename.lastIndexOf(".")) || Infinity) + 1);
			if(extension.toLowerCase() == "r" || extension.toLowerCase() == "do") {
				scriptManagerService.scriptExists($scope.scriptUploaded.script.filename).then(function(result) {
					if(result) {
						$scope.validText = "script already exists";
						$scope.isScriptValid = false;
					} else {
						$scope.validText = "";
						$scope.isScriptValid = true;
					}
				});
			} else {
				$scope.validText = "only .R or .do files are supported";
				$scope.isScriptValid = false;
			}
		} else {
			$scope.validText = "";
		}
	});
	$scope.$watch('step.value', function(n, o) { 
		if(n == 3) {
			var scriptName = "";
			var scriptContent = "";
			
			if($scope.scriptUploaded.script) {
				scriptName = $scope.scriptUploaded.script.filename;
				scriptContent = $scope.scriptUploaded.script.content;
			}
			var scriptMetadata = "";
			if($scope.scriptUploaded.metadata) {
				scriptMetadata = $scope.scriptUploaded.metadata.content;
			}
			// make sure we have the scriptname, the content and the metadata
			if(scriptName && scriptContent) {
				if(scriptMetadata) {
					scriptManagerService.uploadNewScript(scriptName, scriptContent, scriptMetadata).then(function(result) {
						if(result) {
							$scope.uploadSuccessful = "success";
						} else {
							$scope.uploadSuccessful = "failure";
						}
					});
					$scope.$broadcast('refreshScripts'); // tell the other controller to refresh the list of scripts
				} else {
					scriptManagerService.uploadNewScript(scriptName, scriptContent, null).then(function(result) {
						if(result) {
							$scope.uploadSuccessful = "success";
							$scope.metadataUploaded.description = "";
						} else {
							$scope.uploadSuccessful = "failure";
						}
					});
				}
			}
		} else if (n == 1) {
			$scope.isValidMetadata = true;
			$scope.uploadSuccessful = "na";
			if($scope.scriptUploaded.script.filename) {
				scriptManagerService.scriptExists($scope.scriptUploaded.script.filename).then(function(result) {
					if(result) {
						$scope.validText = "script already exists";
						$scope.isScriptValid = false;
					} else {
						$scope.validText = "";
						$scope.isScriptValid = true;
					}
				});
			}
		} else if (n == 2) {
			 if($scope.scriptUploaded.metadata.content) {
				 if(tryParseJSON($scope.scriptUploaded.metadata.content)) {
					 $scope.metadataUploaded = angular.fromJson($scope.scriptUploaded.metadata.content);
					 $scope.metaValidText = "";
					 $scope.isValidMetadata = true;
				 } else {
					 $scope.isValidMetadata = false;
					 $scope.metaValidText = "invalid json";
				 }
			 } else if ($scope.scriptUploaded.metadata.content == "") {
				 $scope.isValidMetadata = true;
				 $scope.metaValidText = "";
			 }
		}
	});
  });