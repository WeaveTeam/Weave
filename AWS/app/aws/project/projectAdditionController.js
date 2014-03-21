angular.module('aws.project')
.controller("projectAdditionController", function($scope, queryService){
	
	var project = "";
	var user = "";
	$scope.uploadStatus = "No file uploaded";
	var queryObjectJsons = []; //array of uploaded queryObject jsons
	var queryObjectTitles = [];
	var fileCount = 0;
    $scope.fileUpload;
	
	$scope.$watch('projectName', function(){
		 project = $scope.projectName;
	});
	
	$scope.$watch('userName', function(){
		 user = $scope.userName;
	});
	
//	$scope.$on('fileUploaded', function(e) {
//        $scope.$safeApply(function() {
//        	$scope.uploadStatus = "";
//        	fileCount++;
//        	var countString = fileCount.toString();
//        	console.log("fileUploaded", e.targetScope.file);
//        	$scope.uploadStatus = countString + " files uploaded";
//        	queryObjectJsons.push(e.targetScope.file);//filling up the json array
//        	var jsonObject = JSON.parse(e.targetScope.file);
//        	queryObjectTitles.push(jsonObject.title);
////        	$scope.uploadStatus = $scope.uploadStatus.concat(qOTitle + " uploaded") + "\n";
//        });
//	});
	$scope.$watch('fileUpload', function(n, o) {
            if ($scope.fileUpload && $scope.fileUpload.then) {
              $scope.fileUpload.then(function(result) {
                $scope.uploadStatus = "";
                fileCount++;
                var countString = fileCount.toString();
                console.log("fileUploaded", result);
                $scope.uploadStatus = countString + " files uploaded";
                queryObjectJsons.push(result.contents);//filling up the json array
                var jsonObject = JSON.parse(result.contents);
                queryObjectTitles.push(jsonObject.title);
              });
            }
          }, true);
	
	 $scope.saveNewProjectToDatabase = function(){
		
		 var queryObjectTitle = []; //array of titles extracted from the queryObjectJsons
		 var queryObjectContent = [];//array of stringifed json objects
		 
		 console.log("jsons", queryObjectJsons);
		 console.log("titles", queryObjectTitles);
		 queryObjectTitle = queryObjectTitles;
		 queryObjectContent = queryObjectJsons;
				 
		 queryService.insertQueryObjectToProject(user, project, queryObjectTitle, queryObjectContent);
		 
	 };
	
});