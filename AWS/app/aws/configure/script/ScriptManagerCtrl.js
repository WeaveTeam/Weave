angular.module('aws.configure.script', []).controller("ScriptManagerCtrl", function($scope, queryService){
				
				$scope.listOfScripts = [];
				$scope.uploadScript = false;
				$scope.textScript  = false;
				$scope.saveButton = false;
				queryService.getListOfScripts();
				
				$scope.$watch(function() {
					return queryService.dataObject.listOfScripts;
				}, function() {
					$scope.listOfScripts = queryService.dataObject.listOfScripts;
				});
				
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
			