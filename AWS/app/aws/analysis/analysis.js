/**
 * Handle all Analysis Tab related work - Controllers to handle Analysis Tab
 */
'use strict';
var tryParseJSON = function(jsonString){
    try {
        var o = JSON.parse(jsonString);

        // Handle non-exception-throwing cases:
        // Neither JSON.parse(false) or JSON.parse(1234) throw errors, hence the type-checking,
        // but... JSON.parse(null) returns 'null', and typeof null === "object", 
        // so we must check for that, too.
        if (o && typeof o === "object" && o !== null) {
            return o;
        }
    }
    catch (e) { }
    return false;
};

var AnalysisModule = angular.module('aws.AnalysisModule', ['wu.masonry', 'ui.select2', 'ui.slider']);

AnalysisModule.service('AnalysisService', function() {
	
	var AnalysisService = {
			content_tools : [{
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
				category : 'datafilter',
			}],
			
			tool_list : [
			         	{
			        		id : 'BarChartTool',
			        		title : 'Bar Chart Tool',
			        		template_url : 'aws/visualization/tools/barChart/bar_chart.tpl.html',
			        		description : 'Display Bar Chart in Weave',
			        		category : 'visualization',
			        		enabled : false

			        	}, {
			        		id : 'MapTool',
			        		title : 'Map Tool',
			        		template_url : 'aws/visualization/tools/mapChart/map_chart.tpl.html',
			        		description : 'Display Map in Weave',
			        		category : 'visualization',
			        		enabled : false
			        	}, {
			        		id : 'DataTableTool',
			        		title : 'Data Table Tool',
			        		template_url : 'aws/visualization/tools/dataTable/data_table.tpl.html',
			        		description : 'Display a Data Table in Weave',
			        		category : 'visualization',
			        		enabled : false
			        	}, {
			        		id : 'ScatterPlotTool',
			        		title : 'Scatter Plot Tool',
			        		template_url : 'aws/visualization/tools/scatterPlot/scatter_plot.tpl.html',
			        		description : 'Display a Scatter Plot in Weave',
			        		category : 'visualization',
			        		enabled : false
			        	}]
	};
	
	return AnalysisService;
	
});

AnalysisModule.controller('AnalysisCtrl', function($scope, queryService, AnalysisService) {

	$scope.queryService = queryService;
	$scope.AnalysisService = AnalysisService;

	$scope.toggle_widget = function(tool) {
		queryService.queryObject[tool.id].enabled = tool.enabled;
	};
	
	$scope.disable_widget = function(tool) {
		tool.enabled = false;
		queryService.queryObject[tool.id].enabled = false;
	};
	
	$scope.$watch(function() {
		return queryService.tool_list;
	}, function(newVal, oldVal) {
		if(newVal, oldVal) {
			for(var i in newVal) {
				var tool = newVal[i];
				queryService.queryObject[tool.id].enabled = tool.enabled;
			}
		}
	}, true);
	
	$scope.$watch(function () {
		return queryService.queryObject.BarChartTool.enabled;
	}, function(newVal, oldVal) {
		if(newVal != oldVal) {
			for(var i in queryService.tool_list) {
				var tool = queryService.tool_list[i];
				if(tool.id == "BarCharTool") {
					tool.enabled = newVal;
					break;
				}
			}
		}
	});
	
	$scope.$watch(function () {
		return queryService.queryObject.MapTool.enabled;
	}, function(newVal, oldVal) {
		if(newVal != oldVal) {
			for(var i in queryService.tool_list) {
				var tool = queryService.tool_list[i];
				if(tool.id == "MapTool") {
					tool.enabled = newVal;
					break;
				}
			}
		}
	});
	
	$scope.$watch(function () {
		return queryService.queryObject.ScatterPlotTool.enabled;
	}, function(newVal, oldVal) {
		if(newVal != oldVal) {
			for(var i in queryService.tool_list) {
				var tool = queryService.tool_list[i];
				if(tool.id == "ScatterPlotTool") {
					tool.enabled = newVal;
					break;
				}
			}
		}
	});
	
	$scope.$watch(function () {
		return queryService.queryObject.DataTableTool.enabled;
	}, function(newVal, oldVal) {
		if(newVal != oldVal) {
			for(var i in queryService.tool_list) {
				var tool = queryService.tool_list[i];
				if(tool.id == "DataTableTool") {
					tool.enabled = newVal;
					break;
				}
			}
		}
	});
	
});


AnalysisModule.config(function($selectProvider) {
	angular.extend($selectProvider.defaults, {
		caretHTML : '&nbsp'
	});
});

AnalysisModule.controller("ScriptsSettingsCtrl", function($scope, queryService) {

	// This sets the service variable to the queryService 
	$scope.service = queryService;
	
	queryService.getDataTableList(true);
	queryService.getListOfScripts(true);

	//  clear script options when script changes
	$scope.$watch('service.queryObject.scriptSelected', function(newVal, oldVal) {
		if(newVal != oldVal) {
			queryService.queryObject.scriptOptions = {};
		}
	});
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
					if(tryParseJSON(option).hasOwnProperty("columnType")) {
						if(angular.fromJson(option).columnType.toLowerCase() == "indicator") {
							queryService.queryObject.Indicator = option;
						}
					}
				}
			}
			
		}
	}, true);

	$scope.$watchCollection(function() {
		return [queryService.queryObject.Indicator, queryService.queryObject.scriptSelected, queryService.dataObject.scriptMetadata];
	}, function(newVal, oldVal) {
		if(newVal != oldVal) {
			var indicator = newVal[0];
			var scriptSelected = newVal[1];
			var scriptMetadata = newVal[2];
			
			if(indicator && scriptSelected) {
				queryService.queryObject.BarChartTool.title = "Bar Chart of " + scriptSelected.split('.')[0] + " of " + angular.fromJson(indicator).title;
				queryService.queryObject.MapTool.title = "Map of " + scriptSelected.split('.')[0] + " of " + angular.fromJson(indicator).title;
				queryService.queryObject.ScatterPlotTool.title = "Scatter Plot of " + scriptSelected.split('.')[0] + " of " + angular.fromJson(indicator).title;

			}
			
			$scope.$watch(function() {
				return queryService.dataObject.scriptMetadata;
			}, function(newValue, oldValue) {
				if(newValue) {
					scriptMetadata = newValue;
					if(indicator && scriptMetadata) {
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
			}, true);
		}
	}, true);
		
	$scope.toggleButton = function(input) {
		
		if (queryService.queryObject.scriptOptions[input.param] == input.options[0]) {
			queryService.queryObject.scriptOptions[input.param] = input.options[1];
		} else {
			queryService.queryObject.scriptOptions[input.param] = input.options[0];
		}
	};
});
