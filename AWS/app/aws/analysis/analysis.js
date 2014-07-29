/**
 * Handle all Analysis Tab related work - Controllers to handle Analysis Tab
 */
'use strict';

var analysis_mod = angular.module('aws.AnalysisModule', ['wu.masonry', 'ui.select2', 'ui.slider']);

analysis_mod.controller('AnalysisFiltersControllers', function($scope, queryService) {

	$scope.service = queryService;
	
});

analysis_mod.controller('AnalysisMainCtrl', function($scope, $location, $anchorScroll, queryService){
	$scope.service= queryService;
  $scope.scrollTo = function(id) {
    $location.hash(id);
    $anchorScroll();
  };
});

analysis_mod.controller('WidgetsController', function($scope, queryService) {

	$scope.service = queryService;
	
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

analysis_mod.controller("ColorColumnCtrl", function($scope, queryService) {

	$scope.service = queryService;

});


analysis_mod.controller("ScriptsBarController", function($scope, queryService) {

	// This sets the service variable to the queryService 
	$scope.service = queryService;
	
	queryService.getDataTableList(true);
	queryService.getListOfScripts(true);

	$scope.$watch(function() {
		return queryService.queryObject.scriptSelected;
	}, function () {
		console.log(queryService.queryObject.scriptOptions);
		queryService.queryObject.scriptOptions = {};
		console.log(queryService.queryObject.scriptOptions);
	});

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
