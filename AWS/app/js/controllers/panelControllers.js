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
.controller("SelectScriptPanelCtrl", function($scope, queryobj, scriptobj){
	
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
		// console.log(dataService.getListOfScripts());
		$scope.options = scriptobj.getListOfScripts();
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
.controller("ScriptOptionsPanelCtrl", function($scope, queryobj, scriptobj, dataService){
	
	$scope.inputs = []; // script inputs
	$scope.options= []; // selected columns
	$scope.show = []; // array corresponding to number of inputs Show filter or not.
	$scope.sliderOptions = []; // array corresponding to settings for visible sliders
	$scope.selection = []; // array corresponding to inputs, which option is selected. 
	$scope.type = "columns"; // or "cluster" to decide which UI to draw in panel


	$scope.inputs = scriptobj.getScriptMetadata().then(function(result){
		return results.inputs;
	});  // get a promise for metadata
	
	$scope.options = queryobj.getSelectedColumns(); // get array of selected columns									
	
	angular.forEach($scope.inputs, function(item, i){ // initialize show and selection with defaults
		$scope.show[i] = false;
		$scope.selection[i] = "";
		$scope.sliderOptions[i] = {values:[1,10]};
	});
	
	$scope.$watch(function(){		// watch the selected script for changes
			return queryobj.scriptSelected;
		},function(newVal, oldVal){   	
			scriptobj.getScriptMetadata().then(function(result){			// reinitialize and apply to model
				$scope.inputs = result.inputs;
				angular.forEach(result.inputs, function(input, index){
					$scope.show[index] = false;
					$scope.selection[index] = "";
					$scope.sliderOptions[index] = {values:[1,10]};
			});
			//return result;
		});
	});
	$scope.$watch('selection', function(newVal, oldVal){
		// new and old will be arrays with objects in them (columns returned from getSelectedColumns()
        // var te = newVal;
		if(angular.toJson(newVal) != angular.toJson(oldVal)){
			angular.forEach(newVal, function(selected, i){
				if (selected){
					$scope.sliderOptions[i] = // try out a closure to set the options model.
						function(){ var obj = {
							id:selected.id,
							title:selected.title,
							filter:[selected.range]};
							return obj;
						}();
					$scope.show[i] = true;
				}
			});
			queryobj.scriptOptions = $scope.selection;
		}
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
