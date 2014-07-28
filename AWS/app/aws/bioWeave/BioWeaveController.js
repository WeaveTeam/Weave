/**
 * 
 */
var bioWeave_mod = angular.module('aws.bioWevae', []);

bioWeave_mod.controller("BioWeaveController", function($scope,runScriptService){

	console.log("done");
	
});

bioWeave_mod.controller('AlgoObjectListController', function($scope,runScriptService ){
	console.log("reached algolist controller");
	
	$scope.service = runScriptService;
	
	//retrive list of algorithm Objects
	runScriptService.getListOfAlgoObjects();
});