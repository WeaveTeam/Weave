var projectModule = angular.module('aws.project');
projectModule.controller("projectAdditionController", function($scope, projectService){
	
	//var project = "";
	//var projectDescription = "";
	//var user = "";
	projectService.data.uploadStatus = "No file uploaded";
	//projectService.data.queryObjectJsons = []; //array of uploaded queryObject jsons
	//projectService.data.queryObjectTitles = [];
	var fileCount = 0;
    $scope.fileUpload;
	
    //$scope.projtDescription = ""; 
//	$scope.$watch('projectName', function(){
//		 project = $scope.projectName;
//	});
//	
//	$scope.$watch('userName', function(){
//		 user = $scope.userName;
//	});
//	
	$scope.$watch('fileUpload', function(n, o) {
            if ($scope.fileUpload && $scope.fileUpload.then) {
              $scope.fileUpload.then(function(result) {
               // $scope.uploadStatus = "";
            	projectService.projectBundle.uploadStatus = "";
            	
            	//TODO find way to retain file uploaded for state retention
            	projectService.projectBundle.queryObjectJsons = [];//reset
            	projectService.projectBundle.queryObjectTitles = [];//reset before every upload
            	
            	projectService.projectBundle.uploadStatus = result.filename+ " uploaded";  
                projectService.projectBundle.queryObjectJsons.push(result.contents);//filling up the json array
                var jsonObject = JSON.parse(result.contents);
                console.log("json",jsonObject);
                projectService.projectBundle.queryObjectTitles.push(jsonObject.title);
              });
            }
          }, true);
	
	
	
	 $scope.saveNewProjectToDatabase = function(){
		
		 console.log("jsons", projectService.projectBundle.queryObjectJsons);
		 console.log("titles", projectService.projectBundle.queryObjectTitles);
		 console.log("userName", projectService.projectBundle.userName);
		 
		 if(angular.isUndefined(projectService.projectBundle.userName))
			 projectService.projectBundle.userName = "Awesome User";
		 projectService.projectBundle.resultVisualizations = null;//when queryObjects will be added with a project, generated visualizations will be null
				 
		 projectService.createNewProject(projectService.projectBundle);
		
		 
	 };
	
});


projectModule.controller('pjtAdditonModal', function($scope, $modal){
	$scope.pjtModalOptions = {//TODO find out how to push error log to bottom of page
			 backdrop: true,
	         backdropClick: true,
	         dialogFade: true,
	         keyboard: true,
	         templateUrl: 'aws/project/projectAdditionPanel.html',
	         controller: 'pjtAddtionInstanceCtrl'
		};
	
	$scope.openAdditionPanel = function(){
		$modal.open($scope.pjtModalOptions);
	};
	
});

projectModule.controller('pjtAddtionInstanceCtrl', function($rootScope,$scope, $modalInstance, projectService) {
	//this is the scope of the modal window that actually opens up
	
	$scope.projectService = projectService;
	//saves a new project (collection of query objects to the server)
	$scope.saveNewProjectToDatabase = function(){
		
//		 console.log("jsons", projectService.projectBundle.queryObjectJsons);
//		 console.log("titles", projectService.projectBundle.queryObjectTitles);
//		 console.log("userName", projectService.projectBundle.userName);
//		 
//		 if(angular.isUndefined(projectService.projectBundle.userName))
//			 projectService.projectBundle.userName = "Awesome User";
//		 projectService.projectBundle.resultVisualizations = null;//when queryObjects will be added with a project, generated visualizations will be null
//				 
//		 projectService.createNewProject(projectService.projectBundle);
		
		 
	 };
	
	$scope.close = function () {
		 $modalInstance.close();
	 };
});