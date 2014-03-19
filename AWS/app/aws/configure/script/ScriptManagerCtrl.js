angular.module('aws.configure.script', ['ngGrid'])
  .controller("ScriptManagerCtrl", function($scope, scriptManagerService) {

    $scope.listOfScripts = [];
    $scope.uploadScript = false;
    $scope.textScript = false;
    $scope.saveButton = false;
    scriptManagerService.getListOfScripts();
    $scope.selectedScript = [];
    $scope.selectedMetadata = {};

    $scope.$watch(function() {
      return scriptManagerService.dataObject.listOfScripts;
    }, function() {
      $scope.listOfScripts = [];
      angular.forEach(scriptManagerService.dataObject.listOfScripts, function(item) {
        $scope.listOfScripts.push({name: item});
      });
    });
    $scope.$watch(function(){
      return scriptManagerService.dataObject.scriptMetadata;
    },function(nv){
      $scope.selectedMetadata = nv;
      console.log("metadata:", $scope.selectedMetadata);
    });
    $scope.gridOptions = {data: 'listOfScripts',
      columnDefs: [{field: 'name', displayName: 'Name'}],
      selectedItems: $scope.selectedScript,
      //multiSelect: false,
      afterSelectionChange: function(item){
        console.log("selectionchange", $scope.selectedScript);
        scriptManagerService.getScriptMetadata($scope.selectedScript[0].name);
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