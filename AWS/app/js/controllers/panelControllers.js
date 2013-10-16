/**
 *  Individual Panel Type Controllers
 *  These controllers will be specified via the panel directive
 */
angular.module("aws.panelControllers", [])
.controller("SelectColumnPanelCtrl", function($scope, queryService){
	
	// This local function filters the data 
	var filter = function(data, type) {
        var filtered = [];
        for (var i = 0; i < data.length; i++) {
            if (data[i]["publicMetadata"]["ui_type"] == type || false) {
                filtered.push(data[i]);
             }
        }
        filtered.sort();
        return filtered;
    };
    
    $scope.options = queryService.getDataColumnsEntitiesFromId(694).then(function (result){
    		return filter(result, $scope.panelType);
    });
    
    /*************** two way binding *******************/
	$scope.$watch(function() { return $scope.dataTableSelect}, function() {
		queryService.queryObject[$scope.selectorId] = $scope.selection;
	});
	
	$scope.$watch(function() {
		return queryService.queryObject.datatable;
		}, function() {
		$scope.selection = queryService.queryObject[$scope.selectorId]; 
	}); 
	/****************************************************/

	$scope.showGrid = false;
	$scope.toggleShowGrid = function(){
		$scope.showGrid = (!$scope.showGrid);
	};

})
.controller("SelectScriptPanelCtrl", function($scope, queryService){
	
	$scope.options = queryService.getListOfScripts();
	
	/*************** two way binding *******************/
	$scope.$watch(function() { return $scope.dataTableSelect}, function() {
		queryService.queryObject['scriptSelected'] = $scope.selection;
	});
	
	$scope.$watch(function() {
		return queryService.queryObject.datatable;
		}, function() {
		$scope.selection = queryService.queryObject[$scope.selectorId]; 
	}); 
	/****************************************************/
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
	
	$scope.runQuery = function(){
		var queryHandler = new aws.QueryHandler(queryService.queryObject);
		queryHandler.runQuery();
		// alert("Running Query");
	};
	
	$scope.clearCache = function(){
		aws.RClient.clearCache();
		alert("Cache cleared");
	};
})

.controller("GenericPanelCtrl", function($scope){
	
})
.controller("MapToolPanelCtrl", function($scope, queryService){
	
	$scope.enabled = queryService.queryObject['MapTool']['enabled'];
	
	$scope.option = queryService.getGeometryDataColumnsEntities;
	
	$scope.selection = queryService.queryObject['MapTool']['geometryColumn'] || null;
	
})

.controller("BarChartToolPanelCtrl", function($scope, queryobj, scriptobj){
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
.controller("DataTablePanelCtrl", function($scope, queryobj, scriptobj){
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
})
.controller("CategoryFilterPanelCrtl", function($scope, queryService){
	
})
.controller("ContinuousFilterPanelCtrl", function($scope, queryService){
	
})
.controller("ScriptOptionsPanelCtrl", function($scope, queryService){
	
//	$scope.inputs = queryService.getScriptMetadata().then(function(result){
//		return result.inputs
//	}); // script inputs
//	$scope.options = queryService.queryObjects; // selected columns
//	$scope.show = []; // array corresponding to number of inputs Show filter or not.
//	$scope.sliderOptions = []; // array corresponding to settings for visible sliders
//	$scope.selection = []; // array corresponding to inputs, which option is selected. 
//	$scope.type = "columns"; // or "cluster" to decide which UI to draw in panel
//
//
//	$scope.inputs = scriptobj.getScriptMetadata().then(function(result){
//		return results.inputs;
//	});  // get a promise for metadata
//	
//	$scope.options = queryobj.getSelectedColumns(); // get array of selected columns									
//	
//	angular.forEach($scope.inputs, function(item, i){ // initialize show and selection with defaults
//		$scope.show[i] = false;
//		$scope.selection[i] = "";
//		$scope.sliderOptions[i] = {values:[1,10]};
//	});
//	
//	$scope.$watch(function(){		// watch the selected script for changes
//			return queryobj.scriptSelected;
//		},function(newVal, oldVal){   	
//			scriptobj.getScriptMetadata().then(function(result){			// reinitialize and apply to model
//				$scope.inputs = result.inputs;
//				angular.forEach(result.inputs, function(input, index){
//					$scope.show[index] = false;
//					$scope.selection[index] = "";
//					$scope.sliderOptions[index] = {values:[1,10]};
//			});
//			//return result;
//		});
//	});
//	$scope.$watch('selection', function(newVal, oldVal){
//		// new and old will be arrays with objects in them (columns returned from getSelectedColumns()
//        // var te = newVal;
//		if(angular.toJson(newVal) != angular.toJson(oldVal)){
//			angular.forEach(newVal, function(selected, i){
//				if (selected){
//					$scope.sliderOptions[i] = // try out a closure to set the options model.
//						function(){ var obj = {
//							id:selected.id,
//							title:selected.title,
//							filter:[selected.range]};
//							return obj;
//						}();
//					$scope.show[i] = true;
//				}
//			});
//			queryobj.scriptOptions = $scope.selection;
//		}
//	});

})
//.controller("RDBPanelCtrl", function($scope, queryobj){
//	if(queryobj["conn"]){
//		$scope.conn = queryobj["conn"];
//	}else{
//		$scope.conn = {};
//	}
//	$scope.$watch('conn', function(){
//		queryobj['conn'] = $scope.conn;
//	}, true);
//})
//.controller("FilterPanelCtrl", function($scope, queryobj){
//	if(queryobj.slidFilter){
//		$scope.slideFilter = queryobj.slideFilter;
//	}
//	$scope.sliderOptions = {
//			range: true,
//			//max/min: querobj['some property']
//			max: 99,
//			min: 1,
//			values: [10,25],
//			animate: 2000
//	};
//	$scope.options = queryobj.getSelectedColumns();
//	$scope.column;
//	
//	$scope.$watch('slideFilter', function(newVal, oldVal){
//		if(newVal){
//			queryobj.slideFilter = newVal;
//		}
//	}, true); //by val
//	
//})
