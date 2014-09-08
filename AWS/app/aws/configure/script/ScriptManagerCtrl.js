var scriptUploaded;
var scriptModule = angular.module('aws.configure.script', ['ngGrid', 'mk.editablespan']).controller("ScriptManagerCtrl", function($scope, scriptManagerService, queryService) {

	  $scope.service = scriptManagerService;
	  $scope.queryService = queryService;
	  $scope.selectedScript = [];
	  $scope.scriptMetadata = {};
	  $scope.selectedRow = [];
	  $scope.editMode = false;
	  
	  $scope.$watch('scriptMetadata', function () {
	 // console.log($scope.scriptMetadata);
	  }, true);
	  
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
		  refreshScripts();
	  });
	  $scope.$watchCollection('selectedScript', function(newVal, oldVal) {
		  
		  if(newVal.length && newVal[0].Script) {
			  scriptManagerService.getScriptMetadata(newVal[0].Script).then(function(result) {
				  $scope.scriptMetadata.description = result.description;
				  $scope.scriptMetadata.inputs = result.inputs;
			  });
			  
			  scriptManagerService.getScript(newVal[0].Script).then(function(result) {
				  $scope.scriptContent = result;
			  });
		  }
      });
	          
	          
      $scope.rScriptListOptions = {
		  data: 'rScripts',
		  columnDefs: [{field: 'Script', displayName: 'R Scripts'}],
		  selectedItems: $scope.selectedScript,
		  multiSelect: false,
		  enableRowSelection: true
      };
      
	  $scope.stataScriptListOptions = {
			  data: 'stataScripts',
			  columnDefs: [{field: 'Script', displayName: 'Stata Scripts'}],
			  selectedItems: $scope.selectedScript,
			  multiSelect: false,
			  enableRowSelection: true
	  };
	  
	  $scope.scriptMetadataGridOptions = {
			  data: 'scriptMetadata.inputs',
		  columnDefs : [{field : "param", displayName : "Parameter"},
		               {field :"type", displayName : "Type", cellTemplate : '<select  ng-input="COL_FIELD" ng-model="COL_FIELD" ng-options="input for input in inputTypes" style="align:center"></select>'},
		               {field : "columnType", displayName : "Column Type", cellTemplate : '<select  ng-input="COL_FIELD" ng-if="scriptMetadata.inputs[row.rowIndex].type == &quot;column&quot;" ng-model="COL_FIELD" ng-options="type for type in columnTypes" style="align:center"></select>'},
		               {field : "options", displayName : "Options"},
		               {field : "default", displayName : "Default"},
		               {field : "description", displayName : "Description"}],
			  multiSelect: false,
			  enableRowSelection: true,
			  enableCellEdit : true,
			  selectedItems : $scope.selectedRow
	  };
	  
	  $scope.inputTypes = ["column", "options", "boolean", "value", "multiColumns", ""];
	  $scope.columnTypes = ["analytic", "geography", "indicator", "time", "by-variable"];
	  
	  $scope.addNewRow = function () {
		 $scope.scriptMetadata.inputs.push({param: '...', type: ' ', columnType : ' ', options : ' ', description : '...'});
	 };
	
	 $scope.removeRow = function() {
		 if($scope.scriptMetadataGridOptions.selectedItems.length) {
			 var index = $scope.scriptMetadata.inputs.indexOf($scope.scriptMetadataGridOptions.selectedItems[0]);
			 $scope.scriptMetadata.inputs.splice(index, 1);
		 }
	 };
	 
	 $scope.deteleScript = function () {
		 if($scope.selectedScript.length) {
			scriptManagerService.deleteScript($scope.selectedScript[0].Script).then(function(status) {
				if(status) {
					console.log("script deleted successfully");
			}
			$scope.selectedScript[0].Script = "";
			$scope.scriptContent = "";
			$scope.scriptMetadata = {};
			refreshScripts();
			});
		 }
	 };
	 
	 $scope.saveChanges = function () {
		 if($scope.selectedScript[0])
		 {
			 scriptManagerService.saveScriptMetadata($scope.selectedScript[0].Script, angular.toJson($scope.scriptMetadata)).then(refreshScripts);
			 scriptManagerService.saveScriptContent($scope.selectedScript[0].Script, $scope.scriptContent);
		 }
	 };
	 
});
scriptModule.controller('AddScriptDialogController', function ($scope, $dialog, scriptManagerService, queryService) {
	$scope.opts = {
		 backdrop: false,
         backdropClick: true,
         dialogFade: true,
         keyboard: true,
         templateUrl: 'aws/configure/script/uploadNewScript.html',
         controller: 'AddScriptDialogInstanceCtrl',
	};
	
    $scope.saveNewScript = function (content, metadata) {
      
    	var d = $dialog.dialog($scope.opts);
    	d.open();
    };
    
 })
 .controller('AddScriptDialogInstanceCtrl', function ($rootScope, $scope, dialog, scriptManagerService) {
	  
	 $scope.fileName = "";
	 $scope.scriptContent = "";
	 $scope.metadata = "";
	 $scope.step = 1;
	 
	 $scope.scriptUploaded = {};
	 $scope.metadataUploaded = {
			 content : ""
	 };
	
	 $scope.close = function () {
	  dialog.close();
	 };
	 
	 $scope.uploadSuccessful = "na";
	 
	 $scope.$watch('scriptUploaded.metadata', function() {
		 console.log($scope.scriptUploaded.metadata);
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