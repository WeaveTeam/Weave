/**
 *  Individual Panel Type Controllers
 *  These controllers will be specified via the panel directive
 */
angular.module("aws.panelControllers", [])
.controller("SelectColumnPanelCtrl", function($scope, queryobj, dataService){
	
	$scope.options; // initialize
	$scope.selection;
	
	
	// fetch Columns using current dataTable
	//refreshColumns($scope, queryobj.conn.dataTable);
	$scope.options = dataService.giveMeColObjs($scope);
	
	if(queryobj[$scope.selectorId]){
		$scope.selection = queryobj[$scope.selectorId];
	}
	
	// watch functions for two-way binding
	$scope.$watch('selection', function(){
		queryobj[$scope.selectorId] = $scope.selection;
	});
	
	$scope.$on("refreshColumns", function(e){
		$scope.options = dataService.giveMeColObjs($scope);
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
	if(!queryobj['selectedVisualization']){
		queryobj['selectedVisualization'] = {'maptool':false, 'barchart':false, 'datatable':false};
	}
	$scope.vis = queryobj['selectedVisualization'];
	
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
	};
})
.controller("GenericPanelCtrl", function($scope){
	
})
.controller("MapToolPanelCtrl", function($scope, queryobj, dataService){
	$scope.enabled = queryobj.selectedVisualization['maptool'];
	$scope.options = dataService.giveMeGeomObjs($scope);
	
	$scope.selection;
	
	// selectorId should be "mapPanel"
	if(queryobj['maptool']){
		$scope.selection = queryobj['maptool'];
	}
	
	// watch functions for two-way binding
	$scope.$watch('selection', function(oldVal, newVal){
		// TODO Bad hack to access results
		//console.log(oldVal, newVal);
		if($scope.options.$$v != undefined){
			var obj = $scope.options.$$v[$scope.selection];
			var send = {};
			send.weaveEntityId = obj.id;
			send.keyType = obj.publicMetadata.keyType;
			send.title = obj.publicMetadata.title;
			queryobj['maptool'] = send;
		}
	});
	$scope.$watch('enabled', function(){
		queryobj.selectedVisualization['maptool'] = $scope.enabled;
	});
	$scope.$watch(function(){
		return queryobj.selectedVisualization['maptool'];
	},
		function(select){
			$scope.enabled = queryobj.selectedVisualization['maptool'];
	});
})
.controller("BarChartToolPanelCtrl", function($scope, queryobj, scriptobj){
	$scope.enabled = queryobj.selectedVisualization['barchart'];
	
	$scope.options = scriptobj.scriptMetadata['outputs'];
	$scope.selection;
	// selectorId should be "barChartPanel"
	if(queryobj[$scope.selectorId]){
		$scope.selection = queryobj['barchart'];
	}
	
	// watch functions for two-way binding
	$scope.$watch('selection', function(){
		queryobj['barchart'] = $scope.selection;
	});
	$scope.$watch('enabled', function(){
		queryobj.selectedVisualization['barchart'] = $scope.enabled;
	});
	$scope.$watch(function(){
		return queryobj.selectedVisualization['barchart'];
	},
		function(select){
			$scope.enabled = queryobj.selectedVisualization['barchart'];
	});
})
.controller("DataTablePanelCtrl", function($scope, queryobj, scriptobj){
	$scope.enabled = queryobj.selectedVisualization['datatable'];
	$scope.options = scriptobj.scriptMetadata['outputs'];
	$scope.selection;
	// selectorId should be "dataTablePanel"
	if(queryobj[$scope.selectorId]){
		$scope.selection = queryobj["datatable"];
	}
	
	// watch functions for two-way binding
	$scope.$watch('selection', function(){
		queryobj["datatable"] = $scope.selection;
	});
	$scope.$watch('enabled', function(){
		queryobj.selectedVisualization['datatable'] = $scope.enabled;
	});
	$scope.$watch(function(){
		return queryobj.selectedVisualization['datatable'];
	},
		function(select){
			$scope.enabled = queryobj.selectedVisualization['datatable'];
	});
})
.controller("ColorColumnPanelCtrl", function($scope, queryobj, scriptobj){
	$scope.selection;
	
	// selectorId should be "ColorColumnPanel"
	if(queryobj[$scope.selectorId]){
		$scope.selection = queryobj["colorColumn"];
	}
	$scope.options = scriptobj.scriptMetadata['outputs'];
	// watch functions for two-way binding
	$scope.$watch('selection', function(){
		queryobj["colorColumn"] = $scope.selection;
	});
})
.controller("CategoryFilterPanelCrtl", function($scope, queryobj, dataService){
	
})
.controller("ContinuousFilterPanelCtrl", function($scope, queryobj, dataService){
	
})
.controller("ScriptOptionsPanelCtrl", function($scope, queryobj, scriptobj){
	
	// Populate Labels
	var metadata = scriptobj.scriptMetadata;
	$scope.labels = metadata['inputs'];
	
	
	// Populate options from Analysis Builder queryobj
	var col = ["geography", "indicators", "byvars", "timeperiods", "analytics"];
	var columns = [];
	for(var i = 0; i<col.length; i++){
		if(queryobj[col[i]]){
			$.merge(columns, queryobj[col[i]]);
		}
	}
	$scope.options = columns;
	$scope.selection = [];
	
	// retrieve selections, else create blanks;
	if(queryobj['scriptOptions']){
		$scope.selection = queryobj['scriptOptions'];
	}else{
		angular.forEach($scope.labels, function(label, i){
			$scope.selection[i] = "";
		});
	}
	
	// set up watch functions
	$scope.$watch('selection', function(){
		queryobj['scriptOptions'] = $scope.selection;
	}, true);

})
.controller("RDBPanelCtrl", function($scope, queryobj){
	
	if(queryobj["conn"]){
		$scope.conn = queryobj["conn"];
	}else{
		$scope.conn = {};
	}
	$scope.$watch('conn', function(){
		queryobj['conn'] = $scope.conn;
	}, true);
})
