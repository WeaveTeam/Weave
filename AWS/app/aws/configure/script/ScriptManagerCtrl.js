var scriptUploaded;
var scriptModule = angular.module('aws.configure.script', ['ngGrid', 'mk.editablespan']).controller("ScriptManagerCtrl", function($scope, $modal, scriptManagerService, queryService) {

	  $scope.service = scriptManagerService;
	  $scope.queryService = queryService;
	  $scope.script = {};
	  $scope.selectedScript = [];
	  $scope.scriptMetadata = {};
	  $scope.script.content = "";
	  $scope.selectedRow = [];
	  $scope.editScript = false;
	  $scope.status = "";
	  $scope.statusColor = "#3276B1";
	  $scope.jsonbtn = "json";
	  $scope.EditDone = "Edit";
	  $scope.inputsAsString = "";
	  
	  $scope.rScriptListOptions = {
			  data: 'rScripts',
			  columnDefs: [{field: 'Script', displayName: ''}],
			  selectedItems: $scope.selectedScript,
			  multiSelect: false,
			  enableRowSelection: true,
			  headerRowHeight:0,
			  keepLastSelected : false,
	      };
	      
	  $scope.stataScriptListOptions = {
			  data: 'stataScripts',
			  columnDefs: [{field: 'Script', displayName: ''}],
			  selectedItems: $scope.selectedScript,
			  multiSelect: false,
			  enableRowSelection: true,
			  headerRowHeight:0,
			  keepLastSelected : false,
	  };
	  
	  $scope.scriptMetadataGridOptions = {
			  data: 'scriptMetadata.inputs',
			  columnDefs : [{field : "param", displayName : "Parameter"},
		               {field :"type", displayName : "Type", enableCellEdit : false, cellTemplate : '<select  ng-input="COL_FIELD" ng-model="COL_FIELD" ng-options="input for input in inputTypes" style="align:center"></select>'},
		               {field : "columnType", displayName : "Column Type", enableCellEdit : false, cellTemplate : '<select  ng-input="COL_FIELD" ng-if="scriptMetadata.inputs[row.rowIndex].type == &quot;column&quot;" ng-model="COL_FIELD" ng-options="type for type in columnTypes" style="align:center"></select>'},
		               {field : "options", displayName : "Options"},
		               {field : "default", displayName : "Default"},
		               {field : "description", displayName : "Description"}],
			  multiSelect: false,
			  enableRowSelection: true,
			  keepLastSelected : false,
			  enableCellEditOnFocus: true,
			  enableCellEdit : true,
			  selectedItems : $scope.selectedRow,
			  enableSorting : false,
	  };
	  
	  $scope.inputTypes = ["column", "options", "boolean", "value", "multiColumns", ""];
	  $scope.columnTypes = ["analytic", "geography", "indicator", "time", "by-variable"];
	  
	  
	  var refreshScripts = function () {
		  scriptManagerService.getListOfRScripts().then(function(result) {
			  $scope.rScripts = $.map(result, function(item) {
				  return {Script : item};
			  });
		  });
	  
	      scriptManagerService.getListOfStataScripts().then(function(result) {
	    	  $scope.stataScripts = $.map(result, function(item) {
	    		  return {Script : item};
	          });
	      });
	  };
	  
	  $scope.refreshScripts  = refreshScripts;
	  
	  refreshScripts();
	  
	  $scope.$on("refreshScripts", function() {
		  console.log("broadcast received");
		  refreshScripts();
	  });
	  
	  $scope.$watchCollection('selectedScript', function(newVal, oldVal) {
		  
		  if(newVal.length && newVal[0].Script) {
			  scriptManagerService.getScriptMetadata(newVal[0].Script).then(function(result) {
				  $scope.scriptMetadata.description = result.description;
				  $scope.scriptMetadata.inputs = result.inputs;
			  });
			  
			  scriptManagerService.getScript(newVal[0].Script).then(function(result) {
				  $scope.script.content = result;
			  });
		  }
      });
	  
	  $scope.toggleEdit = function() {
		$scope.editScript = !$scope.editScript;
		
		// every time editScript is turnOff, we should save the changes.
		if(!$scope.editScript) {
			$scope.EditDone = "Edit";
			if($scope.script.content && $scope.selectedScript[0].Script) {
				scriptManagerService.saveScriptContent($scope.selectedScript[0].Script,  $scope.script.content).then(function (result) {
					if(result) {
						console.log("script modified successfully");
					}
				});
			}
		} else {
			$scope.EditDone = "Done";
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
	  
	  /*** two way binding ***/
	  $scope.$watch('inputsAsString', function() {
		  if($scope.inputsAsString) {
			  $scope.scriptMetadata.inputs = angular.fromJson($scope.inputsAsString); 
		  }
	  });
	  $scope.$watch('scriptMetadata.inputs', function () {
		  if($scope.scriptMetadata.inputs) {
			  $scope.inputsAsString = angular.toJson($scope.scriptMetadata.inputs, true); 
		  }
	  }, true);
	  /***********************/
	  
	  $scope.addNewRow = function () {
		 $scope.scriptMetadata.inputs.push({param: '...', type: ' ', columnType : ' ', options : ' ', description : '...'});
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
	 
	 $scope.deteleScript = function () {
		 if($scope.selectedScript.length) {
			 if($scope.selectedScript[0].Script) {
				 scriptManagerService.deleteScript($scope.selectedScript[0].Script).then(function(status) {
					 if(status) {
						 console.log("script deleted successfully");
						 $scope.rScriptListOptions.selectAll(false);
						 $scope.stataScriptListOptions.selectAll(false);
					 }
					 $scope.selectedScript.Script = "";
					 $scope.script.content = "";
					 $scope.scriptMetadata = {};
					 refreshScripts();
				 });
			 }
		 }
	 };
	 $scope.$watch('selectedScript.length', function () {
		 console.log($scope.selectedScript.length);
	 });
	 
	 $scope.saveChanges = function () {
		 if($scope.selectedScript[0])
		 {
			 scriptManagerService.saveScriptMetadata($scope.selectedScript[0].Script, angular.toJson($scope.scriptMetadata, true)).then(function(result) { 
				 
				 if(result) {
					 refreshScripts();
					 $scope.statusColor = "green";
					 $scope.status = "Changes successful!";
					 setTimeout(function() {
						 $scope.status = "";
						 $scope.$apply();
					 }, 1000);
				 } else {
					 $scope.statusColor = "red";
					 $scope.status = "Changes unsuccessful!";
				 }
			 });
		 }
	 };
    $scope.saveNewScript = function (content, metadata) {
    	$modal.open({
			 backdrop: false,
	         backdropClick: true,
	         dialogFade: true,
	         keyboard: true,
	         templateUrl: 'aws/configure/script/uploadNewScript.html',
	         controller: 'AddScriptDialogInstanceCtrl',
		});
    };
}).controller('AddScriptDialogInstanceCtrl', function ($rootScope, $scope, $modalInstance, scriptManagerService) {
	  
	 $scope.fileName = "";
	 $scope.metadata = "";
	 $scope.validText = "";
	 $scope.isScriptValid = false;
	 $scope.step = 1;
	 
	 $scope.scriptUploaded = {
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
	 
	 $scope.$watch('scriptUploaded.metadata', function() {
		 if($scope.scriptUploaded.metadata) {
			 $scope.metadataUploaded = angular.fromJson($scope.scriptUploaded.metadata.content);
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
			  enableCellEdit : false,
	  };
	 
	$scope.$watch('scriptUploaded.script.filename', function () {
		scriptManagerService.scriptExists($scope.scriptUploaded.script.filename).then(function(result) {
			if(result) {
				$scope.validText = "script already exists";
				$scope.isScriptValid = false;
			} else {
				$scope.validText = "";
				$scope.isScriptValid = true;
			}
		});
	});
	$scope.$watch('step', function(n, o) { 
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
					$scope.$broadcast('refreshScripts'); // tell the other controller to refresh the list of scripts
				}
			}
				
		} else {
			$scope.uploadSucessful = "na";
		}
	});
  });