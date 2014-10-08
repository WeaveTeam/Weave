/**
 * this is a directive that allows searching of the choices in a list of elements
 */

var utils_Module = angular.module('aws.utils', []);

utils_Module.directive('awsSelectDirective', function factory(){
	
	var directiveDefnObj= {
			restrict : 'E', //restricts the directive to a specific directive declaration style.in this case as element
			templateUrl : 'aws/utils/special_select.tpl.html',
			scope : {
				arrayOfObjects : '='
			},
			controller : function($scope, $compile){
				$scope.searchOption;
				console.log("columns",$scope.arrayOfObjects);
				//$scope.arrayOfObjects = [1,2,3];
				$scope.check = function(obj){
					console.log("selected item", obj);
					$scope.selectedItem = angular.copy(obj);
				};
				
				$scope.clear = function(){
					if(angular.isDefined($scope.selectedItem))
 					  $scope.selectedItem.title = "";
				};
			},
			//the scope is that of the parent controller
			//elem :The jQLite wrapped element on which the directive is applied.  
			//attrs : any attributes that may have been applied on the directive element for e.g.<aws-select-directive style = "padding-top: 5px"></aws-select-directive>
			link: function(scope, elem, attrs){
				console.log("scope in directive", scope);
//				console.log("elem in directive", elem);
//				console.log("attrs in directive", attrs);
				
				scope.columnfilter = attrs.columnfilter;
//				console.log("columnFilter", scope.columnfilter);
			}
	};
	
	return directiveDefnObj;
});

utils_Module.controller('specialCtrl', function($scope){
	$scope.adds = [1,2,4];
	console.log("scope in main ctrl", $scope);
});
