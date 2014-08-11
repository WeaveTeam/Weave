/**
 * 
 */
var bioWeave_mod = angular.module('aws.bioWeave', []);

bioWeave_mod.controller("BioWeaveController", function($scope,algorithmObjectService){

	$scope.algorithmObjectService = algorithmObjectService;
	algorithmObjectService.getDataTableList();//we do this again, because we dont want to depend on the Analysis tab for loading the datatables
	
});

bioWeave_mod.controller('AlgoObjectListController', function($scope,algorithmObjectService ){
	$scope.algorithmObjectService = algorithmObjectService;
	
	//retrieve list of algorithm Objects
	algorithmObjectService.getListOfAlgoObjects();
	
});

bioWeave_mod.controller('InputParamsController', function($scope, algorithmObjectService, runScriptService){
	//pulls in the external template for use in ng-include in the main BioWeaveManager.html
	$scope.inputParamsHTMLTpl = {url: 'aws/bioWeave/parameterInputPanel.html'};
	
	$scope.algorithmObjectService = algorithmObjectService;
	
	$scope.collectAlgoObjects = function(){
		var titles = [];//using titles to retrive corresponding script names
		
		for(var f in algorithmObjectService.data.algorithmMetadataObjects){
			titles[f] = algorithmObjectService.data.algorithmMetadataObjects[f].title;
		}
		
		algorithmObjectService.getScripts(titles);
			
//		$scope.$watch(function(){
//			return algorithmObjectService.data.chosenScripts;
//		}, function(){
//			console.log("got the scripts", algorithmObjectService.data.chosenScripts);
//		});
		
		//runScriptService.runScript(algorithmObjectService.data.algorithmMetadataObjects, algorithmObjectService.data.chosenScripts);
	};
	
});

bioWeave_mod.controller('ResultsViewController', function($scope, algorithmObjectService){
	//pulls in the external template for use in ng-include in the main BioWeaveManager.html
	$scope.resultViewHTMLTpl = {url: 'aws/bioWeave/resultViewPanel.html'};
	
	$scope.algorithmObjectService = algorithmObjectService;
});