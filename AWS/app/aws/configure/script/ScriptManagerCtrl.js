angular.module('aws.configure.script', ['ngGrid', 'mk.editablespan']).controller("ScriptManagerCtrl", function($scope, scriptManagerService) {

          $scope.service = scriptManagerService;
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
          
          refreshScripts();
          
          
          $scope.$watchCollection('selectedScript', function(newVal, oldVal) {
 
        	  if(newVal.length && newVal != oldVal) {
        		  scriptManagerService.getScriptMetadata(newVal[0].Script).then(function(result) {
        			  $scope.scriptDescription = result.description;
        			  $scope.scriptMetadata = result.inputs; 
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
        		  data: 'scriptMetadata',
        		  columnDefs : [{field : "param", displayName : "Parameter"},
        		               {field :"type", displayName : "Type", cellTemplate : '<select  ng-input="COL_FIELD" ng-model="COL_FIELD" ng-options="input for input in inputTypes" style="align:center"></select>'},
        		               {field : "columnType", displayName : "Column Type", cellTemplate : '<select  ng-input="COL_FIELD" ng-if="scriptMetadata[row.rowIndex].type == &quot;column&quot;" ng-model="COL_FIELD" ng-options="input for input in columnTypes" style="align:center"></select>'},
        		               {field : "options", displayName : "Options"},
        		               {field : "description", displayName : "Description"}],
        		  multiSelect: false,
        		  enableRowSelection: true,
        		  enableCellEdit : true,
        		  selectedItems : $scope.selectedRow
          };
          
          $scope.inputTypes = ["column", "options", "boolean", "value", "multiColumns", ""];
          $scope.columnTypes = ["analytic", "geography", "indicator", "time", "by-variable"];
          
          $scope.addNewRow = function () {
     		 $scope.scriptMetadata.push({param: '...', type: ' ', columnType : ' ', options : ' ', description : '...'});
     	 };

     	 $scope.removeRow = function() {
     		 if($scope.scriptMetadataGridOptions.selectedItems.length) {
     			 var index = $scope.scriptMetadata.indexOf($scope.scriptMetadataGridOptions.selectedItems[0]);
     			 $scope.scriptMetadata.splice(index, 1);
     		 }
     	 };
     	 
     	 $scope.deteleScript = function () {
     		 if($scope.selectedScript.length) {
     			scriptManagerService.deleteScript($scope.selectedScript[0]);
     			refreshScripts();
 			 }
     	 };
     	 
     	 $scope.saveChanges = function () {
     		 if($scope.selectedScript.length) {
     			scriptManagerService.saveScriptMetadata($scope.selectedScript[0], angular.toJson($scope.scriptMetadata)).then(refreshScripts);
  			 }
     	 };
//          $scope.uploadScript = false;
//          $scope.textScript = false;
//          $scope.saveButton = false;
//          $scope.selectedScript = [];
//          $scope.selectedMetadata = {};
//          $scope.scriptContent = {};
//          $scope.savingMetadata = false;
//          $scope.editMode = false;
//          $scope.scriptToUpload = "";
//          $scope.fileUpload = null;
//          
//          $scope.inputOptions = [];
//          
//          $scope.$watch('selectedMetadata', function(newv, oldv) {
//            if ($scope.selectedScript[0] != "" && $scope.selectedScript[0] != undefined) {
//              $scope.savingMetadata = true;
//              scriptManagerService.saveChangedMetadata($scope.selectedMetadata)
//                      .then(function() {
//                        $scope.savingMetadata = false;
//                      }, function(rejected) {
//                        $scope.selectedMetadata = $scope.defaultTemplate;
//                        scriptManagerService.dataObject.scriptMetadata = $scope.defaultTemplate;
//                      });
//            }
//          }, true);
//         
//          $scope.addInput = function() {
//            if (!$scope.selectedMetadata) {
//              $scope.selectedMetadata = $scope.defaultTemplate;
//            }else if($scope.selectedMetadata.inputs) {
//              $scope.selectedMetadata.inputs.push({param: "New Input",
//                description: "Type a Description",
//                type: "type (column? value?)",
//                columnType: "Column Type (analytics? indicator?)"});
//            }
//          };
//          $scope.addOutput = function() {
//            if (!$scope.selectedMetadata) {
//              $scope.selectedMetadata = $scope.defaultTemplate;
//            }else if ($scope.selectedMetadata.outputs) {
//              $scope.selectedMetadata.outputs.push({param: "New Output",
//                description: "Type a Description"});
//            }
//          };
//          $scope.deleteInput = function(index) {
//          };
//          $scope.deleteOutput = function(index) {
//          };
//          $scope.$watch('fileUpload', function(n, o) {
//            if ($scope.fileUpload && $scope.fileUpload.then) {
//              $scope.fileUpload.then(function(result) {
//                scriptManagerService.uploadNewScript(result);
//                $scope.fileUpload = null;
//                scriptManagerService.getListOfScripts();
//              });
//            }
//          }, true);
//    $scope.addNewScript = function(){
//      return;
//      var contentUnbind;
//      var fileUnbind = $scope.$watch('scriptToUpload', function(nv){
//        if(nv != "" && nv != undefined){
//          contentUnbind = $scope.$watch('fileToUpload',function(n, o){
//            if(n != "" && n!= undefined){
//              var file = {
//                filename: $scope.scriptToUpload,
//                contents: n
//              };
//              scriptManagerService.uploadNewScript(file);
//              contentUnbind();
//              fileUnbind();
//            }
//          });
//        }
//      });
//    };
//          $scope.$watch(function() {
//            return scriptManagerService.dataObject.scriptMetadata;
//          }, function(newval) {
//            $scope.selectedMetadata = newval;
//            //console.log("metadata:", $scope.selectedMetadata);
//          });

//          $scope.$watch(function() {
//            return scriptManagerService.dataObject.scriptContent;
//          }, function(newval) {
//            $scope.scriptContent = newval;
//            //console.log("scriptcontent", $scope.scriptContent);
//          });
        });