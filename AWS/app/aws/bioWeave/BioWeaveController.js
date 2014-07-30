/**
 * 
 */
var bioWeave_mod = angular.module('aws.bioWeave', []);

bioWeave_mod.controller("BioWeaveController", function($scope,runScriptService){

});

bioWeave_mod.controller('AlgoObjectListController', function($scope,runScriptService ){
	$scope.runScriptService = runScriptService;
	
	//retrive list of algorithm Objects
	runScriptService.getListOfAlgoObjects();
	
});