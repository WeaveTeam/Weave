/**
 * this is a directive that allows searching of the choices in a list of elements
 */

var utils_Module = angular.module('aws.utils', []);

utils_Module.directive('awsSelectDirective', function factory(){
	
	var directiveDefnObj = {
			restrict : 'A', //restricts the directive to a specific directive declaration style.in this case as element
			templateUrl : 'aws/utils/special_select.tpl.html',
			//the scope is that of the parent controller
			//elem :The jQLite wrapped element on which the directive is applied.  
			//attrs : any attributes that may have been applied on the directive element for e.g.<aws-select-directive style = "padding-top: 5px"></aws-select-directive>
			link: function(scope, elem, attrs){
				console.log("scope in directive", scope);
				console.log("elem in directive", elem);
				console.log("attrs in directive", attrs);
				
				scope.columnFilter = attrs.columnFilter;
				console.log("columnFilter", attrs.columnfilter);
			}
	};
	
	return directiveDefnObj;
});

utils_Module.controller('specialSelectCtrl', function($scope, queryService){
	$scope.property; 
	
	$scope.color = "red";
	$scope.searchOption;
	$scope.queryService = queryService;

	$scope.check = function(obj){
		console.log("selected item", obj);
		$scope.property = obj;
	};
	console.log("scope in the controller", $scope);
});