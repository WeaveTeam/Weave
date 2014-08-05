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

bioWeave_mod.controller('InputParamsController', function($scope, runScriptService){
	//pulls in the external template for use in ng-include in the main BioWeaveManager.html
	$scope.inputParamsHTMLTpl = {url: 'aws/bioWeave/parameterInputPanel.html'};
	
	$scope.runScriptService = runScriptService;
	
});

bioWeave_mod.controller('ResultsViewController', function($scope, runScriptService){
	$scope.resultViewHTMLTpl = {url: 'aws/bioWeave/resultViewPanel.html'};
	
	$scope.runScriptService = runScriptService;
});