/**
 * Handle all Analysis Tab related work - Controllers to handle Analysis Tab
 */'use strict';

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

	$scope.box_enabled = {};
	$scope.dt_focused = true;
	$scope.script_focused = false;
	$scope.dash_focused = false;
	
	$scope.widtget_bricks = dasboard_widget_service.get_widget_bricks();
	// $scope.general_tools = dasboard_widget_service.get_tool_list('indicatorfilter');
	$scope.tool_list = dasboard_widget_service.get_tool_list('visualization');
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

//	$scope.$watchCollection(function() {
//		return [queryService.dataObject.scriptMetadata, queryService.dataObject.columns];
//	}, function() {
//		if (queryService.dataObject.hasOwnProperty("scriptMetadata") && queryService.dataObject.columns.length) {
//			$scope.inputs = [];
//			if (queryService.dataObject.scriptMetadata.hasOwnProperty("inputs")) {
//				$scope.inputs = queryService.dataObject.scriptMetadata.inputs;
//
//				// look for default values in the db
//
//				for (var i in $scope.inputs){
//					for(var j in queryService.dataObject.columns) {
//						if($scope.inputs[i]['default'] == queryService.dataObject.columns[j].publicMetadata.title) {
//							$scope.selection[i] = angular.toJson({ id : queryService.dataObject.columns[j].id , title: queryService.dataObject.columns[j].publicMetadata.title  });
//							break;
//						}
//					}
//				}
//			}
//		}
//	});

	queryService.queryObject.ScriptColumnRequest = [];


	$scope.$watch(function() {
		return queryService.queryObject;
	}, function() {
		console.log(queryService.queryObject);
	}, true);
});
