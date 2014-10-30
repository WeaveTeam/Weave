AnalysisModule.controller("DataTableCtrl", function($scope, queryService, WeaveService) {

	$scope.service = queryService;
	$scope.WeaveService = WeaveService;
	
	$scope.content_tools = [
		{title :"Shweta"}, 
					
		{title :"Hello"}, 
						  
	    {title :"yelloq"}, 
	    					
		{title :"shdflsh"} 
   ];
	$scope.columns =["fips", "labels", "year.2010", "prev.pct.2010", "CI_LOW.2010", "CI_HI.2010", "CINT.2010"]; 
	
//	$scope.$watch(function(){
//		return WeaveService.columnNames;
//	}, function(){
//		$scope.columns = WeaveService.columns;
//	});
	
	$scope.$watch(function(){
		return queryService.queryObject.DataTableTool;
	}, function(){
		WeaveService.DataTableTool(queryService.queryObject.DataTableTool);
	}, true);

}); 