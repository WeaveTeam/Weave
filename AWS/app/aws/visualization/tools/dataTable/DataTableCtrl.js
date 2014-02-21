angular.module("aws.visualization.tools.dataTable", [])
.controller("DataTableCtrl", function($scope, queryService){
	queryService.queryObject.dataTable = {
			id : -1,
			title : ""
	};
	
	queryService.getDataTableList();
	$scope.dataTableList = [];
	
	$scope.$watch(function() {
		return queryService.dataObject.dataTableList;
	}, function() {
		if(queryService.dataObject.hasOwnProperty("dataTableList")) {
			for(var i=0; i < queryService.dataObject.dataTableList.length; i++) {
				dataTable = queryService.dataObject.dataTableList[i];
				$scope.dataTableList.push( {
											 id : dataTable.id ,
											 title : dataTable.title
											});
			}
		}
	});
	
    $scope.$watch('dataTable', function() {
    	if ($scope.dataTable != undefined && $scope.dataTable != "") {
    		var dataTable = angular.fromJson($scope.dataTable);
    		queryService.queryObject.dataTable = dataTable; 
    		if(dataTable.hasOwnProperty('id') && dataTable.id != null) {
    			queryService.getDataColumnsEntitiesFromId(dataTable.id);
    		}
    	}
    });
    
    $scope.$watch(function() {
    	return queryService.queryObject.dataTable;
    }, function() {
    	$scope.dataTable = angular.toJson(queryService.queryObject.dataTable);
    });	

});