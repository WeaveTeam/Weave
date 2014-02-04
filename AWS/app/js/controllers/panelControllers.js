/**
 *  Individual Panel Type Controllers
 *  These controllers will be specified via the panel directive
 */
angular.module("aws.panelControllers", [])
.controller("ScriptCtrl", function($scope, queryService){
	
	// array of column selected
	$scope.selection = []; 
	
	// array of filter types, can either be categorical (true) or continuous (false).
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
	
	// array of booleans, either true of false if we want filtering enabled
	$scope.enabled = [];
	
	$scope.scriptList = queryService.getListOfScripts();
	
	
	$scope.$watch('scriptSelected', function() {
		if($scope.scriptSelected != undefined && $scope.scriptSelected != "") {
				queryService.queryObject.scriptSelected = $scope.scriptSelected;
				queryService.getScriptMetadata($scope.scriptSelected, true);
		}
	});
	
	$scope.$watch(function() {
		return queryService.queryObject.scriptSelected;
	}, function() {
		$scope.scriptSelected = queryService.queryObject.scriptSelected;
	});
	
	$scope.inputs;
	$scope.$watch(function(){
		return queryService.dataObject.scriptMetadata;
	}, function() {
		if(queryService.dataObject.hasOwnProperty("scriptMetadata")) {
			$scope.inputs = [];
			if(queryService.dataObject.scriptMetadata.hasOwnProperty("inputs")) {
					$scope.inputs = queryService.dataObject.scriptMetadata.inputs;
			}
		}
	});
	
	$scope.columns = [];
	
	$scope.$watch(function(){
		return queryService.queryObject.dataTable;
	}, function(){
		queryService.getDataColumnsEntitiesFromId(queryService.queryObject.dataTable.id, true);
		// reset these values when the data table changes
	});
	

	$scope.$watch(function(){
		return queryService.dataObject.columns;
	}, function(){
		if ( queryService.dataObject.columns != undefined ) {
			var columns = queryService.dataObject.columns;
			var orderedColumns = {};
			orderedColumns.all = [];
			for(var i = 0; i  < columns.length; i++) {
				if (columns[i].publicMetadata.hasOwnProperty("aws_metadata")) {
					var column = columns[i];
					orderedColumns.all.push({ id : column.id , title : column.publicMetadata.title } );
					var aws_metadata = angular.fromJson(column.publicMetadata.aws_metadata);
					if(aws_metadata.hasOwnProperty("columnType")) {
						var key = aws_metadata.columnType;
						if(!orderedColumns.hasOwnProperty(key)) {
							orderedColumns[key] = [ { id : column.id, title : column.publicMetadata.title }];
						} else {
							orderedColumns[key].push({
														id : column.id,
														title : column.publicMetadata.title
							});
						}
					}
				}
			}
			$scope.columns = orderedColumns;
		}
	});
	
	queryService.queryObject.FilteredColumnRequest = [];

	$scope.$watchCollection('selection', function(newVal, oldVal){
		for(var i = 0; i < $scope.selection.length; i++) {
				if($scope.selection != undefined) {
					if ($scope.selection[i] != undefined && $scope.selection[i] != ""){
						var selection = angular.fromJson($scope.selection[i]);
						if(queryService.queryObject.FilteredColumnRequest[i]){
							queryService.queryObject.FilteredColumnRequest[i].column = selection;
						} else {
							queryService.queryObject.FilteredColumnRequest[i] = {column : selection};
						}
						var columnSelected = selection;
						var allColumns = queryService.dataObject.columns;
						var column;
						for (var j = 0; j < allColumns.length; j++) {
							if(columnSelected != undefined && columnSelected != "") {
								if (columnSelected.id == allColumns[j].id) {
									column = allColumns[j];
								}
							}
						}
						if(column != undefined) {
							if(column.publicMetadata.hasOwnProperty("aws_metadata")) {
								var metadata = angular.fromJson(column.publicMetadata.aws_metadata);
								if (metadata.hasOwnProperty("varType")) {
									if (metadata.varType == "continuous") {
										$scope.filterType[i] = "continuous";
										if(metadata.hasOwnProperty("varRange")) {
											$scope.show[i] = true;
											$scope.sliderOptions[i] = { range:true, min: metadata.varRange[0], max: metadata.varRange[1]};
										}
									} else if (metadata.varType == "categorical") {
										$scope.show[i] = true;
										$scope.filterType[i] = "categorical";
										if(metadata.hasOwnProperty("varValues")) {
											console.log(metadata.varValues);
											$scope.categoricalOptions[i] = queryService.getDataMapping(metadata.varValues);
										}
									}
								}
							} 
						}
					} // end if ""
				} // end if undefined
			}
	});
		
	$scope.$watchCollection('filterValues', function(){
		//console.log($scope.filterValues);
		for(var i = 0; i < $scope.filterValues.length; i++) {
			if(($scope.filterValues != undefined) && $scope.filterValues != "") {
				if($scope.filterValues[i] != undefined && $scope.filterValues[i] != []) {
					
					var temp = $.map($scope.filterValues[i],function(item){
						return angular.fromJson(item);
					});
					
					if(!queryService.queryObject.FilteredColumnRequest[i].hasOwnProperty("filters")) {
						queryService.queryObject.FilteredColumnRequest[i].filters = {};
					}
					
					if ($scope.filterType[i] == "categorical") { 
						queryService.queryObject.FilteredColumnRequest[i].filters.filterValues = temp;
					} else if ($scope.filterType[i] == "continuous") { // continuous, we want arrays of ranges
						queryService.queryObject.FilteredColumnRequest[i].filters.filterValues = [temp];
					}
				} 
			}
		}
	});
	$scope.$watchCollection('enabled', function(){
		if($scope.enabled != undefined) {
			for(var i = 0; i < $scope.enabled.length; i++) {
				if(!queryService.queryObject.FilteredColumnRequest[i].hasOwnProperty("filters")) {
					queryService.queryObject.FilteredColumnRequest[i].filters = {};
				}
				
				if($scope.enabled[i] != undefined) {
					queryService.queryObject.FilteredColumnRequest[i].filters.enabled = $scope.enabled[i];
				}
				
//				console.log($scope.enabled);
//				console.log($scope.filterType);
//				console.log($scope.show);
			}
		}
	});
	
	$scope.$watchCollection(function(){
			return queryService.queryObject.FilteredColumnRequest;
	}, function() {
		if(queryService.queryObject.FilteredColumnRequest != undefined) {
			for(var i = 0; i < queryService.queryObject.FilteredColumnRequest.length; i++) {
				if (queryService.queryObject.FilteredColumnRequest[i] != undefined && queryService.queryObject.FilteredColumnRequest[i] != "") {
					if (queryService.queryObject.FilteredColumnRequest[i].hasOwnProperty("column")) {
						$scope.selection[i] = angular.toJson(queryService.queryObject.FilteredColumnRequest[i].column);
					}
					
					if (queryService.queryObject.FilteredColumnRequest[i].hasOwnProperty("filters")) {
						
						if(queryService.queryObject.FilteredColumnRequest[i].filters.hasOwnProperty("filterValues")) {

							$scope.show[i] = true;
							
							if(queryService.queryObject.FilteredColumnRequest[i].filters.filterValues[0].constructor == Object) {
								
								$scope.filterType[i] = "categorical";
								var temp =  $.map(queryService.queryObject.FilteredColumnRequest[i].filters.filterValues, function(item){
									return angular.toJson(item);
								});
								$scope.filterValues[i] = temp;
								
							} else if(queryService.queryObject.FilteredColumnRequest[i].filters.filterValues[0].constructor == Array) {
								$scope.filterType[i] = "continuous";
								$scope.filterValues[i] = queryService.queryObject.FilteredColumnRequest[i].filters.filterValues[0];
							}
						} 
						if(queryService.queryObject.FilteredColumnRequest[i].filters.hasOwnProperty("enabled")) {
							$scope.enabled[i] = queryService.queryObject.FilteredColumnRequest[i].filters.enabled;
						} 
					} 
				}
			}
		}
	});
})

// MAP TOOL CONTROLLER
.controller("MapToolPanelCtrl", function($scope, queryService){
	
	queryService.queryObject.MapTool = {
											enabled : "false",
											selected : { 
												id : "",
												title : "",
												keyType : ""
											}
									   };
	
	queryService.getGeometryDataColumnsEntities();
	$scope.geomTables = [];
	
	$scope.$watch(function() {
		return queryService.dataObject.geometryColumns;
	}, function () {
		if(queryService.dataObject.hasOwnProperty('geometryColumns')){
			var geometryColumns = queryService.dataObject.geometryColumns;
			for (var i = 0; i < geometryColumns.length; i++) {
				$scope.geomTables.push( {
											id : geometryColumns[i].id,
											title : geometryColumns[i].publicMetadata.title,
											keyType : geometryColumns[i].publicMetadata.keyType
				});
			}
		}
	});

	$scope.$watch('enabled', function() {
		if($scope.enabled != undefined) {
			queryService.queryObject.MapTool.enabled = $scope.enabled;
		}
	});
	
	$scope.$watch(function(){
		return queryService.queryObject.MapTool.enabled;
	}, function() {
		$scope.enabled = queryService.queryObject.MapTool.enabled;
	});
		
	$scope.$watch('selected', function() {
		if($scope.selected != undefined && $scope.selected != "") {
			queryService.queryObject.MapTool.selected = angular.fromJson($scope.selected);
		}
	});
	
	$scope.$watch(function(){
		return queryService.queryObject.MapTool.selected;
	}, function() {
		$scope.selected = angular.toJson(queryService.queryObject.MapTool.selected);	
	});
})

// BARCHART CONTROLLER
.controller("BarChartToolPanelCtrl", function($scope, queryService){

	queryService.queryObject.BarChartTool = { 
											 enabled : false,
											 heights : [],
											 sort : "",
											 label : ""
											};

	$scope.options = [];
	
	$scope.$watch(function(){
		return queryService.dataObject.scriptMetadata;
	}, function() {
		$scope.options = [];
		if(queryService.dataObject.hasOwnProperty("scriptMetadata")) {
			if(queryService.dataObject.scriptMetadata.hasOwnProperty("outputs")) {
				var outputs = queryService.dataObject.scriptMetadata.outputs;
				for( var i = 0; i < outputs.length; i++) {
					$scope.options.push(outputs[i].param);
				}
			}
		}
	});		
	
	$scope.$watch('enabled', function() {
		if($scope.enabled != undefined) {
			queryService.queryObject.BarChartTool.enabled = $scope.enabled;
		}
	});
	
	$scope.$watch(function(){
		return queryService.queryObject.BarChartTool.enabled;
	}, function() {
		$scope.enabled = queryService.queryObject.BarChartTool.enabled;
	});
	
	$scope.$watch('heights', function() {

		if($scope.heights != undefined) {
			queryService.queryObject.BarChartTool.heights = $scope.heights;
		}
		
	});
	
	$scope.$watch(function(){
		return queryService.queryObject.BarChartTool.heights;
	}, function() {
		$scope.heights = queryService.queryObject.BarChartTool.heights;	
	});

	$scope.$watch('sort', function() {
		if($scope.sort != undefined) {
			queryService.queryObject.BarChartTool.sort = $scope.sort;
		}
		
	});
	
	$scope.$watch(function(){
		return queryService.queryObject.BarChartTool.sort;
	}, function() {
		$scope.sort = queryService.queryObject.BarChartTool.sort;	
	});
	
	$scope.$watch('label', function() {
		if($scope.label != undefined) {
			queryService.queryObject.BarChartTool.label = $scope.label;
		}
		
	});
	
	$scope.$watch(function(){
		return queryService.queryObject.BarChartTool.label;
	}, function() {
		$scope.label = queryService.queryObject.BarChartTool.label;	
	});
	
})

// DATA TABLE CONTROLLER
.controller("DataTablePanelCtrl", function($scope, queryService){
	queryService.queryObject.DataTableTool = { 
											 enabled : false,
											 selected : []
											};

	$scope.options = [];
	
	$scope.$watch(function(){
		return queryService.dataObject.scriptMetadata;
	}, function() {
		$scope.options = [];
		if(queryService.dataObject.hasOwnProperty("scriptMetadata")) {
			if(queryService.dataObject.scriptMetadata.hasOwnProperty("outputs")) {
				var outputs = queryService.dataObject.scriptMetadata.outputs;
				for( var i = 0; i < outputs.length; i++) {
					$scope.options.push(outputs[i].param);
				}
			}
		}
	});

	
	$scope.$watch('enabled', function() {
		if($scope.enabled != undefined) {
			queryService.queryObject.DataTableTool.enabled = $scope.enabled;
		}
	});
	
	$scope.$watch(function(){
		return queryService.queryObject.DataTableTool.enabled;
	}, function() {
		$scope.enabled = queryService.queryObject.DataTableTool.enabled;
	});
	
	$scope.$watch('selected', function() {
		if($scope.selected != undefined) {
			queryService.queryObject.DataTableTool.selected = $scope.selected;
		}
		
	});
	
	$scope.$watch(function(){
		return queryService.queryObject.DataTableTool.selected;
	}, function() {
		$scope.selected = queryService.queryObject.DataTableTool.selected;	
	});
})

// SCATTERPLOT CONTROLLER
.controller("ScatterPlotToolPanelCtrl", function($scope, queryService) {
	queryService.queryObject.ScatterPlotTool = { 
											 enabled : false,
											 X : "",
											 Y : "" 
											};

	$scope.options = [];
	
	$scope.$watch(function(){
		return queryService.dataObject.scriptMetadata;
	}, function() {
		if(queryService.dataObject.hasOwnProperty("scriptMetadata")) {
			$scope.options = [];
			if(queryService.dataObject.scriptMetadata.hasOwnProperty("outputs")) {
				var outputs = queryService.dataObject.scriptMetadata.outputs;
				for( var i = 0; i < outputs.length; i++) {
					$scope.options.push(outputs[i].param);
				}
			}
		}
	});

	
	$scope.$watch('enabled', function() {
		if($scope.enabled != undefined){
			queryService.queryObject.ScatterPlotTool.enabled = $scope.enabled;
		}
		
	});
	$scope.$watch(function(){
		return queryService.queryObject.ScatterPlotTool.enabled;
	}, function() {
		$scope.enabled = queryService.queryObject.ScatterPlotTool.enabled;	
	});

	$scope.$watch(function(){
		return queryService.queryObject.ScatterPlotTool.X;
	}, function() {
		$scope.XSelection = queryService.queryObject.ScatterPlotTool.X;
	});

	$scope.$watch('XSelection', function() {
		if($scope.XSelection != undefined) {
			queryService.queryObject.ScatterPlotTool.X = $scope.XSelection;
		}
	});
	
	$scope.$watch(function(){
		return queryService.queryObject.ScatterPlotTool.Y;
	}, function() {
		$scope.YSelection = queryService.queryObject.ScatterPlotTool.Y;
	});

	$scope.$watch('YSelection', function() {
		if($scope.YSelection != undefined) {
			queryService.queryObject.ScatterPlotTool.Y = $scope.YSelection;
		}
	});
})


// COLOR CONTROLLER
.controller("ColorColumnPanelCtrl", function($scope, queryService){

	queryService.queryObject.ColorColumn = { 
											 enabled : false,
											 selected : ""
											};

	$scope.options = [];
	
	$scope.$watch(function(){
		return queryService.dataObject.scriptMetadata;
	}, function() {
		if(queryService.dataObject.hasOwnProperty("scriptMetadata")) {
			$scope.options = [];
			if(queryService.dataObject.scriptMetadata.hasOwnProperty("outputs")) {
				var outputs = queryService.dataObject.scriptMetadata.outputs;
				for( var i = 0; i < outputs.length; i++) {
					$scope.options.push(outputs[i].param);
				}
			}
		}
	});
	
		
	/*** double binding *****/
	$scope.$watch('enabled', function() {
		if($scope.enabled != undefined) {
			queryService.queryObject.ColorColumn.enabled = $scope.enabled;
		}
	});
	
	$scope.$watch(function(){
		return queryService.queryObject.ColorColumn.enabled;
	}, function() {
		$scope.enabled = queryService.queryObject.ColorColumn.enabled;
	});

	$scope.$watch('selected', function() {
		if($scope.selected != undefined) {
			queryService.queryObject.ColorColumn.selected = $scope.selected;
		}
		
	});
	
	$scope.$watch(function(){
		return queryService.queryObject.ColorColumn.selected;
	}, function() {
		$scope.selected = queryService.queryObject.ColorColumn.selected;	
	});
	/**************************/
});
