/**
 * Handle all Analysis Tab related work - Controllers to handle Analysis Tab
 */
'use strict';

var analysis_mod = angular.module('aws.AnalysisModule', ['wu.masonry', 'ui.select2', 'ui.slider']);

analysis_mod.controller('AnalysisFiltersControllers', function($scope, $filter, dasboard_widget_service) {

	$scope.filter_widget_bricks = dasboard_widget_service.get_filter_widget_bricks();
	
});

analysis_mod.controller('AnalysisMainCtrl', function($scope, $location, $anchorScroll){
  $scope.scrollTo = function(id) {
    $location.hash(id);
    
    $anchorScroll();
  };
});

analysis_mod.controller('SaveVisualizationCtrl', function($scope, $filter, dasboard_widget_service) {
	
	
	
});


analysis_mod.controller('WidgetsController', function($scope, $filter, dasboard_widget_service) {

	
	$scope.widget_service = dasboard_widget_service;
	
	$scope.box_enabled = {};
	$scope.dt_focused = true;
	$scope.script_focused = false;
	$scope.dash_focused = false;
	
	// $scope.general_tools = dasboard_widget_service.get_tool_list('indicatorfilter');
	// $scope.filter_tools = dasboard_widget_service.get_tool_list('datafilter');

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

	
	$scope.content_tools = [{
		id : 'Indicator',
		title : 'Indicator',
		template_url : 'aws/analysis/indicator/indicator.tpl.html',
		description : 'Choose an Indicator for the Analysis',
		category : 'indicatorfilter'
	},
	{
		id : 'GeographyFilter',
		title : 'Geography Filter',
		template_url : 'aws/analysis/data_filters/geography.tpl.html',
		description : 'Filter data by States and Counties',
		category : 'datafilter'

	},
	{
		id : 'TimePeriodFilter',
		title : 'Time Period Filter',
		template_url : 'aws/analysis/data_filters/time_period.tpl.html',
		description : 'Filter data by Time Period',
		category : 'datafilter'
	},
	{
		id : 'ByVariableFilter',
		title : 'By Variable Filter',
		template_url : 'aws/analysis/data_filters/by_variable.tpl.html',
		description : 'Filter data by Variables',
		category : 'datafilter'
	},
	{
		id : 'ScriptSettings',
		title : 'Script Settings',
		template_url : 'aws/analysis/script_settings.tpl.html',
		description : 'Script Settings',
		category : 'datafilter'
	}
	
	/*{
		id : 'Visualization',
		title : 'Configure Visulas',
		template_url : 'aws/analysis/visualization.tpl.html',
		description : 'Configure output chart for Weave',
		category : 'visualization'
	}*/];
	
	// This sets the service variable to the queryService 
	$scope.service = queryService;
	
	
	$scope.setting_loaded = false;
	$scope.secret_state = false;
	$scope.show_load = false;


	queryService.getDataTableList(true);
	queryService.getListOfScripts(true);

	$scope.enable_dashboard = function() {
		$scope.dash_focused = true;

	};
	
	$scope.$watchCollection(function() {
		return [queryService.dataObject.scriptMetadata, queryService.dataObject.columns];
	}, function(newValue, oldValue) {
		
		if(newValue != oldValue) {
			var scriptMetadata = newValue[0];
			var columns = newValue[1];
			
			if(scriptMetadata && columns) {
				if(scriptMetadata.hasOwnProperty("inputs")) {
					for(var i in scriptMetadata.inputs) {
						var input = scriptMetadata.inputs[i];
						if(input.type == "column") {
							for(var j in columns) {
								var column = columns[j];
								if(input.hasOwnProperty("default")) {
									if(column.title == input['default']) {
										queryService.queryObject.scriptOptions[input.param] = angular.toJson(column);
										break;
									}
								}
							}
						}
					}
				}
			}
		}
	});
	
	$scope.$watch(function() {
		return queryService.queryObject.scriptOptions;
	}, function(newValue, oldValue) {
		if(newValue != oldValue) {
			var scriptOptions = newValue;
			for(var key in scriptOptions) { 
				var option = scriptOptions[key];
				if(option) {
					if(angular.fromJson(option).hasOwnProperty("columnType")) {
						if(angular.fromJson(option).columnType.toLowerCase() == "indicator") {
							queryService.queryObject.Indicator = option;
						}
					}
				}
			}
			
		}
	}, true);
	
	$scope.$watch(function() {
		return queryService.queryObject.Indicator;
	}, function(newValue, oldValue) {
		if(newValue != oldValue) {
			var indicator = newValue;
			for(var key in queryService.queryObject.scriptOptions) { 
				var option = queryService.queryObject.scriptOptions[key];
				if(option){
					if(angular.fromJson(option).hasOwnProperty("columnType")) {
						if(angular.fromJson(option).columnType.toLowerCase() == "indicator") {
							queryService.queryObject.scriptOptions[key] = indicator;
						}
					}
				} else {
					if(queryService.dataObject.scriptMetadata.hasOwnProperty("inputs")) {
						for(var i in queryService.dataObject.scriptMetadata.inputs) {
							var metadata = queryService.dataObject.scriptMetadata.inputs[i];
							if(metadata.hasOwnProperty('type')) {
								if(metadata.type == 'column') {
									if(metadata.hasOwnProperty('columnType')) {
										if(metadata.columnType.toLowerCase() == "indicator") {
											queryService.queryObject.scriptOptions[metadata.param] = indicator;
										}
									}
								}
							}
						}
					}
				}
			}
		}
	});
	
});
