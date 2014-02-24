/**

 */
angular.module("aws.router", [])
.controller("LayoutCtrl", function($scope){
	$scope.leftPanelUrl = "aws/queryObject/queryObject.html";
	$scope.analysisUrl = "aws/visualization/tools/tools.html";
	$scope.weaveInstancePanel = "./visualization/weave/weave.html";
	$scope.geographyPanel = "aws/analysis/geography/geography.html";
	//$scope.georgraphyUrl = "./tpls/GeographyPanel.tpls.html";
	
	$scope.$watch(function(){
		return aws.timeLogString;
	},function(oldVal, newVal){
		$("#LogBox").append(newVal);
	});
});