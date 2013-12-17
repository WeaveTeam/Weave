/**
 * DataTable Module DataTableCtrl - Controls dialog button and closure.
 */
angular.module('aws.DataTable', []).controller('DataTableCtrl', function($scope, queryService) {
	
	queryService.getDataTableList();
	
	$scope.$watch(function() {
		return queryService.dataObject.dataTableList;
	}, function(newVal, oldVal) {
		if(newVal) {
			$scope.dataTableList = newVal;
		}
	});
	
    $scope.$watch('dataTable', function(newVal) {
    	if(newVal) {
   			queryService.queryObject.dataTable = angular.fromJson($scope.dataTable); 
			queryService.getDataColumnsEntitiesFromId(angular.fromJson(newVal).id);
    	}
    });
    
    $scope.$watch(function() {
    	return queryService.queryObject.dataTable;
    }, function() {
    	$scope.dataTable = queryService.queryObject.dataTable;
    });
});