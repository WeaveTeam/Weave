/**
 * DataTable Module DataTableCtrl - Controls dialog button and closure.
 */
angular.module('aws.DataTable', []).controller('DataTableCtrl', function($scope, queryService) {
	
	$scope.dataTableList = queryService.getDataTableList();
    
    $scope.dataTable;
    
    $scope.$watch('dataTable', function() {
    	queryService.queryObject.dataTable = angular.fromJson($scope.dataTable); 
    });
});