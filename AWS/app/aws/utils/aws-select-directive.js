/**
 * this is a directive that allows searching of the choices in a list of elements
 */

var utils_Module = angular.module('aws.utils', []);

utils_Module.directive('awsSelectDirective', function factory(){
	
	var directiveDefnObj= {
			restrict : 'A', //restricts the directive to a specific directive declaration style.in this case as element
			scope : {
				collection : '='
			},
			templateUrl : 'aws/utils/special_select.tpl.html',
			controller : function($scope, $compile){
				$scope.searchOption;
				$scope.check = function(obj){
					console.log("selected item", obj);
					$scope.selectedItem = angular.copy(obj);
				};
				
				$scope.clear = function(){
					if(angular.isDefined($scope.selectedItem))
 					  $scope.selectedItem.title = "";
				};
				
			},
			link: function(scope, elem, attrs){
				console.log("scope in directive", scope);
				
				scope.columnfilter = attrs.columnfilter;
			}
	};
	
	return directiveDefnObj;
});

