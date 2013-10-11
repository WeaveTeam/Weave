/**
 *  Individual Panel Type Controllers
 *  These controllers will be specified via the panel directive
 */
angular.module("aws.panelControllers", [])
.controller("SelectColumnPanelCtrl", function($scope, queryobj, dataService){
	
	$scope.options; // initialize
	$scope.selection = [];
	
	var getOptions = function getOptions(){
		// fetch Columns using current dataTable
		var fullColumnObjects = dataService.giveMeColObjs($scope);
		$scope.options=[];
		fullColumnObjects.then(function(result){
			angular.forEach(result, function(item, index){
				if(item.hasOwnProperty('publicMetadata')) {
					var obj = {
	           			title:item.publicMetadata.title,
	    				id:item.id,
	    				range:item.publicMetadata.var_range
	    			};
	    			$scope.options[index] = obj;
				}
			});
			setSelect();
		});
	};
	getOptions(); // call immediately
	
	function setSelect(){
		if(queryobj[$scope.selectorId]){
			var arr = queryobj[$scope.selectorId];
			angular.forEach(arr, function(item, index){
				$scope.selection[index] = angular.toJson(item);
			});
			//$scope.selection = queryobj[$scope.selectorId];
		}
		$scope.$watch('selection', function(newVal, oldVal){
			if(newVal != oldVal){
				var arr = [];
				angular.forEach($scope.selection, function(item, i){
					arr.push(angular.fromJson(item));
				});
				queryobj[$scope.selectorId] = arr;
			}
		});
	}

	$scope.$on("refreshColumns", function(e){
		getOptions();
	});

})
.controller("SelectScriptPanelCtrl", function($scope, queryobj, scriptobj){
	$scope.selection;
	$scope.options;// = scriptobj.availableScripts;
	
	if(queryobj['scriptSelected']){
		$scope.selection = queryobj['scriptSelected'];
	}else{
		queryobj['scriptSelected'] = "No Selection";
	}
	
	$scope.$watch('selection', function(){
		queryobj['scriptSelected'] = $scope.selection;
		scriptobj.updateMetadata();
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
		function(){
		$scope.options = scriptobj.getScriptsFromServer();
	});
	
})
.controller("WeaveVisSelectorPanelCtrl", function($scope, queryobj, dataService){
	// set defaults or retrieve from queryobject
	if(!queryobj['selectedVisualization']){
		queryobj['selectedVisualization'] = {'maptool':false, 
		                                     'barchart':false, 
		                                     'datatable':false,
		                                     'scatterplot':false};
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
	}
	
})
.controller("MapToolPanelCtrl", function($scope, queryobj, dataService){
	if(queryobj.selectedVisualization['maptool']){
		$scope.enabled = queryobj.selectedVisualization['maptool'];
	}
	$scope.options = dataService.giveMeGeomObjs();
	
	$scope.selection;
	
	// selectorId should be "mapPanel"
	if(queryobj['maptool']){
		$scope.selection = queryobj['maptool'];
	}
	
	// watch functions for two-way binding
	$scope.$watch('selection', function(oldVal, newVal){
		// TODO Bad hack to access results
		//console.log(oldVal, newVal);
		if(($scope.options.$$v != undefined) && ($scope.options.$$v != null)){
			var obj = $scope.options.$$v[$scope.selection];
			if(obj){
				var send = {};
				send.weaveEntityId = obj.id;
				send.keyType = obj.publicMetadata.keyType;
				send.title = obj.publicMetadata.title;
				queryobj['maptool'] = send;
			}
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
.controller("ScatterPlotToolPanelCtrl", function($scope, queryobj, scriptobj){
	if(queryobj.selectedVisualization['scatterplot']){
		$scope.enabled = queryobj.selectedVisualization['scatterplot'];
	}

	$scope.options;
	scriptobj.scriptMetadata.then(function(results){
		$scope.options = results.outputs;
	});
	$scope.ySelection;
	$scope.xSelection;
	
	if(queryobj.scatterplot){
		$scope.ySelection = queryobj.scatterplot.yColumn;
		$scope.xSelection = queryobj.scatterplot.xColumn;
	}else{
		queryobj['scatterplot'] = {};
	}
	
	// watch functions for two-way binding
	$scope.$watch('ySelection', function(){
		queryobj.scatterplot.yColumn = $scope.ySelection;
	});
	$scope.$watch('labelSelection', function(){
		queryobj.scatterplot.xColumn = $scope.xSelection;
	});

	$scope.$watch('enabled', function(){
		queryobj.selectedVisualization['scatterplot'] = $scope.enabled;
	});
	
	$scope.$watch(function(){
		return queryobj.selectedVisualization['scatterplot'];
	},
		function(select){
			$scope.enabled = queryobj.selectedVisualization['scatterplot'];
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
	$scope.sliderDefault = {
			range: true,
			//max/min: querobj['some property']
			max: 99,
			min: 1,
			values: [10,25]
	};
	$scope.sliderOptions = [];
	$scope.options = queryobj.getSelectedColumns();
	$scope.selection = [];
	$scope.show = [];
	$scope.type = "columns";
	$scope.clusterOptions = {};

	// TODO, fix: retrieve selections, else create blanks;
	if(queryobj['scriptOptions']){
		var tempselection = queryobj['scriptOptions'];
		angular.forEach(tempselection, function(item, index){
			$scope.selection[index] = angular.toJson(item);
		});
	}
	
	// build an array that will conform to what query handler expects. 
	var buildScriptOptions = function(){
		var arr = [];
		var obj;
		angular.forEach($scope.selection, function(item, index){
			if(angular.isString(item)){
				obj = item;
			//}else{
				obj = "";
				if(item != ""){
					item = angular.fromJson(item);
				
					obj = {
							id:item.id,
							title:item.title
					};
					if(item.range){
						obj.filter = [$scope.sliderOptions[index].values];
					}
				}
			}
			arr.push(obj);	
		});
		return arr;
	};
	
	var setSliderOptions = function(index){
		//get selection that changed
		if($scope.selection[index] != ""){
			var selec = angular.fromJson($scope.selection[index]);
			selec.range = angular.fromJson(selec.range);
			var curr = angular.fromJson($scope.sliderOptions[index]);
			if(selec.range != []){
				curr.values = selec.range;
				curr.min = selec.range[0];
				curr.max = selec.range[1];
				$scope.sliderOptions[index] = curr;
			}
		}
	};
	
	// set up watch functions
	$scope.$watch('selection', function(newVal, oldVal){
		angular.forEach(newVal, function(item, i){
			if(item === oldVal[i]){
				//do nothing since they didn't change
			}else{
				//update the whole slider settings. 
				setSliderOptions(i);
				$scope.show[i] = true;
			}
		});
		queryobj.scriptOptions = buildScriptOptions();
	}, true);
	$scope.$watch(function(){
		return queryobj.scriptSelected;
	},function(newVal, oldVal){
		var temp = scriptobj.scriptMetadata;
		temp.then(function(result){
			if(result.scriptType == "columns"){
				$scope.inputs = result.inputs;
				angular.forEach($scope.inputs, function(input, index){
					$scope.selection[index] = "";
					$scope.show[index] = false;
					$scope.sliderOptions[index] = angular.copy($scope.sliderDefault);
				});
			}
		});
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
	
}).controller("ClusterPanelCtrl", function($scope, queryobj, scriptobj){
	$scope.inputs = [];

	$scope.$watch('inputs', function(newVal, oldVal){
		queryobj.scriptOptions = $scope.inputs;
	}, true);
	$scope.$watch(function(){
		return queryobj.scriptSelected;
	},function(newVal, oldVal){
		
		var temp = scriptobj.scriptMetadata;
		temp.then(function(result){
//				angular.forEach(result, function(item, index){
//					$scope.inputs[index] = item.param;
//				});
			if(result.scriptType == "cluster"){
				$scope.inputs = result.inputs;
				angular.forEach($scope.inputs, function(input, index){
					$scope.inputs[index].value = "";
				});
			}
		});
		
	});
})
