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
	
	$scope.columns = [];
	
	$scope.$watch(function(){
		return queryService.queryObject.dataTable;
	}, function(){
		if(queryService.queryObject.hasOwnProperty("dataTable")) {
			if(queryService.queryObject.dataTable.hasOwnProperty("id")) {
				$scope.columns = queryService.getDataColumnsEntitiesFromId(queryService.queryObject.dataTable.id);
			}
		}
	});
	

	$scope.$watch(function(){		// watch the selected script for changes
			return queryService.queryObject.scriptSelected;
	},function(){   	
		$scope.inputs = queryService.getScriptMetadata(queryService.queryObject.scriptSelected).then(function(result){			// reinitialize and apply to model
			return result.inputs;
		});
	});
	
	// array of column selected
	$scope.selection = []; 
	
	// array of filter types, can either be categorical or continuous.
	$scope.filterType = [];
	
	// array of boolean values, true when the column it is possible to apply a filter on the column, 
	// we basically check if the metadata has varType, min, max etc...
	$scope.show = [];
	
	// the slider options for the columns, min, max etc... Array of object, comes from the metadata
	$scope.sliderOptions = [];
	
	// the categorical options for the columns, Array of string Arrays, comes from metadata, 
	// this is provided in the ng-repeat for the select2
	$scope.categoricalOptions = [];
	
	// array of filter values. This is used for the model and is sent to the queryObject, each element is either
	// [min, max] or ["a", "b", "c", etc...]
	$scope.filterValues = [];
	
	$scope.$watch('selection', function(){
		for(var i = 0; i < $scope.selection.length; i++) {
			if ($scope.selection[i] != ""){
				var column = angular.fromJson($scope.selection[i]);
				if(column.publicMetadata.hasOwnProperty("aws_metadata")) {
					var metadata = angular.fromJson(column.publicMetadata.aws_metadata);
					console.log(metadata);
					if (metadata.hasOwnProperty("varType")) {
						if (metadata.varType == "continous") {
							$scope.filterType[i] = "continuous";
							if(metadata.hasOwnProperty("varRange")) {
								$scope.show[i] = true;
								$scope.sliderOptions[i] = { min: metadata.varRange[0], max: metadata.varRange[1], step : (varRange[1] - varRange[0])/ 100 };
							}
						} else if (metadata.varType == "categorical") {
							$scope.filterType[i] = "categorical";
							if(metadata.hasOwnProperty("varValues")) {
								$scope.show[i] = true;
								$scope.categoricalOptions[i] = metadata.varValues;
								console.log($scope.categoricalOptions);
							}
						}
					}
				}
			}
		}
	}, true);
	
	$scope.$watch('filterValues', function() {
		for(var i = 0; i < $scope.selection.length; i++) {
			queryService.queryObject['ColumnFilterRequest'][i] = {
					title : angular.fromJson($scope.selection[i]).publicMetadata.title,
					id : $scope.selection[i].id,
					Filters : $scope.filterValues[i]
			};
		}
	}, true);
})
.controller("RunQueryCtrl", function($scope, queryService){
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
	queryService.queryObject['MapTool'] = {};
	$scope.$watch('enabled', function() {
		queryService.queryObject.MapTool['enabled'] = $scope.enabled;
	});
	
	$scope.options = queryService.getGeometryDataColumnsEntities();
	
	
	$scope.$watch('selection', function() {
		if($scope.selection != "") {
			var metadata = angular.fromJson($scope.selection);
				queryService.queryObject['MapTool']['geometryColumn'] = {
						id : metadata.id,
						title : metadata.publicMetadata.title,
						keyType : metadata.publicMetadata.keyType
				};
		}
	});
	
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