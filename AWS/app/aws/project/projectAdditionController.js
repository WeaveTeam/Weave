var hoo;
var projectModule = angular.module('aws.project');
projectModule.controller("projectAdditionController", function($scope, $modal, projectService){
	$scope.projectService = projectService;
	
	//projectService.data.uploadStatus = "No file uploaded";
	//projectService.data.queryObjectJsons = []; //array of uploaded queryObject jsons
	//projectService.data.queryObjectTitles = [];
	var queryObjectJsons = [];
	var queryObjectTitles = [];
	
//
//	$scope.$watch('fileUpload', function(n, o) {
//              $scope.fileUpload.then(function(result) {
//            	$scope.uploadStatus = "";
//            	
//            	//TODO find way to retain file uploaded for state retention
//            	queryObjectJsons = [];//reset
//            	queryObjectTitles = [];//reset before every upload
//            	
//            	$scope.uploadStatus = result.filename+ " uploaded";  
//            	queryObjectJsons.push(result.contents);//filling up the json array
//                var jsonObject = JSON.parse(result.contents);
//                console.log("json",jsonObject);
//                queryObjectTitles.push(jsonObject.title);
//              });
//            
//          }, true);
//	
//	 $scope.saveNewProjectToDatabase = function(){
//		
//		 console.log("jsons", queryObjectJsons);
//		 console.log("titles", queryObjectTitles);
//		 console.log("userName",$scope.userNameEntered);
//		 
//		 if(angular.isUndefined($scope.userNameEntered))
//			 $scope.userNameEntered = "Awesome User";
//		 $scope.resultVisualizations = null;//when queryObjects will be added with a project, generated visualizations will be null
//				 
//		 projectService.createNewProject(userNameEntered,
//				 						 projectNameEntered,
//				 						 projectDescriptionEntered,
//				 						 queryObjectTitles,
//				 						 queryObjectJsons);
//		
//		 
//	 };
	 
	 //communicating with the modal
	 $scope.pjtModalOptions = {//TODO find out how to push error log to bottom of page
			 backdrop: true,
	         backdropClick: true,
	         dialogFade: true,
	         keyboard: true,
	         templateUrl: 'aws/project/projectAdditionPanel.html',
	         controller: 'pjtAddtionInstanceCtrl',
	         resolve :{
	        	 projectNameEntered : function(){return $scope.projectNameEntered;},
	        	 userNameEntered : function(){return $scope.userNameEntered;},
	        	 projectDescriptionEntered : function(){return $scope.projectDescriptionEntered;}
	        	 
	         }
		};
	
	$scope.openAdditionPanel = function(){
		var saveNewProject = $modal.open($scope.pjtModalOptions);
		
		saveNewProject.result.then(function(additionParams){
			 console.log("jsons", queryObjectJsons);
			 console.log("titles", queryObjectTitles);
			 console.log("userName", additionParams.userNameEntered);
			 
//			 projectService.createNewProject(additionParams.userNameEntered,
//					 						 additionParams.projectNameEntered,
//					 						 additionParams.projectDescriptionEntered,
//					 						 queryObjectTitles,
//					 						 queryObjectJsons);
			 
		});
	};
});

//Modal instance controller
projectModule.controller('pjtAddtionInstanceCtrl', function($rootScope,$scope, $modalInstance, projectNameEntered,projectDescriptionEntered, userNameEntered ) {
	$scope.uploadStatus = "No file uploaded";
	
	$scope.uploadedQueryObject = {
			filename : "",
			content : ""
	};
	$scope.$watch('uploadedQueryObject.filename', function(){
		
		if($scope.uploadedQueryObject)
			{
				console.log("got file name",$scope.uploadedQueryObject.filename );
			}
		
	},true);
	
	$scope.close = function (projectNameEntered,projectDescriptionEntered) {
		var additionParams = {
				projectNameEntered : projectNameEntered,
				userNameEntered :userNameEntered,
				projectDescriptionEntered : projectDescriptionEntered
		};
		
		 $modalInstance.close(additionParams);
	 };
});