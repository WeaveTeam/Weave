angular.module('aws.configure.script', ['ngGrid', 'mk.editablespan']).controller("ScriptManagerCtrl", function($scope, scriptManagerService) {

          $scope.service = scriptManagerService;
          
          $scope.listOfScripts = [];
          $scope.uploadScript = false;
          $scope.textScript = false;
          $scope.saveButton = false;
          scriptManagerService.getListOfScripts();
          $scope.selectedScript = [];
          $scope.selectedMetadata = {};
          $scope.scriptContent = {};
          $scope.savingMetadata = false;
          $scope.editMode = false;
          $scope.scriptToUpload = "";
          $scope.fileUpload = null;
          $scope.defaultTemplate = {
            name: "New Script Name",
            description: "New Script Description",
            inputs: [{param: "New Input",
                description: "Type a Description",
                type: "type (column? value?)",
                columnType: "Column Type (analytics? indicator?)"}],
            outputs: [{param: "New Output",
                description: "Type a Description"}]
          };
          $scope.$watch('selectedMetadata', function(newv, oldv) {
            if ($scope.selectedScript[0] != "" && $scope.selectedScript[0] != undefined) {
              $scope.savingMetadata = true;
              scriptManagerService.saveChangedMetadata($scope.selectedMetadata)
                      .then(function() {
                        $scope.savingMetadata = false;
                      }, function(rejected) {
                        $scope.selectedMetadata = $scope.defaultTemplate;
                        scriptManagerService.dataObject.scriptMetadata = $scope.defaultTemplate;
                      });
            }
          }, true);
          $scope.$watch(function() {
            return scriptManagerService.dataObject.listOfScripts;
          }, function() {
            $scope.listOfScripts = [];
            angular.forEach(scriptManagerService.dataObject.listOfScripts, function(item) {
              $scope.listOfScripts.push({name: item});
            });
          }, true);

          $scope.addInput = function() {
            if (!$scope.selectedMetadata) {
              $scope.selectedMetadata = $scope.defaultTemplate;
            }else if($scope.selectedMetadata.inputs) {
              $scope.selectedMetadata.inputs.push({param: "New Input",
                description: "Type a Description",
                type: "type (column? value?)",
                columnType: "Column Type (analytics? indicator?)"});
            }
          };
          $scope.addOutput = function() {
            if (!$scope.selectedMetadata) {
              $scope.selectedMetadata = $scope.defaultTemplate;
            }else if ($scope.selectedMetadata.outputs) {
              $scope.selectedMetadata.outputs.push({param: "New Output",
                description: "Type a Description"});
            }
          };
          $scope.deleteInput = function(index) {
          };
          $scope.deleteOutput = function(index) {
          };
          $scope.$watch('fileUpload', function(n, o) {
            if ($scope.fileUpload && $scope.fileUpload.then) {
              $scope.fileUpload.then(function(result) {
                scriptManagerService.uploadNewScript(result);
                $scope.fileUpload = null;
                scriptManagerService.getListOfScripts();
              });
            }
          }, true);
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
          $scope.$watch(function() {
            return scriptManagerService.dataObject.scriptMetadata;
          }, function(newval) {
            $scope.selectedMetadata = newval;
            //console.log("metadata:", $scope.selectedMetadata);
          });

          $scope.$watch(function() {
            return scriptManagerService.dataObject.scriptContent;
          }, function(newval) {
            $scope.scriptContent = newval;
            //console.log("scriptcontent", $scope.scriptContent);
          });

          $scope.scriptListOptions = {data: 'service.getListOfScripts()',
            columnDefs: [{field: 'Scripts', displayName: 'Scripts'}],
            selectedItems: $scope.selectedScript,
            multiSelect: false,
	        enableRowSelection: true,
          };
          
        });