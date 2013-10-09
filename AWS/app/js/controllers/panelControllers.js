/**
 *  Individual Panel Type Controllers
 *  These controllers will be specified via the panel directive
 */
angular.module("aws.panelControllers", [])
.controller("SelectColumnPanelCtrl", function($scope, queryobj, dataService){
	
	$scope.options; // initialize
	$scope.selection;
	
	var filter = function(data, type) {
        var filtered = [];
        for (var i = 0; i < data.length; i++) {
            if (data[i]["publicMetadata"]["ui_type"] == type) {
                filtered.push(data[i]);
             }
        }
        filtered.sort();
        return filtered;
    };
    
	function getOptions() {
		$scope.options = dataService.getDataColumnsEntitiesFromId(queryobj.dataTable.id).then(function (result) {
    		return filter(result, $scope.panelType);
		});
	};
	
	getOptions(); // call immediately
	
	function setSelect(){
		
		if(queryobj[$scope.selectorId]){
			$scope.selection = queryobj[$scope.selectorId];
		}

		$scope.$watch('selection', function(newVal, oldVal){
			if(newVal != oldVal){
				var tempArray = [];
				angular.forEach($scope.selection, function(item, i){
					tempArray.push(angular.fromJson(item));
				});
				
				queryobj[$scope.selectorId] = tempArray;
			}
		});
	}

	$scope.$on("refreshColumns", function(e){
		getOptions();
	});

	$scope.showGrid = false;
	$scope.toggleShowGrid = function(){
		$scope.showGrid = (!$scope.showGrid);
	};

})
.controller("SelectScriptPanelCtrl", function($scope, queryobj, scriptobj, dataService){
	
	$scope.selection;
	$scope.options;
	
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
	$scope.$watch(function(){
		return queryobj.conn.scriptLocation;
	},
		function() {
		console.log(dataService.getListOfScripts());
		// $scope.options = dataService.getListOfScripts();
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
		var qh = new aws.QueryHandler(queryobj);
		qh.runQuery();
		alert("Running Query");
	};
	
	$scope.clearCache = function(){
		aws.RClient.clearCache();
		alert("Cache cleared");
	};
})
.controller("GenericPanelCtrl", function($scope){
	
})
.controller("MapToolPanelCtrl", function($scope, queryobj, dataService){
	
	 aws.DataClient.getEntityIdsByMetadata({"dataType":"geometry"}, function(idsArray) {
     	aws.DataClient.getDataColumnEntities(idsArray, function(dataEntityArray) {
     		
     		if(queryobj.selectedVisualization['maptool']){
     			$scope.enabled = queryobj.selectedVisualization['maptool'];
     		}
     		
     		$scope.option = dataEntityArray;
     		$scope.selection;
     		
     	// selectorId should be "mapPanel"
     		if(queryobj['maptool']){
     			$scope.selection = queryobj['maptool'];
     		}
     		
     		// watch functions for two-way binding
     		$scope.$watch('selection', function(){
     			queryobj['maptool'] = {
     									weaveEntityId : $scope.option.id,
     									keyType : $scope.option.keyType,
     									title : $scope.option.publicMetadata.title
     									};
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
     	});
	 
	 });
})
.controller("BarChartToolPanelCtrl", function($scope, queryobj, scriptobj){
	if(queryobj.selectedVisualization['barchart']){
		$scope.enabled = queryobj.selectedVisualization['barchart'];
	}

	$scope.options;
	scriptobj.scriptMetadata.then(function(results){
		$scope.options = results.outputs;
	});
	$scope.sortSelection;
	$scope.heightSelection;
	$scope.labelSelection;
	
	if(queryobj.barchart){
		$scope.sortSelection = queryobj.barchart.sort;
		$scope.heightSelection = queryobj.barchart.height;
		$scope.labelSelection = queryobj.barchart.label;
	}else{
		queryobj['barchart'] = {};
	}
	
	// watch functions for two-way binding
	$scope.$watch('sortSelection', function(){
		queryobj.barchart.sort = $scope.sortSelection;
	});
	$scope.$watch('labelSelection', function(){
		queryobj.barchart.label = $scope.labelSelection;
	});
	$scope.$watch('heightSelection', function(){
		queryobj.barchart.height = $scope.heightSelection;
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
	if(queryobj.selectedVisualization['datatable']){
		$scope.enabled = queryobj.selectedVisualization['datatable'];
	}
	
	$scope.options;
	scriptobj.scriptMetadata.then(function(results){
		$scope.options = results.outputs;
	});
	$scope.selection;
	// selectorId should be "dataTablePanel"
	if(queryobj['datatable']){
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
	if(queryobj['colorColumn']){
		$scope.selection = queryobj["colorColumn"];
	}
	$scope.options;
	scriptobj.scriptMetadata.then(function(results){
		$scope.options = results.outputs;
	});
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
	$scope.inputs = [];
	$scope.sliderOptions = {
			range: true,
			//max/min: querobj['some property']
			max: 99,
			min: 1,
			values: [10,25]
	};

	$scope.options = queryobj.getSelectedColumns();
	$scope.selection = [{
			id: 0,
			filter: [[1,2], [1,3]]
		},
		{
			id:1,
			filter: [[1,2], [1,3]]
		}
	];
	
	// retrieve selections, else create blanks;
	if(queryobj['scriptOptions']){
		$scope.selection = queryobj['scriptOptions'];
	}
	
	var buildScriptOptions = function(){
		var arr = [];
		var obj;
		angular.forEach($scope.selection, function(item){
			obj = "";
			if(item != ""){
				item = angular.fromJson(item);
			
				obj = {
						id:item.id,
						title:item.title
				};
				if(item.range){
					obj.filter = [item.range];
				}
			}
			arr.push(obj);
				
		});
		return arr;
	};
	
	// set up watch functions
	$scope.$watch('selection', function(){
		queryobj.scriptOptions = buildScriptOptions();
		//scriptobj.scriptMetadata.outputs = $scope.selection;
	}, true);
	$scope.$watch(function(){
		return queryobj.scriptSelected;
	},function(newVal, oldVal){
		$scope.inputs = scriptobj.getScriptMetadata().inputs;
	});

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
.controller("FilterPanelCtrl", function($scope, queryobj){
	if(queryobj.slidFilter){
		$scope.slideFilter = queryobj.slideFilter;
	}
	$scope.sliderOptions = {
			range: true,
			//max/min: querobj['some property']
			max: 99,
			min: 1,
			values: [10,25],
			animate: 2000
	};
	$scope.options = queryobj.getSelectedColumns();
	$scope.column;
	
	$scope.$watch('slideFilter', function(newVal, oldVal){
		if(newVal){
			queryobj.slideFilter = newVal;
		}
	}, true); //by val
	
})
