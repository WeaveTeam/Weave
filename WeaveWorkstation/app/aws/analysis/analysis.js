/**
 * Handle all Analysis Tab related work - Controllers to handle Analysis Tab
 */'use strict';

var analysis_mod = angular.module('aws.AnalysisModule', ['wu.masonry', 'ui.select2']);

analysis_mod.controller('WidgetsController', function($scope, $filter, dasboard_widget_service) {

	$scope.box_enabled = {};
	$scope.dt_focused = true;
	$scope.script_focused = false;
	$scope.dash_focused = false;
	
	$scope.widtget_bricks = dasboard_widget_service.get_widget_bricks();
	$scope.general_tools = dasboard_widget_service.get_tool_list('indicatorfilter');
	$scope.tool_list = dasboard_widget_service.get_tool_list('visualization');
	$scope.filter_tools = dasboard_widget_service.get_tool_list('datafilter');

	$scope.add_widget = function(element_id) {
		
		dasboard_widget_service.add_widget_bricks(element_id);
		try{
			
			$scope.box_enabled[element_id] = true;
		}
		catch(e){
			
				$scope.box_enabled.push({key: element_id, value : true});
			}
		
	};

	$scope.remove_widget = function(widget_index) {
		dasboard_widget_service.remove_widget_bricks(widget_index);
	};

	$scope.enable_widget = function(id) {
		dasboard_widget_service.enable_widget(id, $scope.box_enabled[id]);
	};

});


analysis_mod.config(function($selectProvider) {
	angular.extend($selectProvider.defaults, {
		caretHTML : '&nbsp'
	});
});

/*
 *
 * Clean up
 * TODO: Seperate the dtatable from scripts bar
 *
 */

analysis_mod.controller("ScriptsBarController", function($scope, queryService) {

	$scope.setting_loaded = false;
	$scope.secret_state = false;
	$scope.show_load = false;

	/*
	 *
	 * Data Table Section
	 *
	 *
	 */
	queryService.queryObject.dataTable = {
		id : -1,
		title : ""
	};

	/*??*/
	queryService.getDataTableList();
	$scope.dataTableList = [];
	var dataTable;

	$scope.$watch(function() {
		return queryService.dataObject.dataTableList;
	}, function() {
		if (queryService.dataObject.hasOwnProperty("dataTableList")) {
			for (var i = 0; i < queryService.dataObject.dataTableList.length; i++) {
				dataTable = queryService.dataObject.dataTableList[i];
				$scope.dataTableList.push({
					id : dataTable.id,
					title : dataTable.title
				});
			}
		}
	});

	$scope.$watch('dataTable', function() {
		if ($scope.dataTable != undefined && $scope.dataTable != "") {
			var dataTable_s = angular.fromJson($scope.dataTable);
			queryService.queryObject.dataTable = dataTable_s;
			if (dataTable_s.hasOwnProperty('id') && dataTable_s.id != null) {
				queryService.getDataColumnsEntitiesFromId(dataTable_s.id);
			}

		}
		/*console.log(angular.toJson(queryService.queryObject));*/
	});

	/*
	 *
	 *
	 * Search Bar section
	 *
	 *
	 */

	$scope.scriptSelected = '';
	$scope.scriptList = []

	$scope.populateScriptsBar = function() {
		$scope.script_focused = true;

		$scope.scriptList = queryService.getListOfScripts();

	};

	$scope.script_selected_set = function() {
		if ($scope.setting_loaded == false) {
			$scope.show_load = true;
		};

		//$scope.setting_data_loaded = false;

	};

	$scope.enable_settings = function(load_flag) {
		if (load_flag) {
			$scope.show_load = false;
			$scope.setting_loaded = true;
		}

	};

	$scope.enable_dashboard = function() {
		$scope.dash_focused = true;

	};

	$scope.$watch('scriptSelected', function() {
		if ($scope.scriptSelected != undefined && $scope.scriptSelected != "") {
			queryService.queryObject.scriptSelected = $scope.scriptSelected;
			queryService.getScriptMetadata($scope.scriptSelected, true);

		} else {
			$scope.scriptList = queryService.getListOfScripts();
		}
	});

	//*Building the Input controls from the script metadata
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

	/*$scope.$watch(function() {
	 return queryService.queryObject.scriptSelected;
	 }, function() {
	 $scope.scriptSelected = queryService.queryObject.scriptSelected;
	 });
	 */
	$scope.inputs

	$scope.$watch(function() {
		return queryService.dataObject.scriptMetadata;
	}, function() {
		if (queryService.dataObject.hasOwnProperty("scriptMetadata")) {
			$scope.inputs = [];
			if (queryService.dataObject.scriptMetadata.hasOwnProperty("inputs")) {
				$scope.inputs = queryService.dataObject.scriptMetadata.inputs;
			}
		}
	});

	$scope.columns = [];

	$scope.$watch(function() {
		return queryService.queryObject.dataTable;
	}, function() {
		queryService.getDataColumnsEntitiesFromId(queryService.queryObject.dataTable.id, true);
		// reset these values when the data table changes
	});

	$scope.$watch(function() {
		return queryService.dataObject.columns;
	}, function() {
		var load_flag = false;
		if (queryService.dataObject.columns != undefined) {
			var columns = queryService.dataObject.columns;
			var orderedColumns = {};
			orderedColumns.all = [];
			for (var i = 0; i < columns.length; i++) {
				if (columns[i].publicMetadata.hasOwnProperty("aws_metadata")) {
					var column = columns[i];
					orderedColumns.all.push({
						id : column.id,
						title : column.publicMetadata.title
					});
					var aws_metadata = angular.fromJson(column.publicMetadata.aws_metadata);
					if (aws_metadata.hasOwnProperty("columnType")) {
						load_flag = true
						var key = aws_metadata.columnType;
						if (!orderedColumns.hasOwnProperty(key)) {
							orderedColumns[key] = [{
								id : column.id,
								title : column.publicMetadata.title
							}];
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
			$scope.enable_settings(load_flag);
		}

	});

	queryService.queryObject.FilteredColumnRequest = [];

	$scope.$watchCollection('selection', function(newVal, oldVal) {
		for (var i = 0; i < $scope.selection.length; i++) {
			if ($scope.selection != undefined) {
				if ($scope.selection[i] != undefined && $scope.selection[i] != "") {
					var selection = angular.fromJson($scope.selection[i]);
					if (queryService.queryObject.FilteredColumnRequest[i]) {
						queryService.queryObject.FilteredColumnRequest[i].column = selection;
					} else {
						queryService.queryObject.FilteredColumnRequest[i] = {
							column : selection
						};
					}
					var columnSelected = selection;
					var allColumns = queryService.dataObject.columns;
					var column;
					for (var j = 0; j < allColumns.length; j++) {
						if (columnSelected != undefined && columnSelected != "") {
							if (columnSelected.id == allColumns[j].id) {
								column = allColumns[j];
							}
						}
					}
					if (column != undefined) {
						if (column.publicMetadata.hasOwnProperty("aws_metadata")) {
							var metadata = angular.fromJson(column.publicMetadata.aws_metadata);
							if (metadata.hasOwnProperty("varType")) {
								if (metadata.varType == "continuous") {
									$scope.filterType[i] = "continuous";
									if (metadata.hasOwnProperty("varRange")) {
										$scope.show[i] = true;
										$scope.sliderOptions[i] = {
											range : true,
											min : metadata.varRange[0],
											max : metadata.varRange[1]
										};
									}
								} else if (metadata.varType == "categorical") {
									$scope.show[i] = true;
									$scope.filterType[i] = "categorical";
									if (metadata.hasOwnProperty("varValues")) {
										$scope.categoricalOptions[i] = metadata.varValues;
									}
								}
							}
						}
					}
				} // end if ""
			} // end if undefined
		}
	});

	$scope.$watchCollection('filterValues', function() {
		//console.log($scope.filterValues);
		for (var i = 0; i < $scope.filterValues.length; i++) {
			if (($scope.filterValues != undefined) && $scope.filterValues != "") {
				if ($scope.filterValues[i] != undefined && $scope.filterValues[i] != []) {

					var temp = $.map($scope.filterValues[i], function(item) {
						return angular.fromJson(item);
					});

					if (!queryService.queryObject.FilteredColumnRequest[i].hasOwnProperty("filters")) {
						queryService.queryObject.FilteredColumnRequest[i].filters = {};
					}

					if ($scope.filterType[i] == "categorical") {
						queryService.queryObject.FilteredColumnRequest[i].filters.filterValues = temp;
					} else if ($scope.filterType[i] == "continuous") {// continuous, we want arrays of ranges
						queryService.queryObject.FilteredColumnRequest[i].filters.filterValues = [temp];
					}
				}
			}
		}
	});

	$scope.$watchCollection('enabled', function() {
		if ($scope.enabled != undefined) {
			for (var i = 0; i < $scope.enabled.length; i++) {
				if (!queryService.queryObject.FilteredColumnRequest[i].hasOwnProperty("filters")) {
					queryService.queryObject.FilteredColumnRequest[i].filters = {};
				}

				if ($scope.enabled[i] != undefined) {
					queryService.queryObject.FilteredColumnRequest[i].filters.enabled = $scope.enabled[i];
				}

				//				console.log($scope.enabled);
				//				console.log($scope.filterType);
				//				console.log($scope.show);
			}
		}
	});

	$scope.$watchCollection(function() {
		return queryService.queryObject.FilteredColumnRequest;
	}, function() {
		if (queryService.queryObject.FilteredColumnRequest != undefined) {
			for (var i = 0; i < queryService.queryObject.FilteredColumnRequest.length; i++) {
				if (queryService.queryObject.FilteredColumnRequest[i] != undefined && queryService.queryObject.FilteredColumnRequest[i] != "") {
					if (queryService.queryObject.FilteredColumnRequest[i].hasOwnProperty("column")) {
						$scope.selection[i] = angular.toJson(queryService.queryObject.FilteredColumnRequest[i].column);
					}

					if (queryService.queryObject.FilteredColumnRequest[i].hasOwnProperty("filters")) {

						if (queryService.queryObject.FilteredColumnRequest[i].filters.hasOwnProperty("filterValues")) {

							$scope.show[i] = true;

							if (queryService.queryObject.FilteredColumnRequest[i].filters.filterValues[0].constructor == Object) {

								$scope.filterType[i] = "categorical";
								var temp = $.map(queryService.queryObject.FilteredColumnRequest[i].filters.filterValues, function(item) {
									return angular.toJson(item);
								});
								$scope.filterValues[i] = temp;

							} else if (queryService.queryObject.FilteredColumnRequest[i].filters.filterValues[0].constructor == Array) {
								$scope.filterType[i] = "continuous";
								$scope.filterValues[i] = queryService.queryObject.FilteredColumnRequest[i].filters.filterValues[0];
							}
						}
						if (queryService.queryObject.FilteredColumnRequest[i].filters.hasOwnProperty("enabled")) {
							$scope.enabled[i] = queryService.queryObject.FilteredColumnRequest[i].filters.enabled;
						}
					}
				}
			}
		}
	});
});
