var dc_mod = angular.module('aws.dataCommunication', []);

dc_mod.controller("DataCommunicationController", function($scope,algorithmObjectService){

	$scope.algorithmObjectService = algorithmObjectService;
	algorithmObjectService.getDataTableList();
});