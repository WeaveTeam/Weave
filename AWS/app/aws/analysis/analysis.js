/**
 * Handle all Analysis Tab related work - Controllers to handle Analysis Tab
 */'use strict';

var analysis_mod = angular.module('aws.AnalysisModule', ['wu.masonry', 'ui.select2', 'ui.slider']);

/*analysis_mod.controller('AnalysisFiltersControllers', function($scope, $filter, dasboard_widget_service) {

	$scope.widtget_bricks = dasboard_widget_service.get_widget_bricks();
	
});*/

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
		
		dasboard_widget_service.enable_widget(element_id, $scope.box_enabled[element_id]);
		
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
	$scope.scriptList = [];

	$scope.populateScriptsBar = function() {
		$scope.script_focused = true;

		$scope.scriptList = queryService.getListOfScripts();

	};

	$scope.script_selected_set = function() {
		$scope.script_focused = true;
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

	queryService.queryObject.scriptSelected = "";
	$scope.$watch('scriptSelected', function() {
		if ($scope.scriptSelected != undefined && $scope.scriptSelected != "") {
			queryService.queryObject.scriptSelected = $scope.scriptSelected;
			queryService.getScriptMetadata($scope.scriptSelected, true);
			$scope.selection = [];
		} else {
			$scope.scriptList = queryService.getListOfScripts();
		}
	});

	//*Building the Input controls from the script metadata
	// array of column selected
	$scope.selection = [];

	$scope.inputs = [];

	$scope.$watchCollection(function() {
		return [queryService.dataObject.scriptMetadata, queryService.dataObject.columns];
	}, function() {
		if (queryService.dataObject.hasOwnProperty("scriptMetadata") && queryService.dataObject.columns.length) {
			$scope.inputs = [];
			if (queryService.dataObject.scriptMetadata.hasOwnProperty("inputs")) {
				$scope.inputs = queryService.dataObject.scriptMetadata.inputs;

				// look for default values in the db
				
				for (var i in $scope.inputs){
					for(var j in queryService.dataObject.columns) {
						if($scope.inputs[i]['default'] == queryService.dataObject.columns[j].publicMetadata.title) {
							$scope.selection[i] = angular.toJson({ id : queryService.dataObject.columns[j].id , title: queryService.dataObject.columns[j].publicMetadata.title  });
							break;
						}
					}
				}
			}
		}
	});

	$scope.$watchCollection(function() {
		return [queryService.queryObject.Indicator, $scope.inputs];
	}, function() {
		if(queryService.queryObject.Indicator.hasOwnProperty("id")) {
			for(var i in $scope.inputs) {
				if($scope.inputs[i].columnType.toLowerCase() == "indicator") {
					$scope.selection[i] = angular.toJson({ id : queryService.queryObject.Indicator.id, title : queryService.queryObject.Indicator.label });
				}
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

	queryService.queryObject.ScriptColumnRequest = [];

	$scope.$watchCollection('selection', function() {
		
		if(!$scope.selection.length) {
			queryService.queryObject.ScriptColumnRequest = [];
		}
		
		for (var i = 0; i < $scope.selection.length; i++) {
			if ($scope.selection != undefined) {
				if ($scope.selection[i] != undefined && $scope.selection[i] != "") {
					var selection = angular.fromJson($scope.selection[i]);
					if (queryService.queryObject.ScriptColumnRequest[i]) {
						queryService.queryObject.ScriptColumnRequest[i] = selection;
					} else {
						queryService.queryObject.ScriptColumnRequest[i] = selection;
					}
				} 
			} // end if undefined
		}
	});


	$scope.$watchCollection(function() {
		return queryService.queryObject.ScriptColumnRequest;
	}, function() {
		if (queryService.queryObject.ScriptColumnRequest != undefined) {
			for (var i = 0; i < queryService.queryObject.ScriptColumnRequest.length; i++) {
				if (queryService.queryObject.ScriptColumnRequest[i] != undefined && queryService.queryObject.ScriptColumnRequest[i] != "") {
					$scope.selection[i] = angular.toJson(queryService.queryObject.ScriptColumnRequest[i]);
				}
			}
		}
	});
});
