/**
 *  Individual Panel Type Controllers
 *  These controllers will be specified via the panel directive
 */
angular.module("aws.panelControllers", [])
.controller("ScriptCtrl", function($scope, queryService){
	
	$scope.scriptList = queryService.getListOfScripts();
	
	$scope.$watch('scriptSelected', function() {
		queryService.queryObject['scriptSelected'] = $scope.scriptSelected;
	});
	
	$scope.$watch(function(){
		return queryService.queryObject.dataTable;
	}, function(){
		$scope.columns = queryService.getDataColumnsEntitiesFromId(queryService.queryObject.dataTable.id);
	});

	$scope.selection = []; 
	
	$scope.$watch('selection', function(){
		var selectedColumns = [];
		var namesSelected = [];
		angular.forEach($scope.selection, function(value, key){
			if(value != ""){
				var val = angular.fromJson(value);
				selectedColumns.push(val);
				namesSelected.push(val.publicMetadata.title);
			};
		});
		queryService.queryObject['selectedColumns'] = namesSelected;
	}, true);
	
	$scope.$watch(function(){		// watch the selected script for changes
			return queryService.queryObject.scriptSelected;
	},function(){   	
		$scope.inputs = queryService.getScriptMetadata(queryService.queryObject.scriptSelected).then(function(result){			// reinitialize and apply to model
				return result.inputs;
		});
	});
})
.controller("WeaveVisSelectorPanelCtrl", function($scope, queryService){
	// set defaults or retrieve from queryobject
//	if(!queryobj['selectedVisualization']){
//		queryobj['selectedVisualization'] = {'maptool':false, 'barchart':false, 'datatable':false};
//	}
//	$scope.vis = queryobj['selectedVisualization'];
//	
//	// set up watch functions
//	$scope.$watch('vis', function(){
//		queryobj['selectedVisualization'] = $scope.vis;
//	});
//	$scope.$watch(function(){
//		return queryobj['selectedVisualization'];
//	},
//		function(select){
//			$scope.vis = queryobj['selectedVisualization'];
//	});
})
.controller("RunPanelCtrl", function($scope, queryService){
	
//	$scope.runQuery = function(){
//		var queryHandler = new aws.QueryHandler(queryService.queryObject);
//		queryHandler.runQuery();
//		// alert("Running Query");
//	};
//	
//	$scope.clearCache = function(){
//		aws.RClient.clearCache();
//		alert("Cache cleared");
//	};
})
.controller("MapToolPanelCtrl", function($scope, queryService){
	
//	$scope.enabled = queryService.queryObject['MapTool']['enabled'];
//	
//	$scope.option = queryService.getGeometryDataColumnsEntities;
//	
//	$scope.selection = queryService.queryObject['MapTool']['geometryColumn'] || null;
//	
})

.controller("BarChartToolPanelCtrl", function($scope, queryService){
//	if(queryobj.selectedVisualization['barchart']){
//		$scope.enabled = queryobj.selectedVisualization['barchart'];
//	}
//
//	$scope.options;
//	scriptobj.scriptMetadata.then(function(results){
//		$scope.options = results.outputs;
//	});
//	$scope.sortSelection;
//	$scope.heightSelection;
//	$scope.labelSelection;
//	
//	if(queryobj.barchart){
//		$scope.sortSelection = queryobj.barchart.sort;
//		$scope.heightSelection = queryobj.barchart.height;
//		$scope.labelSelection = queryobj.barchart.label;
//	}else{
//		queryobj['barchart'] = {};
//	}
//	
//	// watch functions for two-way binding
//	$scope.$watch('sortSelection', function(){
//		queryobj.barchart.sort = $scope.sortSelection;
//	});
//	$scope.$watch('labelSelection', function(){
//		queryobj.barchart.label = $scope.labelSelection;
//	});
//	$scope.$watch('heightSelection', function(){
//		queryobj.barchart.height = $scope.heightSelection;
//	});
//	$scope.$watch('enabled', function(){
//		queryobj.selectedVisualization['barchart'] = $scope.enabled;
//	});
//	$scope.$watch(function(){
//		return queryobj.selectedVisualization['barchart'];
//	},
//		function(select){
//			$scope.enabled = queryobj.selectedVisualization['barchart'];
//	});
})
.controller("DataTablePanelCtrl", function($scope, queryService){
//	if(queryobj.selectedVisualization['datatable']){
//		$scope.enabled = queryobj.selectedVisualization['datatable'];
//	}
//	
//	$scope.options;
//	scriptobj.scriptMetadata.then(function(results){
//		$scope.options = results.outputs;
//	});
//	$scope.selection;
//	// selectorId should be "dataTablePanel"
//	if(queryobj['datatable']){
//		$scope.selection = queryobj["datatable"];
//	}
//	
//	// watch functions for two-way binding
//	$scope.$watch('selection', function(){
//		queryobj["datatable"] = $scope.selection;
//	});
//	$scope.$watch('enabled', function(){
//		queryobj.selectedVisualization['datatable'] = $scope.enabled;
//	});
//	$scope.$watch(function(){
//		return queryobj.selectedVisualization['datatable'];
//	},
//		function(select){
//			$scope.enabled = queryobj.selectedVisualization['datatable'];
//	});
})
.controller("ColorColumnPanelCtrl", function($scope, queryService){
//	$scope.selection;
//	
//	// selectorId should be "ColorColumnPanel"
//	if(queryobj['colorColumn']){
//		$scope.selection = queryobj["colorColumn"];
//	}
//	$scope.options;
//	scriptobj.scriptMetadata.then(function(results){
//		$scope.options = results.outputs;
//	});
//	// watch functions for two-way binding
//	$scope.$watch('selection', function(){
//		queryobj["colorColumn"] = $scope.selection;
//	});
});