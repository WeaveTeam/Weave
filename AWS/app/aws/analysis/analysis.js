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

var AnalysisModule = angular.module('aws.AnalysisModule', ['wu.masonry', 'ui.select2', 'ui.slider', 'ui.bootstrap']);

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
				category : 'datafilter'
			}]
	};
	
	return AnalysisService;
	
});

AnalysisModule.controller('AnalysisCtrl', function($scope, queryService, AnalysisService, WeaveService, QueryHandlerService) {

	$scope.queryService = queryService;
	$scope.AnalysisService = AnalysisService;
	$scope.WeaveService = WeaveService;
	$scope.queryHandlerService = QueryHandlerService;
	
	$scope.IndicDescription = "";
	$scope.varValues = [];
	
	$scope.toggle_widget = function(tool) {
		queryService.queryObject[tool.id].enabled = tool.enabled;
	};
	
	$scope.disable_widget = function(tool) {
		tool.enabled = false;
		queryService.queryObject[tool.id].enabled = false;
		WeaveService[tool.id](queryService.queryObject[tool.id]); // temporary because the watch is not triggered
	};
	
	//clears the session state
	$scope.clearSessionState = function(){
		WeaveService.clearSessionState();
	};
	
	$scope.$watchCollection(function() {
		return $('#weave');
	}, function() {
		if($('#weave').length) {
			WeaveService.weave = $('#weave')[0];
		}
	});
	
	$scope.$watch('queryService.queryObject.Indicator', function() {
		
		if(queryService.queryObject.Indicator) {
			$scope.IndicDescription = angular.fromJson(queryService.queryObject.Indicator).description;
			queryService.getEntitiesById([angular.fromJson(queryService.queryObject.Indicator).id], true).then(function (result) {
				if(result.length) {
					var resultMetadata = result[0];
					if(resultMetadata.publicMetadata.hasOwnProperty("aws_metadata")) {
						var metadata = angular.fromJson(resultMetadata.publicMetadata.aws_metadata);
						if(metadata.hasOwnProperty("varValues")) {
							queryService.getDataMapping(metadata.varValues).then(function(result) {
								$scope.varValues = result;
							});
						}
					}
				}
			});
		} else {
			// delete description and table if the indicator is clear
			$scope.IndicDescription = "";
			$scope.varValues = [];
		}
	});
	
//	$scope.$watchCollection(function() {
//		return $.map(AnalysisService.tool_list, function(tool) {
//			return tool.enabled;
//		});
//	}, function() {
//		$.map(AnalysisService.tool_list, function(tool) {
//			queryService.queryObject[tool.id].enabled = tool.enabled;
//		});
//	});
	
	$scope.$watch(function () {
		return queryService.queryObject.BarChartTool.enabled;
	}, function(newVal, oldVal) {
		if(newVal != oldVal) {
			for(var i in AnalysisService.tool_list) {
				var tool = AnalysisService.tool_list[i];
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
			for(var i in AnalysisService.tool_list) {
				var tool = AnalysisService.tool_list[i];
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
			for(var i in AnalysisService.tool_list) {
				var tool = AnalysisService.tool_list[i];
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
			for(var i in AnalysisService.tool_list) {
				var tool = AnalysisService.tool_list[i];
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
