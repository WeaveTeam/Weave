/**
 *  Individual Panel Type Controllers
 *  These controllers will be specified via the panel directive
 */
angular.module("aws.panelControllers", [])
.controller("SelectColumnPanelCtrl", function($scope, queryobj, dataService){
	// get the promise of future values
	
	$scope.options = dataService.giveMeColObjs($scope);
	
	$scope.selection;
	
	if(queryobj[$scope.selectorId]){
		$scope.selection = queryobj[$scope.selectorId];
	}
	
	// watch functions for two-way binding
	$scope.$watch('selection', function(){
		queryobj[$scope.selectorId] = $scope.selection;
	});
/*	$scope.$watch(function(){
		return queryobj[$scope.selectorId];
	},
		function(select){
			$scope.selection = queryobj[$scope.selectorId];
	});*/

})
.controller("SelectScriptPanelCtrl", function($scope, queryobj, dataService){
	$scope.selection;
	
	if(queryobj['scriptSelected']){
		$scope.selection = queryobj['scriptSelected'];
	}else{
		queryobj['scriptSelected'] = "No Selection";
	}
	
	$scope.$watch('selection', function(){
		queryobj['scriptSelected'] = $scope.selection;
	});
	$scope.$watch(function(){
		return queryobj['scriptSelected'];
	},
		function(select){
			$scope.selection = queryobj['scriptSelected'];
	});
	
})
.controller("WeaveVisSelectorPanelCtrl", function($scope, queryobj, dataService){
	// set defaults or retrieve from queryobject
	if(queryobj['selectedVisualization']){
		$scope.vis = queryobj['selectedVisualization'];
	}else{
		queryobj['selectedVisualization'] = {'maptool':false, 'barchart':true, 'datatable':false};
	}
	
	// set up watch functions
	$scope.$watch('vis', function(){
		queryobj['selectedVisualization'] = $scope.vis;
	});
	$scope.$watch(function(){
		return queryobj['selectedVisualization'];
	},
		function(select){
			$scope.vis = queryobj['selectedVisualization'];
	});

})
.controller("RunPanelCtrl", function($scope, queryobj, dataService){
	$scope.runQ = function(){
		alert("Running Query");
		var qh = new aws.QueryHandler(queryobj);
		qh.runQuery();
	}
})
.controller("GenericPanelCtrl", function($scope){
	
})
.controller("MapToolPanelCtrl", function($scope, queryobj, dataService){
	$scope.options = dataService.giveMeGeomObjs($scope);
	
	$scope.selection;
	
	// selectorId should be "mapPanel"
	if(queryobj[$scope.selectorId]){
		$scope.selection = queryobj[$scope.selectorId];
	}
	
	// watch functions for two-way binding
	$scope.$watch('selection', function(){
		queryobj[$scope.selectorId] = $scope.selection;
	});
})
.controller("BarChartToolPanelCtrl", function($scope, queryobj){
	
	// TODO: Get from queryobj later
	$scope.options = [
	                  {
	                	  result:"Result Column #1"  
	                  },
	                  {
	                	  result:"Result Column #2"
	                  }
			];
	$scope.selection;
	// selectorId should be "barChartPanel"
	if(queryobj[$scope.selectorId]){
		$scope.selection = queryobj[$scope.selectorId];
	}
	
	// watch functions for two-way binding
	$scope.$watch('selection', function(){
		queryobj[$scope.selectorId] = $scope.selection;
	});
})
.controller("DataTablePanelCtrl", function($scope, queryobj){
	// TODO: get from queryobj
	$scope.options = [
	                  {
	                	  result:"Result Column #1"  
	                  },
	                  {
	                	  result:"Result Column #2"
	                  }
			];
	$scope.selection;
	// selectorId should be "dataTablePanel"
	if(queryobj[$scope.selectorId]){
		$scope.selection = queryobj[$scope.selectorId];
	}
	
	// watch functions for two-way binding
	$scope.$watch('selection', function(){
		queryobj[$scope.selectorId] = $scope.selection;
	});
})
.controller("ColorColumnPanelCtrl", function($scope, queryobj){
	
})
.controller("CategoryFilterPanelCrtl", function($scope, queryobj, dataService){
	
})
.controller("ContinuousFilterPanelCtrl", function($scope, queryobj, dataService){
	
})
.controller("ScriptOptionsPanelCtrl", function($scope, queryobj, dataService){
	
})