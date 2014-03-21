angular.module('aws.configure.script', ['ngGrid', 'mk.editablespan'])
  .controller("ScriptManagerCtrl", function($scope, scriptManagerService) {

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
    $scope.$watch('selectedMetadata',function(newv, oldv){
      console.log("selectedMetadata", newv);
      $scope.savingMetadata = true;
      if($scope.selectedScript[0] != ""){
        scriptManagerService.saveChangedMetadata($scope.selectedMetadata)
          .then(function(){
            $scope.savingMetadata = false;
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
    });

    $scope.addInput = function(){
      $scope.selectedMetadata.inputs.push({param: "New Input", description: "Type a Description"});
    };
    $scope.addOutput = function(){
      $scope.selectedMetadata.outputs.push({param: "New Output", description: "Type a Description"});
    };
    $scope.deleteInput = function(index){
      $scope.selectedMetadata.inputs.splice(index, 1);
    };
    $scope.deleteOutput = function(index){
      $scope.selectedMetadata.outputs.splice(index, 1);
    };
    $scope.addNewScript = function(){
      console.log("add a new Script means uploading a script and optionally metadata");
      console.log("if there is no metadata then should be able to fill out the forms with sensible defaults");
    };
    $scope.$watch(function(){
      return scriptManagerService.dataObject.scriptMetadata;
    },function(newval){
      $scope.selectedMetadata = newval;
      //console.log("metadata:", $scope.selectedMetadata);
    });
    
    $scope.$watch(function(){
      return scriptManagerService.dataObject.scriptContent;
    }, function(newval){
      $scope.scriptContent = newval;
      //console.log("scriptcontent", $scope.scriptContent);
    });

    $scope.gridOptions = {data: 'listOfScripts',
      columnDefs: [{field: 'name', displayName: 'Name'}],
      selectedItems: $scope.selectedScript,
      multiSelect: false,
      afterSelectionChange: function(item){
        //console.log("selectionchange", $scope.selectedScript);
        if($scope.selectedScript.length >= 1){
          scriptManagerService.refreshScriptInfo($scope.selectedScript[0].name);
        }
      }
    };
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

  });